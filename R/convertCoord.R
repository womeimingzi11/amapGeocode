#' Convert coordinates to the AutoNavi system
#'
#' @param locations Required.
#' Coordinate string(s) to convert. Accepts a character vector.
#' @param key Optional.
#' AutoNavi API key. You can also set this globally via
#' `options(amap_key = "your-key")`.
#' @param coordsys Optional.
#' Source coordinate system (`gps`, `mapbar`, `baidu`, `autonavi`).
#' @param sig Optional.
#' Manual digital signature. Most workflows can enable automatic signing via
#' [with_amap_signature()] or [amap_config()].
#' @param output Optional.
#' Output data structure. Supported values are `"tibble"` (default),
#' `"JSON"`, and `"XML"`.
#' @param keep_bad_request Optional.
#' When `TRUE` (default) API errors are converted into placeholder rows so that
#' batched workflows continue. When `FALSE` errors are raised as
#' `amap_api_error` conditions.
#' @param ... Optional.
#' Included for forward compatibility only.
#'
#' @return
#' When `output = "tibble"`, a `tibble` with columns `lng` and `lat`
#' is returned. The table preserves the input order and gains a `rate_limit`
#' attribute containing any rate limit headers returned by the API. When
#' `output` is `"JSON"` or `"XML"`, the parsed body is returned without
#' further processing.
#'
#' @seealso [extractConvertCoord()], [with_amap_signature()], [amap_config()]
#' @export
#'
#' @examples
#' \\dontrun{
#' convertCoord("116.481499,39.990475", coordsys = "gps")
#' }
convertCoord <- function(locations,
                         key = NULL,
                         coordsys = NULL,
                         sig = NULL,
                         output = "tibble",
                         keep_bad_request = TRUE,
                         ...) {
  locations <- as.character(locations)
  output_upper <- toupper(output)

  if (output_upper != "TIBBLE") {
    return(convert_coord_raw(
      locations,
      key = key,
      coordsys = coordsys,
      sig = sig,
      output = output,
      keep_bad_request = keep_bad_request
    ))
  }

  rows <- list()
  rate_limits <- list()
  query_index <- seq_along(locations)

  perform_request <- function(query, key) {
    tryCatch(
      amap_request(
        endpoint = "assistant/coordinate/convert",
        query = query,
        key = key,
        output = NULL
      ),
      amap_api_error = function(err) {
        if (isTRUE(keep_bad_request)) {
          structure(list(error = err), class = "amap_request_error")
        } else {
          rlang::cnd_signal(err)
        }
      }
    )
  }

  for (i in seq_along(locations)) {
    location <- locations[[i]]
    query <- list(
      locations = location,
      coordsys = coordsys,
      sig = sig
    )
    resp <- perform_request(query, key)
    if (inherits(resp, "amap_request_error")) {
      placeholder <- convert_placeholder()
      placeholder$query <- location
      placeholder$query_index <- i
      rows[[length(rows) + 1L]] <- placeholder
      next
    }
    rate_limits[[length(rate_limits) + 1L]] <- attr(resp, "rate_limit")
    parsed <- extractConvertCoord(resp$body)
    parsed$query <- location
    parsed$query_index <- i
    rows[[length(rows) + 1L]] <- parsed
  }

  combined <- dplyr::bind_rows(rows)
  if (!nrow(combined)) {
    return(combined)
  }
  combined <- combined |> dplyr::arrange(query_index)
  combined <- dplyr::select(combined, -query_index, -query)

  rate_limit <- Filter(Negate(is.null), rate_limits)
  if (length(rate_limit)) {
    attr(combined, "rate_limit") <- rate_limit[[length(rate_limit)]]
  }
  attr(combined, "query") <- locations
  combined
}

convert_coord_raw <- function(locations,
                             key = NULL,
                             coordsys = NULL,
                             sig = NULL,
                             output = "JSON",
                             keep_bad_request = TRUE) {
  mapper <- function(location) {
    query <- list(
      locations = location,
      coordsys = coordsys,
      sig = sig
    )
    tryCatch(
      {
        resp <- amap_request(
          endpoint = "assistant/coordinate/convert",
          query = query,
          key = key,
          output = output
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
  results <- lapply(locations, mapper)
  if (length(locations) == 1L) {
    results <- results[[1L]]
  }
  results
}

#' Extract converted coordinates from a conversion response
#'
#' @param res Required.
#' Response object returned by [convertCoord()] with `output = "JSON"` or by
#' the AutoNavi coordinate conversion API.
#'
#' @return
#' A `tibble` with columns `lng` and `lat`. When no data is present a
#' single placeholder row filled with `NA` values is returned.
#'
#' @examples
#' \\dontrun{
#' raw <- convertCoord("116.481499,39.990475", coordsys = "gps", output = "JSON")
#' extractConvertCoord(raw)
#' }
#'
#' @seealso [convertCoord()]
#' @export
extractConvertCoord <- function(res) {
  parsed <- normalize_convert_response(res)
  # print(str(parsed)) 
  status <- parsed$status %||% parsed$Status
  if (!is.null(status) && !identical(as.character(status), "1")) {
    rlang::abort(parsed$info %||% parsed$message %||% "AutoNavi API request failed", call = NULL)
  }
  locations <- scalar_or_na(parsed$locations)
  if (is.na(locations)) {
    return(convert_placeholder())
  }
  coords <- strsplit(locations, split = ";", fixed = TRUE)[[1L]]
  rows <- lapply(coords, function(coord) {
    split <- str_loc_to_num_coord(coord)
    tibble::tibble(lng = split[[1L]], lat = split[[2L]])
  })
  dplyr::bind_rows(rows)
}

normalize_convert_response <- function(res) {
  if (inherits(res, "xml_document")) {
    res <- xml2::as_list(res)$response
  }
  if (is.list(res) && length(res) == 1L && !is.null(res$response)) {
    res <- res$response
  }
  res
}

convert_placeholder <- function() {
  tibble::tibble(lng = NA_real_, lat = NA_real_)
}
