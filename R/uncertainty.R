# Uncertainty propagation helpers

softmax2 <- function(score1, score2) {
  score1 <- as.numeric(score1)
  score2 <- as.numeric(score2)
  m <- pmax(score1, score2, na.rm = TRUE)
  ex1 <- exp(score1 - m)
  ex2 <- exp(score2 - m)
  ex1[is.na(score1)] <- 0
  ex2[is.na(score2)] <- 0
  s <- ex1 + ex2
  w1 <- ifelse(s > 0, ex1 / s, NA_real_)
  w2 <- ifelse(s > 0, ex2 / s, NA_real_)
  list(w1 = w1, w2 = w2)
}

top2_candidates <- function(candidates) {
  candidates <- amap_as_tibble(candidates)
  required <- c("query_index", "lng", "lat")
  missing <- setdiff(required, names(candidates))
  if (length(missing)) {
    rlang::abort(sprintf("`candidates` must contain columns: %s", paste(required, collapse = ", ")), call = NULL)
  }
  if (!"score" %in% names(candidates)) {
    candidates$score <- -as.numeric(candidates$match_rank %||% 1)
  }
  candidates <- dplyr::arrange(candidates, .data$query_index, dplyr::desc(.data$score), .data$match_rank)
  split_rows <- split(candidates, candidates$query_index)
  out <- lapply(split_rows, function(tbl) utils::head(tbl, 2))
  dplyr::bind_rows(out)
}

#' Propagate geocode uncertainty to OD matrices
#'
#' @param best Required.
#' Best-match rows, typically `resolved$best` from [resolveGeocode()].
#' @param candidates Required.
#' Candidate rows, typically `resolved$candidates` from [resolveGeocode()].
#' @param od_fun Optional.
#' Function used to build OD matrices. Defaults to [getOdMatrix()].
#' @param summary Optional.
#' Summaries to compute. Supports `"expected"`, `"interval"`, and `"sensitivity"`.
#' @param n_draws Optional.
#' Reserved for future Monte Carlo sampling. Currently ignored when `> 0`.
#' @param ... Required.
#' Passed to `od_fun()`. Must include `destinations = ...`.
#'
#' @return A list with OD matrices for scenarios and an aggregated summary.
#' @export
propagateUncertainty <- function(best,
                                 candidates,
                                 od_fun = getOdMatrix,
                                 summary = c("expected", "interval", "sensitivity"),
                                 n_draws = 100,
                                 ...) {
  summary <- unique(match.arg(summary, several.ok = TRUE))
  if (!missing(n_draws) && is.numeric(n_draws) && n_draws > 0) {
    rlang::inform("`n_draws` is reserved for future Monte Carlo sampling; using top-2 sensitivity analysis instead.")
  }

  best <- amap_as_tibble(best)
  candidates <- amap_as_tibble(candidates)
  if (!all(c("query_index", "lng", "lat") %in% names(best))) {
    rlang::abort("`best` must contain `query_index`, `lng`, and `lat` columns.", call = NULL)
  }

  cand2 <- top2_candidates(candidates)
  cand2 <- dplyr::arrange(cand2, .data$query_index, dplyr::desc(.data$score))
  cand2$alt_rank <- ave(cand2$query_index, cand2$query_index, FUN = seq_along)

  origins1 <- dplyr::filter(cand2, .data$alt_rank == 1L)
  origins2 <- dplyr::filter(cand2, .data$alt_rank == 2L)

  origins1 <- dplyr::transmute(origins1,
    id = as.character(.data$query_index),
    lng = as.numeric(.data$lng),
    lat = as.numeric(.data$lat),
    score = .data$score
  )
  origins2 <- dplyr::transmute(origins2,
    id = as.character(.data$query_index),
    lng = as.numeric(.data$lng),
    lat = as.numeric(.data$lat),
    score = .data$score
  )

  od1 <- od_fun(origins = dplyr::select(origins1, id, lng, lat), ...)
  od2 <- if (nrow(origins2)) od_fun(origins = dplyr::select(origins2, id, lng, lat), ...) else tibble::tibble()

  od1$scenario <- "top1"
  if (nrow(od2)) od2$scenario <- "top2"

  out <- list(
    od_scenarios = dplyr::bind_rows(od1, od2)
  )

  if (!("duration_s" %in% names(od1))) {
    return(out)
  }

  if (!nrow(od2)) {
    out$od_summary <- od1
    return(out)
  }

  key <- c("from_id", "to_id")
  merged <- dplyr::full_join(
    dplyr::select(od1, dplyr::all_of(key), duration_s_top1 = .data$duration_s, distance_m_top1 = .data$distance_m),
    dplyr::select(od2, dplyr::all_of(key), duration_s_top2 = .data$duration_s, distance_m_top2 = .data$distance_m),
    by = key
  )

  w_tbl <- dplyr::full_join(
    dplyr::select(origins1, from_id = .data$id, score_top1 = .data$score),
    dplyr::select(origins2, from_id = .data$id, score_top2 = .data$score),
    by = "from_id"
  )
  w <- softmax2(w_tbl$score_top1, w_tbl$score_top2)
  w_tbl$w_top1 <- w$w1
  w_tbl$w_top2 <- w$w2

  merged <- dplyr::left_join(merged, dplyr::select(w_tbl, from_id, w_top1, w_top2), by = "from_id")

  if ("expected" %in% summary) {
    merged$duration_s_expected <- (merged$duration_s_top1 * merged$w_top1) + (merged$duration_s_top2 * merged$w_top2)
    merged$distance_m_expected <- (merged$distance_m_top1 * merged$w_top1) + (merged$distance_m_top2 * merged$w_top2)
  }
  if ("interval" %in% summary) {
    merged$duration_s_min <- pmin(merged$duration_s_top1, merged$duration_s_top2, na.rm = TRUE)
    merged$duration_s_max <- pmax(merged$duration_s_top1, merged$duration_s_top2, na.rm = TRUE)
  }
  if ("sensitivity" %in% summary) {
    merged$duration_s_delta <- merged$duration_s_top2 - merged$duration_s_top1
  }

  out$od_summary <- merged
  out
}
