#' Get coordinate from location
#'
#' @param address Required.
#' Structured address information.
#' The value can be a character vector; each element will be queried in turn.
#' @param key Optional.
#' AutoNavi API key. You can also set this globally via
#' `options(amap_key = "your-key")`.
#' @param city Optional.
#' City hint that narrows down the search scope. When `batch = TRUE`,
#' only a single city value is supported.
#' @param sig Optional.
#' Digital signature supplied manually. Most users should instead enable
#' automatic signing via [with_amap_signature()] or [amap_config()].
#' @param output Optional.
#' Output data structure. Supported values are `"tibble"` (default),
#' `"JSON"`, and `"XML"`.
#' @param callback Optional.
#' JSONP callback. When supplied the raw body is returned as a character
#' vector.
#' @param keep_bad_request Optional.
#' When `TRUE` (default) API errors are converted into placeholder rows so
#' that vectorised or batched workflows continue. When `FALSE` errors are
#' raised as `amap_api_error` conditions.
#' @param mode Optional.
#' Controls how geocode candidates are returned. Use `"best"` (default) to
#' keep the highest ranked candidate for each query or `"all"` to return all
#' matches alongside ranking metadata.
#' @param batch Optional.
#' When `TRUE`, requests are chunked into groups of ten addresses using the
#' API's batch mode. Defaults to `FALSE` for backwards compatibility.
#' @param ... Optional.
#' Included for forward compatibility only.
#'
#' @return
#' When `output = "tibble"`, a `tibble` containing geocode results is
#' returned. The table preserves the input order and gains a
#' `rate_limit` attribute containing any rate limit headers returned by the API.
#' When `mode = "all"`, additional metadata columns (`query`, `query_index`,
#' and `match_rank`) are included. When `output` is `"JSON"` or `"XML"`,
#' the parsed body is returned without further processing.
#'
#' @seealso [extractCoord()], [with_amap_signature()], [amap_config()]
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic lookup (best match only)
#' getCoord("IFS Chengdu")
#'
#' # Retrieve all candidates for a single query
#' getCoord("LOS ANGELES", mode = "all")
#'
#' # Batch ten addresses at a time
#' getCoord(rep("Chengdu IFS", 12), batch = TRUE)
#'
#' # Temporarily enable automatic request signing
#' with_amap_signature("your-secret", getCoord("IFS Chengdu"))
#' }
getCoord <- function(address,
                     key = NULL,
                     city = NULL,
                     sig = NULL,
                     output = "tibble",
                     callback = NULL,
                     keep_bad_request = TRUE,
                     mode = c("best", "all"),
                     batch = FALSE,
                     ...) {
  mode <- match.arg(mode)
  if (missing(address) || length(address) == 0) {
    return(tibble::tibble())
  }

  output_upper <- toupper(output)
  addresses <- as.character(address)

  if (output_upper != "TIBBLE") {
    return(get_coord_raw(addresses,
                        key = key,
                        city = city,
                        sig = sig,
                        output = output,
                        callback = callback,
                        keep_bad_request = keep_bad_request))
  }

  if (batch && length(city) > 1L) {
    rlang::inform("Only a single city filter is supported when batch geocoding; using the first value provided.")
    city <- city[[1L]]
  }

  rows <- list()
  rate_limits <- list()
  query_index <- seq_along(addresses)

  perform_request <- function(query, key, chunk_size = 1L) {
    tryCatch(
      amap_request(
        endpoint = "geocode/geo",
        query = query,
        key = key,
        output = NULL,
        callback = callback
      ),
      amap_api_error = function(err) {
        if (isTRUE(keep_bad_request)) {
          structure(list(error = err, chunk_size = chunk_size), class = "amap_request_error")
        } else {
          rlang::cnd_signal(err)
        }
      }
    )
  }

  if (isTRUE(batch) && length(addresses) > 1L) {
    indices <- split(seq_along(addresses), ceiling(seq_along(addresses) / 10))
    for (idx in indices) {
      chunk_addresses <- addresses[idx]
      query <- list(
        address = paste(chunk_addresses, collapse = "|"),
        batch = "true",
        sig = sig
      )
      if (!is.null(city) && length(city) == 1L) {
        query$city <- city
      }
      resp <- perform_request(query, key, chunk_size = length(idx))
      if (inherits(resp, "amap_request_error")) {
        rows[[length(rows) + 1L]] <- geocode_placeholder(length(idx), query_index[idx], chunk_addresses)
        next
      }
      rate_limits[[length(rate_limits) + 1L]] <- attr(resp, "rate_limit")
      rows[[length(rows) + 1L]] <- parse_batch_geocode(resp$body, chunk_addresses, query_index[idx])
    }
  } else {
    for (i in seq_along(addresses)) {
      current_city <- if (length(city) > 1L) city[[i]] else city
      query <- list(
        address = addresses[[i]],
        city = current_city,
        sig = sig
      )
      resp <- perform_request(query, key)
      if (inherits(resp, "amap_request_error")) {
        rows[[length(rows) + 1L]] <- geocode_placeholder(1L, i, addresses[[i]])
        next
      }
      rate_limits[[length(rate_limits) + 1L]] <- attr(resp, "rate_limit")
      rows[[length(rows) + 1L]] <- parse_single_geocode(resp$body, addresses[[i]], i)
    }
  }

  combined <- dplyr::bind_rows(rows)
  if (!nrow(combined)) {
    return(geocode_finalize(combined, mode))
  }

  combined <- combined |> dplyr::arrange(query_index, match_rank)
  result <- geocode_finalize(combined, mode)

  rate_limit <- Filter(Negate(is.null), rate_limits)
  if (length(rate_limit)) {
    attr(result, "rate_limit") <- rate_limit[[length(rate_limit)]]
  }
  attr(result, "query") <- addresses
  result
}

get_coord_raw <- function(address,
                         key = NULL,
                         city = NULL,
                         sig = NULL,
                         output = "JSON",
                         callback = NULL,
                         keep_bad_request = TRUE) {
  mapper <- function(addr, city_value) {
    query <- list(
      address = addr,
      city = city_value,
      sig = sig
    )
    tryCatch(
      {
        resp <- amap_request(
          endpoint = "geocode/geo",
          query = query,
          key = key,
          output = output,
          callback = callback
        )
        resp$body
      },
      amap_api_error = function(err) {
        if (isTRUE(keep_bad_request)) {
          NULL
        } else {
          rlang::cnd_signal(err)
        }
      }
    )
  }
  city_values <- if (length(city) > 1L) {
    city
  } else if (is.null(city)) {
    rep(list(NULL), length(address))
  } else {
    rep_len(city, length(address))
  }
  results <- Map(mapper, address, city_values)
  if (length(address) == 1L) {
    results <- results[[1L]]
  }
  results
}

#' Extract coordinate from a geocoding response
#'
#' @param res Required.
#' Response object returned by [getCoord()] with `output = "JSON"` or by the
#' AutoNavi geocoding API.
#'
#' @return
#' A `tibble` with one row per geocode candidate. The table contains the
#' original columns provided by the API alongside a `match_rank` column that
#' indicates the ordering reported by AutoNavi. When the response does not
#' contain any matches a single placeholder row filled with `NA` values is
#' returned.
#'
#' @examples
#' \dontrun{
#' raw <- getCoord("IFS Chengdu", output = "JSON")
#' extractCoord(raw)
#' }
#'
#' @seealso [getCoord()]
#' @export
extractCoord <- function(res) {
  parsed <- normalize_geocode_response(res)
  status <- parsed$status %||% parsed$Status
  if (!is.null(status) && !identical(as.character(status), "1")) {
    rlang::abort(parsed$info %||% parsed$message %||% "AutoNavi API request failed", call = NULL)
  }
  geocodes <- parsed$geocodes
  count <- suppressWarnings(as.integer(parsed$count))
  if (is.null(geocodes) || length(geocodes) == 0 || isTRUE(count == 0)) {
    out <- geocode_placeholder(1L, NA_integer_, NA_character_)
    out$query <- NULL
    out$query_index <- NULL
    return(out)
  }
  rows <- lapply(seq_along(geocodes), function(i) geocode_entry_to_dt(geocodes[[i]], match_rank = i))
  dplyr::bind_rows(rows)
}

normalize_geocode_response <- function(res) {
  if (inherits(res, "xml_document")) {
    res <- xml2::as_list(res)$response
  }
  if (is.list(res) && length(res) == 1L && !is.null(res$response)) {
    res <- res$response
  }
  res
}

geocode_entry_to_dt <- function(entry, match_rank) {
  row <- geocode_template(1L)
  row$match_rank <- match_rank
  if (is.null(entry)) {
    return(row)
  }
  location <- scalar_or_na(entry$location)
  coords <- if (!is.na(location)) str_loc_to_num_coord(location) else c(NA_real_, NA_real_)
  neighborhood_val <- entry$neighborhood %||% list()
  building_val <- entry$building %||% list()
  
  dplyr::mutate(row,
    lng = coords[[1L]],
    lat = coords[[2L]],
    formatted_address = scalar_or_na(entry$formatted_address),
    country = scalar_or_na(entry$country),
    province = scalar_or_na(entry$province),
    city = scalar_or_na(entry$city),
    district = scalar_or_na(entry$district),
    township = scalar_or_na(entry$township),
    street = scalar_or_na(entry$street),
    number = scalar_or_na(entry$number),
    citycode = scalar_or_na(entry$citycode),
    adcode = scalar_or_na(entry$adcode),
    level = scalar_or_na(entry$level),
    matchlevel = scalar_or_na(entry$matchlevel),
    neighborhood = scalar_or_na(neighborhood_val$name),
    neighborhood_type = scalar_or_na(neighborhood_val$type),
    building = scalar_or_na(building_val$name),
    building_type = scalar_or_na(building_val$type),
    location = location
  )
}

geocode_template <- function(n = 1L) {
  tibble::tibble(
    match_rank = rep(NA_integer_, n),
    lng = rep(NA_real_, n),
    lat = rep(NA_real_, n),
    formatted_address = rep(NA_character_, n),
    country = rep(NA_character_, n),
    province = rep(NA_character_, n),
    city = rep(NA_character_, n),
    district = rep(NA_character_, n),
    township = rep(NA_character_, n),
    street = rep(NA_character_, n),
    number = rep(NA_character_, n),
    citycode = rep(NA_character_, n),
    adcode = rep(NA_character_, n),
    level = rep(NA_character_, n),
    matchlevel = rep(NA_character_, n),
    neighborhood = rep(NA_character_, n),
    neighborhood_type = rep(NA_character_, n),
    building = rep(NA_character_, n),
    building_type = rep(NA_character_, n),
    location = rep(NA_character_, n),
    query = rep(NA_character_, n),
    query_index = rep(NA_integer_, n)
  )
}

geocode_placeholder <- function(n = 1L, query_index = NA_integer_, query = NA_character_) {
  tbl <- geocode_template(n)
  if (!all(is.na(query))) {
    tbl$query <- rep(query, length.out = n)
  }
  if (!all(is.na(query_index))) {
    tbl$query_index <- rep(query_index, length.out = n)
  }
  tbl
}

parse_single_geocode <- function(body, query, index) {
  parsed <- normalize_geocode_response(body)
  geocodes <- parsed$geocodes
  if (is.null(geocodes) || length(geocodes) == 0) {
    out <- geocode_placeholder(1L, index, query)
    out$match_rank <- 1L
    return(out)
  }
  rows <- lapply(seq_along(geocodes), function(i) geocode_entry_to_dt(geocodes[[i]], match_rank = i))
  tbl <- dplyr::bind_rows(rows)
  tbl$query <- query
  tbl$query_index <- index
  tbl
}

parse_batch_geocode <- function(body, queries, indices) {
  parsed <- normalize_geocode_response(body)
  geocodes <- parsed$geocodes
  if (is.null(geocodes)) {
    geocodes <- vector("list", length(indices))
  }
  rows <- vector("list", length(indices))
  for (i in seq_along(indices)) {
    entry <- if (length(geocodes) >= i) geocodes[[i]] else NULL
    rows[[i]] <- geocode_entry_to_dt(entry, match_rank = 1L)
    rows[[i]]$query <- queries[[i]]
    rows[[i]]$query_index <- indices[[i]]
  }
  dplyr::bind_rows(rows)
}

geocode_finalize <- function(tbl, mode) {
  base_cols <- c(
    "lng", "lat", "formatted_address", "country", "province",
    "city", "district", "township", "street", "number", "citycode",
    "adcode"
  )
  extra_cols <- c(
    "level", "matchlevel", "neighborhood", "neighborhood_type",
    "building", "building_type", "location"
  )
  if (!nrow(tbl)) {
    return(dplyr::select(tbl, dplyr::all_of(base_cols)))
  }
  if (identical(mode, "best")) {
    query_index <- NULL
    best <- dplyr::ungroup(dplyr::slice(dplyr::group_by(tbl, query_index), 1L))
    best <- dplyr::arrange(best, query_index)
    keep <- intersect(c(base_cols, extra_cols), names(best))
    if (length(keep)) {
      best <- dplyr::select(best, dplyr::all_of(keep))
    }
    return(dplyr::select(best, dplyr::all_of(base_cols)))
  }
  ordered_cols <- c("query", "query_index", "match_rank", base_cols, extra_cols)
  present <- intersect(ordered_cols, names(tbl))
  query_index <- match_rank <- NULL
  tbl <- dplyr::mutate(tbl, match_rank = ifelse(is.na(match_rank), 1L, match_rank))
  tbl <- dplyr::arrange(tbl, query_index, match_rank)
  dplyr::select(tbl, dplyr::all_of(present))
}
