# Explainable geocode candidate resolution

haversine_km <- function(lng1, lat1, lng2, lat2) {
  rad <- pi / 180
  lng1 <- lng1 * rad
  lat1 <- lat1 * rad
  lng2 <- lng2 * rad
  lat2 <- lat2 * rad
  dlat <- lat2 - lat1
  dlng <- lng2 - lng1
  a <- sin(dlat / 2)^2 + cos(lat1) * cos(lat2) * sin(dlng / 2)^2
  6371 * 2 * atan2(sqrt(a), sqrt(1 - a))
}

normalize_similarity <- function(a, b) {
  if (is.na(a) || is.na(b) || !nzchar(a) || !nzchar(b)) {
    return(NA_real_)
  }
  d <- utils::adist(a, b)
  denom <- max(nchar(a), nchar(b), 1)
  sim <- 1 - (as.numeric(d) / denom)
  max(min(sim, 1), 0)
}

admin_score <- function(row, admin) {
  if (is.null(admin) || !length(admin)) {
    return(0)
  }
  score <- 0
  if (!is.null(admin$adcode) && nzchar(admin$adcode) && "adcode" %in% names(row)) {
    score <- score + ifelse(!is.na(row$adcode) && identical(as.character(row$adcode), as.character(admin$adcode)), 1, -1)
  }
  if (!is.null(admin$province) && nzchar(admin$province) && "province" %in% names(row)) {
    score <- score + ifelse(!is.na(row$province) && identical(as.character(row$province), as.character(admin$province)), 1, -1)
  }
  if (!is.null(admin$city) && nzchar(admin$city) && "city" %in% names(row)) {
    score <- score + ifelse(!is.na(row$city) && identical(as.character(row$city), as.character(admin$city)), 1, -1)
  }
  if (!is.null(admin$district) && nzchar(admin$district) && "district" %in% names(row)) {
    score <- score + ifelse(!is.na(row$district) && identical(as.character(row$district), as.character(admin$district)), 1, -1)
  }
  score
}

boundary_score <- function(lng, lat, boundary) {
  if (is.null(boundary)) {
    return(0)
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    rlang::inform("`sf` is not installed; `boundary` constraint is ignored.")
    return(0)
  }
  if (!inherits(boundary, "sf") && !inherits(boundary, "sfc")) {
    rlang::inform("`boundary` must be an sf object; ignoring boundary constraint.")
    return(0)
  }
  pts <- sf::st_sfc(sf::st_point(c(lng, lat)), crs = sf::st_crs(boundary))
  inside <- suppressWarnings(sf::st_within(pts, boundary, sparse = FALSE))
  if (is.matrix(inside) && any(inside[1, ])) {
    return(1)
  }
  -1
}

#' Resolve geocoding candidates with an explainable strategy
#'
#' @param candidates Required.
#' Candidate table returned by [getCoord(mode = "all")] or by [geocodeData(mode = "all")].
#' @param strategy Optional.
#' Strategy name. Defaults to `"default"`.
#' @param admin Optional.
#' List of administrative constraints: `province`, `city`, `district`, `adcode`.
#' @param anchor Optional.
#' Numeric vector `c(lng, lat)` used as a spatial anchor.
#' @param boundary Optional.
#' An `sf` polygon defining an allowed region (optional; requires `{sf}`).
#' @param weights Optional.
#' Named numeric weights for score components: `admin`, `text`, `rank`, `anchor`, `boundary`.
#' @param top_k Optional.
#' Number of candidates to keep per query in the returned `$candidates`.
#'
#' @return A list with `best`, `candidates`, and `diagnostics`.
#' @export
resolveGeocode <- function(candidates,
                           strategy = "default",
                           admin = list(province = NULL, city = NULL, district = NULL, adcode = NULL),
                           anchor = NULL,
                           boundary = NULL,
                           weights = NULL,
                           top_k = 5) {
  candidates <- amap_as_tibble(candidates)
  required <- c("query", "query_index", "match_rank")
  missing <- setdiff(required, names(candidates))
  if (length(missing)) {
    rlang::abort(sprintf("`candidates` must contain columns: %s", paste(required, collapse = ", ")), call = NULL)
  }

  w_default <- list(admin = 2, text = 1, rank = 0.5, anchor = 1, boundary = 2)
  weights <- utils::modifyList(w_default, weights %||% list())

  use_anchor <- is.numeric(anchor) && length(anchor) == 2L && all(is.finite(anchor))
  anchor_lng <- if (use_anchor) anchor[[1L]] else NA_real_
  anchor_lat <- if (use_anchor) anchor[[2L]] else NA_real_

  score_row <- function(row) {
    s_admin <- admin_score(row, admin)
    s_rank <- if (!is.na(row$match_rank) && row$match_rank > 0) 1 / as.numeric(row$match_rank) else 0
    s_text <- normalize_similarity(as.character(row$query), as.character(row$formatted_address %||% NA_character_))
    if (is.na(s_text)) s_text <- 0
    s_anchor <- 0
    if (use_anchor && is.finite(row$lng) && is.finite(row$lat)) {
      d_km <- haversine_km(anchor_lng, anchor_lat, row$lng, row$lat)
      s_anchor <- exp(-d_km / 5)
    }
    s_boundary <- 0
    if (!is.null(boundary) && is.finite(row$lng) && is.finite(row$lat)) {
      s_boundary <- boundary_score(row$lng, row$lat, boundary)
    }
    total <- weights$admin * s_admin +
      weights$text * s_text +
      weights$rank * s_rank +
      weights$anchor * s_anchor +
      weights$boundary * s_boundary
    list(
      score = total,
      score_admin = s_admin,
      score_text = s_text,
      score_rank = s_rank,
      score_anchor = s_anchor,
      score_boundary = s_boundary
    )
  }

  scored <- candidates
  scores <- lapply(seq_len(nrow(scored)), function(i) score_row(scored[i, , drop = FALSE]))
  scored$score <- vapply(scores, `[[`, numeric(1), "score")
  scored$score_admin <- vapply(scores, `[[`, numeric(1), "score_admin")
  scored$score_text <- vapply(scores, `[[`, numeric(1), "score_text")
  scored$score_rank <- vapply(scores, `[[`, numeric(1), "score_rank")
  scored$score_anchor <- vapply(scores, `[[`, numeric(1), "score_anchor")
  scored$score_boundary <- vapply(scores, `[[`, numeric(1), "score_boundary")

  scored <- dplyr::arrange(scored, .data$query_index, dplyr::desc(.data$score), .data$match_rank)

  split_rows <- split(scored, scored$query_index)
  best_rows <- vector("list", length(split_rows))
  diag_rows <- vector("list", length(split_rows))
  cand_rows <- vector("list", length(split_rows))

  for (i in seq_along(split_rows)) {
    tbl <- split_rows[[i]]
    tbl_top <- utils::head(tbl, top_k)
    cand_rows[[i]] <- tbl_top

    top1 <- tbl[1L, , drop = FALSE]
    top2_score <- if (nrow(tbl) >= 2L) tbl$score[[2L]] else NA_real_
    delta <- if (!is.na(top2_score)) top1$score[[1L]] - top2_score else NA_real_
    confidence <- if (!is.na(delta)) stats::plogis(delta) else NA_real_
    needs_review <- is.na(confidence) || confidence < 0.6

    top1$confidence <- confidence
    top1$needs_review <- needs_review
    top1$strategy <- strategy
    best_rows[[i]] <- top1

    diag_rows[[i]] <- tibble::tibble(
      query_index = top1$query_index[[1L]],
      query = top1$query[[1L]],
      top1_score = top1$score[[1L]],
      top2_score = top2_score,
      score_delta = delta,
      confidence = confidence,
      needs_review = needs_review,
      strategy = strategy
    )
  }

  best <- dplyr::bind_rows(best_rows)
  diagnostics <- dplyr::bind_rows(diag_rows)
  candidates_out <- dplyr::bind_rows(cand_rows)

  structure(
    list(best = best, candidates = candidates_out, diagnostics = diagnostics),
    class = "amap_resolved_geocode"
  )
}

