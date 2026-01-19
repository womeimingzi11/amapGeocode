#' Get subordinate administrative regions from keywords
#'
#' @param keywords Required.
#' Search keywords. Accepts a character vector; each element is queried in turn.
#' @param key Optional.
#' AutoNavi API key. You can also set this globally via
#' `options(amap_key = "your-key")`.
#' @param subdistrict Optional.
#' Subordinate administrative depth (0-3). Defaults to the API's behaviour.
#' @param page Optional.
#' Page number when multiple pages are available.
#' @param offset Optional.
#' Maximum records per page (maximum 20).
#' @param extensions Optional.
#' Either `"base"` or `"all"`. Required for polyline data.
#' @param filter Optional.
#' Filter by designated administrative divisions (adcode).
#' @param callback Optional.
#' JSONP callback. When supplied, the raw response string is returned.
#' @param output Optional.
#' Output data structure. Supported values are `"tibble"` (default),
#' `"JSON"`, and `"XML"`.
#' @param keep_bad_request Optional.
#' When `TRUE` (default) API errors are converted into placeholder rows so that
#' batched workflows continue. When `FALSE` errors are raised as
#' `amap_api_error` conditions.
#' @param include_polyline Optional.
#' When `TRUE`, and when the request is made with `extensions = "all"`,
#' polyline strings are included in the parsed output.
#' @param ... Optional.
#' Included for forward compatibility only.
#'
#' @return
#' When `output = "tibble"`, a `tibble` containing administrative
#' region details is returned. The table preserves the input order and includes
#' parent metadata (`parent_name`, `parent_adcode`, `parent_level`) and a `depth`
#' column describing the nesting level. A `rate_limit` attribute is attached when
#' rate limit headers are present. When `output` is `"JSON"` or `"XML"`, the
#' parsed body is returned without further processing.
#'
#' @seealso [extractAdmin()], [with_amap_signature()], [amap_config()]
#' @export
#'
#' @examples
#' \dontrun{
#' getAdmin("Sichuan Province", subdistrict = 1)
#'
#' # Include polylines (requires extensions = "all")
#' getAdmin("Sichuan Province", subdistrict = 1,
#'          extensions = "all", include_polyline = TRUE)
#' }
getAdmin <- function(keywords,
                     key = NULL,
                     subdistrict = NULL,
                     page = NULL,
                     offset = NULL,
                     extensions = NULL,
                     filter = NULL,
                     callback = NULL,
                     output = "tibble",
                     keep_bad_request = TRUE,
                     include_polyline = FALSE,
                     ...) {
  keywords <- as.character(keywords)
  output_upper <- toupper(output)

  if (output_upper != "TIBBLE") {
    return(get_admin_raw(
      keywords,
      key = key,
      subdistrict = subdistrict,
      page = page,
      offset = offset,
      extensions = extensions,
      filter = filter,
      output = output,
      callback = callback,
      keep_bad_request = keep_bad_request
    ))
  }

  rows <- list()
  rate_limits <- list()
  query_index <- seq_along(keywords)

  perform_request <- function(query, key) {
    tryCatch(
      amap_request(
        endpoint = "config/district",
        query = query,
        key = key,
        output = NULL,
        callback = callback
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

  for (i in seq_along(keywords)) {
    keyword <- keywords[[i]]
    query <- list(
      keywords = keyword,
      subdistrict = subdistrict,
      page = page,
      offset = offset,
      extensions = extensions,
      filter = filter
    )
    resp <- perform_request(query, key)
    if (inherits(resp, "amap_request_error")) {
      placeholder <- admin_placeholder(include_polyline)
      placeholder$query <- keyword
      placeholder$query_index <- i
      rows[[length(rows) + 1L]] <- placeholder
      next
    }
    rate_limits[[length(rate_limits) + 1L]] <- attr(resp, "rate_limit")
    parsed <- extractAdmin(resp$body, include_polyline = include_polyline)
    parsed$query <- keyword
    parsed$query_index <- i
    rows[[length(rows) + 1L]] <- parsed
  }

  combined <- dplyr::bind_rows(rows)
  if (!nrow(combined)) {
    return(combined)
  }
  query_index <- depth <- parent_name <- name <- NULL
  combined <- combined |> dplyr::arrange(query_index, depth, parent_name, name)
  combined <- dplyr::select(combined, -query_index)

  rate_limit <- Filter(Negate(is.null), rate_limits)
  if (length(rate_limit)) {
    attr(combined, "rate_limit") <- rate_limit[[length(rate_limit)]]
  }
  attr(combined, "query") <- keywords
  combined
}

get_admin_raw <- function(keywords,
                         key = NULL,
                         subdistrict = NULL,
                         page = NULL,
                         offset = NULL,
                         extensions = NULL,
                         filter = NULL,
                         output = "JSON",
                         callback = NULL,
                         keep_bad_request = TRUE) {
  mapper <- function(keyword) {
    query <- list(
      keywords = keyword,
      subdistrict = subdistrict,
      page = page,
      offset = offset,
      extensions = extensions,
      filter = filter
    )
    tryCatch(
      {
        resp <- amap_request(
          endpoint = "config/district",
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
  results <- lapply(keywords, mapper)
  if (length(keywords) == 1L) {
    results <- results[[1L]]
  }
  results
}

#' Extract subordinate administrative regions from a district response
#'
#' @param res Required.
#' Response object returned by [getAdmin()] with `output = "JSON"` or by the
#' AutoNavi district API.
#' @param include_polyline Logical indicating whether to include the polyline
#' column (requires `extensions = "all"`). Defaults to `FALSE`.
#'
#' @return
#' A `tibble` describing each administrative region present in the response.
#' The table includes parent metadata (`parent_name`, `parent_adcode`,
#' `parent_level`), centre coordinates (`lng`, `lat`), and a `depth` column
#' describing the nesting level (0 for the matched region, 1+ for subregions).
#' When no results are present a single placeholder row filled with `NA` values
#' is returned.
#'
#' @examples
#' \dontrun{
#' raw <- getAdmin("Sichuan Province", output = "JSON")
#' extractAdmin(raw)
#' }
#'
#' @seealso [getAdmin()]
#' @export
extractAdmin <- function(res, include_polyline = FALSE) {
  parsed <- normalize_admin_response(res)
  status <- parsed$status %||% parsed$Status
  if (!is.null(status) && !identical(as.character(status), "1")) {
    rlang::abort(parsed$info %||% parsed$message %||% "AutoNavi API request failed", call = NULL)
  }
  districts <- parsed$districts
  if (is.null(districts) || length(districts) == 0) {
    return(admin_placeholder(include_polyline))
  }
  rows <- unlist(lapply(districts, flatten_districts, include_polyline = include_polyline), recursive = FALSE)
  if (!length(rows)) {
    return(admin_placeholder(include_polyline))
  }
  tbl <- dplyr::bind_rows(rows)
  # When depth > 0 rows exist, return only those (subordinate regions).
  # Otherwise return the matched region itself (depth 0).
  depth <- NULL
  if (any(tbl$depth > 0)) {
    tbl <- dplyr::filter(tbl, depth > 0)
  }
  dplyr::select(tbl, dplyr::all_of(admin_column_order(include_polyline)))
}

normalize_admin_response <- function(res) {
  if (inherits(res, "xml_document")) {
    res <- xml2::as_list(res)$response
  }
  if (is.list(res) && length(res) == 1L && !is.null(res$response)) {
    res <- res$response
  }
  res
}

flatten_districts <- function(district, parent = NULL, depth = 0L, include_polyline = FALSE) {
  row <- district_row(district, parent, depth, include_polyline)
  children <- district$districts
  if (is.null(children) || length(children) == 0) {
    return(list(row))
  }
  child_rows <- unlist(lapply(children, flatten_districts, parent = district, depth = depth + 1L, include_polyline = include_polyline), recursive = FALSE)
  c(list(row), child_rows)
}

district_row <- function(district, parent, depth, include_polyline) {
  center <- scalar_or_na(district$center)
  coords <- if (!is.na(center)) str_loc_to_num_coord(center) else c(NA_real_, NA_real_)
  row <- list(
    parent_name = if (!is.null(parent)) scalar_or_na(parent$name) else NA_character_,
    parent_adcode = if (!is.null(parent)) scalar_or_na(parent$adcode) else NA_character_,
    parent_level = if (!is.null(parent)) scalar_or_na(parent$level) else NA_character_,
    name = scalar_or_na(district$name),
    level = scalar_or_na(district$level),
    citycode = scalar_or_na(district$citycode),
    adcode = scalar_or_na(district$adcode),
    lng = coords[[1L]],
    lat = coords[[2L]],
    depth = depth
  )
  if (isTRUE(include_polyline)) {
    row$polyline <- scalar_or_na(district$polyline)
  }
  row
}

admin_placeholder <- function(include_polyline = FALSE) {
  cols <- admin_column_order(include_polyline)
  empty <- vector("list", length(cols))
  names(empty) <- cols
  for (col in cols) {
    empty[[col]] <- NA_character_
  }
  empty[["lng"]] <- NA_real_
  empty[["lat"]] <- NA_real_
  empty[["depth"]] <- 0L
  tibble::as_tibble(empty)
}

admin_column_order <- function(include_polyline = FALSE) {
  cols <- c(
    "parent_name", "parent_adcode", "parent_level",
    "name", "level", "citycode", "adcode",
    "lng", "lat", "depth"
  )
  if (isTRUE(include_polyline)) {
    cols <- c(cols, "polyline")
  }
  cols
}
