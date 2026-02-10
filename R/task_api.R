# Task-level APIs for tidy workflows (data.frame / tibble inputs)

amap_as_tibble <- function(x) {
  if (tibble::is_tibble(x)) {
    return(x)
  }
  tibble::as_tibble(x)
}

amap_col_sym <- function(col) {
  expr <- rlang::enexpr(col)
  if (is.character(expr) && length(expr) == 1L) {
    return(rlang::sym(expr))
  }
  rlang::ensym(expr)
}

amap_pull_col <- function(data, col) {
  col <- amap_col_sym(col)
  name <- rlang::as_string(col)
  if (!name %in% names(data)) {
    rlang::abort(sprintf("Column `%s` not found in `data`.", name), call = NULL)
  }
  data[[name]]
}

amap_unique_key <- function(address, city = NULL) {
  address <- as.character(address)
  if (is.null(city)) {
    return(address)
  }
  paste(address, as.character(city), sep = "\u241f")
}

amap_geocode_candidates <- function(address,
                                    city = NULL,
                                    key = NULL,
                                    sig = NULL,
                                    callback = NULL,
                                    keep_bad_request = TRUE,
                                    batch = TRUE,
                                    max_active = NULL) {
  addresses <- as.character(address)
  if (length(addresses) == 0) {
    return(tibble::tibble())
  }
  query_index <- seq_along(addresses)
  max_active <- max_active %||% getOption("amap_max_active", 3)

  build_prepared <- function(query) {
    amap_prepare_request(
      endpoint = "geocode/geo",
      query = query,
      key = key,
      output = NULL,
      callback = callback
    )
  }

  rows <- list()

  city_values <- if (length(city) > 1L) {
    as.character(city)
  } else if (is.null(city)) {
    rep(NA_character_, length(addresses))
  } else {
    rep_len(as.character(city), length(addresses))
  }

  can_batch <- isTRUE(batch) && length(addresses) > 1L && length(unique(na.omit(city_values))) <= 1L

  if (isTRUE(can_batch)) {
    city_single <- unique(na.omit(city_values))
    city_single <- if (length(city_single)) city_single[[1L]] else NULL

    indices <- split(seq_along(addresses), ceiling(seq_along(addresses) / 10))
    batch_queries <- lapply(indices, function(idx) {
      query <- list(
        address = paste(addresses[idx], collapse = "|"),
        batch = "true",
        sig = sig
      )
      if (!is.null(city_single) && nzchar(city_single)) {
        query$city <- city_single
      }
      query
    })
    prepared <- lapply(batch_queries, build_prepared)
    outs <- amap_perform_prepared(prepared, max_active = max_active)

    for (i in seq_along(outs)) {
      idx <- indices[[i]]
      out <- outs[[i]]
      request_id <- attr(out, "request_id") %||% NA_character_

      parsed <- tryCatch(
        {
          if (inherits(out, "amap_response")) {
            parse_batch_geocode(out$body, addresses[idx], query_index[idx])
          } else {
            rlang::abort("Request failed", parent = out)
          }
        },
        error = function(e) {
          err <- e
          if (inherits(e, "amap_api_error")) {
            err <- e
          }
          placeholder <- geocode_placeholder(length(idx), query_index[idx], addresses[idx])
          placeholder$match_rank <- 1L
          placeholder$amap_ok <- FALSE
          placeholder$amap_error <- conditionMessage(e)
          placeholder$amap_infocode <- if (inherits(err, "amap_api_error")) err$infocode %||% NA_character_ else NA_character_
          placeholder$amap_request_id <- request_id
          placeholder
        }
      )

      if (inherits(out, "amap_response")) {
        parsed$amap_ok <- TRUE
        parsed$amap_error <- NA_character_
        parsed$amap_infocode <- scalar_or_na(out$body$infocode %||% out$body$infoCode)
        parsed$amap_request_id <- request_id
      }
      rows[[length(rows) + 1L]] <- parsed
    }
  } else {
    queries <- lapply(seq_along(addresses), function(i) {
      current_city <- city_values[[i]]
      query <- list(
        address = addresses[[i]],
        city = if (!is.na(current_city) && nzchar(current_city)) current_city else NULL,
        sig = sig
      )
      query
    })
    prepared <- lapply(queries, build_prepared)
    outs <- amap_perform_prepared(prepared, max_active = max_active)

    for (i in seq_along(outs)) {
      out <- outs[[i]]
      request_id <- attr(out, "request_id") %||% NA_character_

      parsed <- tryCatch(
        {
          if (inherits(out, "amap_response")) {
            parse_single_geocode(out$body, addresses[[i]], i)
          } else {
            rlang::abort("Request failed", parent = out)
          }
        },
        error = function(e) {
          err <- e
          placeholder <- geocode_placeholder(1L, i, addresses[[i]])
          placeholder$match_rank <- 1L
          placeholder$amap_ok <- FALSE
          placeholder$amap_error <- conditionMessage(e)
          placeholder$amap_infocode <- if (inherits(err, "amap_api_error")) err$infocode %||% NA_character_ else NA_character_
          placeholder$amap_request_id <- request_id
          placeholder
        }
      )

      if (inherits(out, "amap_response")) {
        parsed$amap_ok <- TRUE
        parsed$amap_error <- NA_character_
        parsed$amap_infocode <- scalar_or_na(out$body$infocode %||% out$body$infoCode)
        parsed$amap_request_id <- request_id
      }
      rows[[length(rows) + 1L]] <- parsed
    }
  }

  combined <- dplyr::bind_rows(rows)
  if (!nrow(combined)) {
    return(combined)
  }
  combined <- dplyr::arrange(combined, .data$query_index, .data$match_rank)
  combined
}

geocode_best_from_candidates <- function(candidates) {
  if (!nrow(candidates)) {
    return(candidates)
  }
  query_index <- NULL
  best <- dplyr::ungroup(dplyr::slice(dplyr::group_by(candidates, query_index), 1L))
  dplyr::arrange(best, .data$query_index)
}

pack_candidates <- function(candidates) {
  if (!nrow(candidates)) {
    return(tibble::tibble(query_index = integer(), candidates = list()))
  }
  split_rows <- split(candidates, candidates$query_index)
  tibble::tibble(
    query_index = as.integer(names(split_rows)),
    candidates = unname(lapply(split_rows, function(x) dplyr::select(x, -query_index)))
  )
}

#' Geocode a data frame (task-level API)
#'
#' @param data Required.
#' A data.frame/tibble containing address information.
#' @param address_col Required.
#' Column containing addresses.
#' @param city_col Optional.
#' Optional city hint column.
#' @param mode Optional.
#' `"best"` (default) keeps the best match per row. `"all"` keeps candidates
#' in a list-column.
#' @param deduplicate Optional.
#' Whether to deduplicate identical queries before requesting. Defaults to `TRUE`.
#' @param join_back Optional.
#' When `TRUE` (default), results are joined back onto the input data.
#' @param keep_diagnostics Optional.
#' When `TRUE` and `mode="all"`, a `diagnostics` list-column is included. The
#' column is initially `NULL` and can be populated by [resolveGeocode()].
#' @param ... Optional.
#' Passed through to lower-level request helpers in future versions.
#'
#' @return A tibble with geocoding results, preserving input order.
#' @export
geocodeData <- function(data,
                        address_col,
                        city_col = NULL,
                        mode = c("best", "all"),
                        deduplicate = TRUE,
                        join_back = TRUE,
                        keep_diagnostics = TRUE,
                        ...) {
  mode <- match.arg(mode)
  data <- amap_as_tibble(data)

  address_col <- rlang::ensym(address_col)
  address_name <- rlang::as_string(address_col)
  if (!address_name %in% names(data)) {
    rlang::abort(sprintf("Column `%s` not found in `data`.", address_name), call = NULL)
  }
  address <- data[[address_name]]

  city_hint <- NULL
  if (!is.null(city_col)) {
    city_col <- rlang::ensym(city_col)
    city_name <- rlang::as_string(city_col)
    if (!city_name %in% names(data)) {
      rlang::abort(sprintf("Column `%s` not found in `data`.", city_name), call = NULL)
    }
    city_hint <- data[[city_name]]
  }
  key <- amap_unique_key(address, city_hint)

  query_tbl <- tibble::tibble(.key = key)

  unique_tbl <- tibble::tibble(
    .key = if (isTRUE(deduplicate)) unique(key) else key,
    address = if (isTRUE(deduplicate)) as.character(address)[match(unique(key), key)] else as.character(address),
    city_hint = if (isTRUE(deduplicate)) {
      if (!is.null(city_hint)) as.character(city_hint)[match(unique(key), key)] else NA_character_
    } else {
      if (!is.null(city_hint)) as.character(city_hint) else NA_character_
    }
  )
  unique_tbl$query_index <- seq_len(nrow(unique_tbl))

  candidates <- amap_geocode_candidates(
    address = unique_tbl$address,
    city = if (!all(is.na(unique_tbl$city_hint))) unique_tbl$city_hint else NULL,
    batch = TRUE
  )
  candidates$.key <- unique_tbl$.key[candidates$query_index]

  if (identical(mode, "best")) {
    best <- geocode_best_from_candidates(candidates)
    best <- dplyr::select(best, -query, -query_index, -match_rank)
    lookup <- dplyr::left_join(unique_tbl, best, by = ".key")
  } else {
    packed <- pack_candidates(candidates)
    packed$.key <- unique_tbl$.key[packed$query_index]
    packed$query_index <- NULL

    best <- geocode_best_from_candidates(candidates)
    best <- dplyr::select(best, -query, -query_index, -match_rank)
    lookup <- dplyr::left_join(unique_tbl, best, by = ".key")
    lookup <- dplyr::left_join(lookup, dplyr::select(packed, .data$.key, .data$candidates), by = ".key")
    if (isTRUE(keep_diagnostics)) {
      lookup$diagnostics <- rep(list(NULL), nrow(lookup))
    }
  }

  out <- dplyr::left_join(query_tbl, dplyr::select(lookup, -"address", -"city_hint", -"query_index"), by = ".key")
  out <- dplyr::select(out, -dplyr::any_of(c(".key")))
  if (isTRUE(join_back)) {
    dplyr::bind_cols(data, out)
  } else {
    out
  }
}

amap_regeo_rows <- function(lng,
                            lat,
                            key = NULL,
                            extensions = NULL,
                            details = NULL,
                            keep_bad_request = TRUE,
                            batch = TRUE,
                            max_active = NULL) {
  if (length(lng) != length(lat)) {
    rlang::abort("`lng` and `lat` must have the same length.", call = NULL)
  }
  if (!length(lng)) {
    return(tibble::tibble())
  }
  details <- normalize_location_details(details)
  coords <- num_coord_to_str_loc(lng, lat)
  query_index <- seq_along(coords)
  max_active <- max_active %||% getOption("amap_max_active", 3)

  build_prepared <- function(query) {
    amap_prepare_request(
      endpoint = "geocode/regeo",
      query = query,
      key = key,
      output = NULL
    )
  }

  rows <- list()
  can_batch <- isTRUE(batch) && length(coords) > 1L
  if (isTRUE(can_batch)) {
    indices <- split(seq_along(coords), ceiling(seq_along(coords) / 10))
    batch_queries <- lapply(indices, function(idx) {
      list(
        location = paste(coords[idx], collapse = "|"),
        batch = "true",
        extensions = extensions
      )
    })
    prepared <- lapply(batch_queries, build_prepared)
    outs <- amap_perform_prepared(prepared, max_active = max_active)

    for (i in seq_along(outs)) {
      idx <- indices[[i]]
      out <- outs[[i]]
      request_id <- attr(out, "request_id") %||% NA_character_

      parsed <- tryCatch(
        {
          if (inherits(out, "amap_response")) {
            parse_batch_location(out$body,
              coords = coords[idx],
              lng = lng[idx],
              lat = lat[idx],
              indices = query_index[idx],
              details = details
            )
          } else {
            rlang::abort("Request failed", parent = out)
          }
        },
        error = function(e) {
          placeholder <- location_placeholder(length(idx), details)
          placeholder$query_index <- query_index[idx]
          placeholder$query_lng <- lng[idx]
          placeholder$query_lat <- lat[idx]
          placeholder$amap_ok <- FALSE
          placeholder$amap_error <- conditionMessage(e)
          placeholder$amap_infocode <- if (inherits(e, "amap_api_error")) e$infocode %||% NA_character_ else NA_character_
          placeholder$amap_request_id <- request_id
          placeholder
        }
      )

      if (inherits(out, "amap_response")) {
        parsed$amap_ok <- TRUE
        parsed$amap_error <- NA_character_
        parsed$amap_infocode <- scalar_or_na(out$body$infocode %||% out$body$infoCode)
        parsed$amap_request_id <- request_id
      }
      rows[[length(rows) + 1L]] <- parsed
    }
  } else {
    queries <- lapply(seq_along(coords), function(i) {
      list(location = coords[[i]], extensions = extensions)
    })
    prepared <- lapply(queries, build_prepared)
    outs <- amap_perform_prepared(prepared, max_active = max_active)

    for (i in seq_along(outs)) {
      out <- outs[[i]]
      request_id <- attr(out, "request_id") %||% NA_character_
      parsed <- tryCatch(
        {
          if (inherits(out, "amap_response")) {
            parse_single_location(out$body, lng = lng[[i]], lat = lat[[i]], index = i, details = details)
          } else {
            rlang::abort("Request failed", parent = out)
          }
        },
        error = function(e) {
          placeholder <- location_placeholder(1L, details)
          placeholder$query_index <- i
          placeholder$query_lng <- lng[[i]]
          placeholder$query_lat <- lat[[i]]
          placeholder$amap_ok <- FALSE
          placeholder$amap_error <- conditionMessage(e)
          placeholder$amap_infocode <- if (inherits(e, "amap_api_error")) e$infocode %||% NA_character_ else NA_character_
          placeholder$amap_request_id <- request_id
          placeholder
        }
      )
      if (inherits(out, "amap_response")) {
        parsed$amap_ok <- TRUE
        parsed$amap_error <- NA_character_
        parsed$amap_infocode <- scalar_or_na(out$body$infocode %||% out$body$infoCode)
        parsed$amap_request_id <- request_id
      }
      rows[[length(rows) + 1L]] <- parsed
    }
  }

  combined <- dplyr::bind_rows(rows)
  if (!nrow(combined)) {
    return(combined)
  }
  combined <- dplyr::arrange(combined, .data$query_index)
  combined
}

#' Reverse geocode a data frame (task-level API)
#'
#' @param data Required.
#' A data.frame/tibble containing longitude/latitude columns.
#' @param lng_col Required.
#' Longitude column.
#' @param lat_col Required.
#' Latitude column.
#' @param deduplicate Optional.
#' Whether to deduplicate identical coordinates before requesting. Defaults to `TRUE`.
#' @param join_back Optional.
#' When `TRUE` (default), results are joined back onto the input data.
#' @param details Optional.
#' Passed to [getLocation()] for list-column parsing when `extensions="all"`.
#' @param ... Optional.
#' Reserved for future extensions.
#'
#' @return A tibble with reverse geocoding results, preserving input order.
#' @export
regeoData <- function(data,
                      lng_col,
                      lat_col,
                      deduplicate = TRUE,
                      join_back = TRUE,
                      details = NULL,
                      ...) {
  data <- amap_as_tibble(data)
  lng_col <- rlang::ensym(lng_col)
  lat_col <- rlang::ensym(lat_col)
  lng_name <- rlang::as_string(lng_col)
  lat_name <- rlang::as_string(lat_col)
  if (!lng_name %in% names(data)) {
    rlang::abort(sprintf("Column `%s` not found in `data`.", lng_name), call = NULL)
  }
  if (!lat_name %in% names(data)) {
    rlang::abort(sprintf("Column `%s` not found in `data`.", lat_name), call = NULL)
  }
  lng <- data[[lng_name]]
  lat <- data[[lat_name]]

  coord_key <- paste(round(as.numeric(lng), 6), round(as.numeric(lat), 6), sep = ",")
  query_tbl <- tibble::tibble(.key = coord_key)

  unique_keys <- if (isTRUE(deduplicate)) unique(coord_key) else coord_key
  unique_idx <- match(unique_keys, coord_key)
  unique_tbl <- tibble::tibble(
    .key = unique_keys,
    lng = as.numeric(lng)[unique_idx],
    lat = as.numeric(lat)[unique_idx]
  )
  unique_tbl$query_index <- seq_len(nrow(unique_tbl))

  rows <- amap_regeo_rows(
    lng = unique_tbl$lng,
    lat = unique_tbl$lat,
    details = details,
    batch = TRUE
  )
  rows$.key <- unique_tbl$.key[rows$query_index]
  rows <- dplyr::select(rows, -"query_index", -"query_lng", -"query_lat")
  lookup <- dplyr::left_join(unique_tbl, rows, by = ".key")

  out <- dplyr::left_join(query_tbl, dplyr::select(lookup, -"query_index", -"lng", -"lat"), by = ".key")
  out <- dplyr::select(out, -dplyr::any_of(c(".key")))
  if (isTRUE(join_back)) {
    dplyr::bind_cols(data, out)
  } else {
    out
  }
}
