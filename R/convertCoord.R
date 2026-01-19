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
#' \dontrun{
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
  max_active <- getOption("amap_max_active", 3)

  build_prepared <- function(query) {
    amap_prepare_request(
      endpoint = "assistant/coordinate/convert",
      query = query,
      key = key,
      output = NULL
    )
  }

  queries <- lapply(locations, function(location) {
    list(
      locations = location,
      coordsys = coordsys,
      sig = sig
    )
  })

  prepared <- lapply(queries, build_prepared)
  reqs <- lapply(prepared, function(x) x$req)
  resps <- httr2::req_perform_parallel(
    reqs,
    on_error = "return",
    progress = FALSE,
    max_active = max_active
  )

  for (i in seq_along(resps)) {
    location <- locations[[i]]
    prep <- prepared[[i]]
    resp <- resps[[i]]

    out <- tryCatch(
      {
        if (inherits(resp, "httr2_response")) {
          amap_process_response(
            resp = resp,
            endpoint = prep$endpoint,
            query = prep$query,
            output = prep$output,
            callback = prep$callback
          )
        } else {
          rlang::abort("Request failed", parent = resp)
        }
      },
      amap_api_error = function(err) {
        if (isTRUE(keep_bad_request)) {
          structure(list(error = err), class = "amap_request_error")
        } else {
          rlang::cnd_signal(err)
        }
      },
      error = function(err) {
        if (isTRUE(keep_bad_request)) {
          structure(list(error = err), class = "amap_request_error")
        } else {
          rlang::abort("Request failed", parent = err)
        }
      }
    )

    if (inherits(out, "amap_request_error")) {
      placeholder <- convert_placeholder()
      placeholder$query <- location
      placeholder$query_index <- i
      rows[[length(rows) + 1L]] <- placeholder
      next
    }
    rate_limits[[length(rate_limits) + 1L]] <- attr(out, "rate_limit")
    parsed <- extractConvertCoord(out$body)
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
#' \dontrun{
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
  splits <- str_loc_to_num_coord(coords)
  if (length(coords) == 1L) {
    splits <- matrix(splits, nrow = 1L)
  }
  tibble::tibble(lng = splits[, 1L], lat = splits[, 2L])
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
