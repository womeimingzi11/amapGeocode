# OD matrix and accessibility helpers

amap_normalize_points <- function(x, arg = "origins") {
  if (tibble::is_tibble(x) || is.data.frame(x)) {
    x <- amap_as_tibble(x)
    required <- c("id", "lng", "lat")
    missing <- setdiff(required, names(x))
    if (length(missing)) {
      rlang::abort(sprintf("`%s` must contain columns: %s", arg, paste(required, collapse = ", ")), call = NULL)
    }
    out <- dplyr::transmute(x,
      id = as.character(.data$id),
      lng = as.numeric(.data$lng),
      lat = as.numeric(.data$lat)
    )
    return(out)
  }

  if (is.matrix(x) || is.data.frame(x)) {
    x <- as.data.frame(x)
    if (ncol(x) < 2) {
      rlang::abort(sprintf("`%s` must have at least two columns (lng, lat).", arg), call = NULL)
    }
    out <- tibble::tibble(
      id = as.character(seq_len(nrow(x))),
      lng = as.numeric(x[[1]]),
      lat = as.numeric(x[[2]])
    )
    return(out)
  }

  rlang::abort(sprintf("Unsupported `%s` type. Supply a tibble/data.frame with id,lng,lat.", arg), call = NULL)
}

amap_distance_type <- function(mode) {
  mode <- match.arg(mode, c("driving", "walking", "transit"))
  if (identical(mode, "driving")) {
    return("1")
  }
  if (identical(mode, "walking")) {
    return("3")
  }
  "2"
}

amap_distance_parse <- function(body, n_origins) {
  results <- body$results %||% list()
  if (!length(results)) {
    return(tibble::tibble(
      origin_id = character(),
      dest_id = character(),
      distance = numeric(),
      duration = numeric()
    ))
  }
  rows <- lapply(results, function(x) {
    tibble::tibble(
      origin_id = scalar_or_na(x$origin_id),
      dest_id = scalar_or_na(x$dest_id),
      distance = suppressWarnings(as.numeric(scalar_or_na(x$distance))),
      duration = suppressWarnings(as.numeric(scalar_or_na(x$duration)))
    )
  })
  out <- dplyr::bind_rows(rows)
  if (nrow(out) && n_origins > 0) {
    out$origin_id <- ifelse(is.na(out$origin_id), as.character(seq_len(nrow(out))), out$origin_id)
  }
  out
}

od_placeholder <- function(from_id, to_id, request_id = NA_character_, ok = FALSE, error = NA_character_, infocode = NA_character_) {
  tibble::tibble(
    from_id = from_id,
    to_id = to_id,
    duration_s = NA_real_,
    distance_m = NA_real_,
    amap_ok = isTRUE(ok),
    amap_error = error,
    amap_infocode = infocode,
    amap_request_id = request_id
  )
}

#' Build an OD matrix using the AutoNavi distance API
#'
#' @param origins Required.
#' Tibble/data.frame with columns `id`, `lng`, `lat`.
#' @param destinations Required.
#' Tibble/data.frame with columns `id`, `lng`, `lat`.
#' @param mode Optional.
#' Travel mode. Defaults to `"driving"`.
#' @param metric Optional.
#' Which metric to emphasise in downstream helpers. Defaults to `"duration"`.
#' @param chunking Optional.
#' Chunking limits. Defaults to `list(max_origins = 100, max_destinations = 1)`.
#' @param keep_bad_request Optional.
#' When `TRUE` (default), errors are returned as placeholder rows.
#' When `FALSE`, errors are raised.
#' @param ... Optional.
#' Reserved for future extensions.
#'
#' @return A tibble containing `from_id`, `to_id`, `duration_s`, `distance_m`,
#' and audit columns (`amap_ok`, `amap_error`, `amap_infocode`, `amap_request_id`).
#' @export
getOdMatrix <- function(origins,
                        destinations,
                        mode = c("driving", "walking", "transit"),
                        metric = c("duration", "distance"),
                        chunking = list(max_origins = 100, max_destinations = 1),
                        keep_bad_request = TRUE,
                        ...) {
  mode <- match.arg(mode)
  metric <- match.arg(metric)

  origins <- amap_normalize_points(origins, arg = "origins")
  destinations <- amap_normalize_points(destinations, arg = "destinations")

  max_origins <- chunking$max_origins %||% 100
  if (!is.numeric(max_origins) || length(max_origins) != 1L || is.na(max_origins) || max_origins < 1) {
    rlang::abort("`chunking$max_origins` must be a positive number.", call = NULL)
  }

  max_active <- getOption("amap_max_active", 3)
  type <- amap_distance_type(mode)

  build_prepared <- function(query) {
    amap_prepare_request(
      endpoint = "distance",
      query = query,
      output = NULL
    )
  }

  requests <- list()
  request_map <- list()

  for (d in seq_len(nrow(destinations))) {
    to <- destinations[d, , drop = FALSE]
    origin_idx <- split(seq_len(nrow(origins)), ceiling(seq_len(nrow(origins)) / max_origins))
    for (chunk in origin_idx) {
      from_chunk <- origins[chunk, , drop = FALSE]
      origins_str <- num_coord_to_str_loc(from_chunk$lng, from_chunk$lat)
      query <- list(
        origins = paste(origins_str, collapse = "|"),
        destination = num_coord_to_str_loc(to$lng, to$lat),
        type = type
      )
      requests[[length(requests) + 1L]] <- build_prepared(query)
      request_map[[length(request_map) + 1L]] <- list(
        from_ids = from_chunk$id,
        to_id = to$id[[1L]]
      )
    }
  }

  outs <- amap_perform_prepared(requests, max_active = max_active)

  rows <- list()
  for (i in seq_along(outs)) {
    out <- outs[[i]]
    map <- request_map[[i]]
    request_id <- attr(out, "request_id") %||% NA_character_

    if (!inherits(out, "amap_response")) {
      if (isTRUE(keep_bad_request)) {
        rows[[length(rows) + 1L]] <- od_placeholder(
          from_id = map$from_ids,
          to_id = rep(map$to_id, length(map$from_ids)),
          request_id = request_id,
          ok = FALSE,
          error = conditionMessage(out),
          infocode = if (inherits(out, "amap_api_error")) out$infocode %||% NA_character_ else NA_character_
        )
        next
      }
      rlang::abort("OD matrix request failed.", parent = out)
    }

    parsed <- amap_distance_parse(out$body, length(map$from_ids))
    if (!nrow(parsed)) {
      rows[[length(rows) + 1L]] <- od_placeholder(
        from_id = map$from_ids,
        to_id = rep(map$to_id, length(map$from_ids)),
        request_id = request_id,
        ok = TRUE
      )
      next
    }

    origin_ids <- suppressWarnings(as.integer(parsed$origin_id))
    origin_ids[is.na(origin_ids)] <- seq_len(nrow(parsed))
    origin_ids <- pmin(pmax(origin_ids, 1L), length(map$from_ids))

    rows[[length(rows) + 1L]] <- tibble::tibble(
      from_id = map$from_ids[origin_ids],
      to_id = rep(map$to_id, nrow(parsed)),
      duration_s = parsed$duration,
      distance_m = parsed$distance,
      amap_ok = TRUE,
      amap_error = NA_character_,
      amap_infocode = scalar_or_na(out$body$infocode %||% out$body$infoCode),
      amap_request_id = request_id
    )
  }

  result <- dplyr::bind_rows(rows)
  if (!nrow(result)) {
    return(result)
  }
  result <- dplyr::arrange(result, .data$from_id, .data$to_id)
  attr(result, "metric") <- metric
  result
}

#' Prepare an OD matrix for the {accessibility} package
#'
#' @param od Required.
#' Output from [getOdMatrix()].
#' @param origins Optional.
#' Origins table used to build the OD matrix.
#' @param destinations Optional.
#' Destinations table used to build the OD matrix.
#'
#' @return A tibble with columns `from_id`, `to_id`, and `travel_time` (minutes).
#' @export
asAccessibilityInput <- function(od, origins = NULL, destinations = NULL) {
  od <- amap_as_tibble(od)
  required <- c("from_id", "to_id", "duration_s")
  missing <- setdiff(required, names(od))
  if (length(missing)) {
    rlang::abort(sprintf("`od` must contain columns: %s", paste(required, collapse = ", ")), call = NULL)
  }
  out <- dplyr::transmute(od,
    from_id = as.character(.data$from_id),
    to_id = as.character(.data$to_id),
    travel_time = .data$duration_s / 60
  )
  attr(out, "origins") <- origins
  attr(out, "destinations") <- destinations
  out
}

