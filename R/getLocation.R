#' Get location from coordinate
#'
#' @param lng Required.
#' Longitude in decimal degrees. Can be a numeric vector.
#' @param lat Required.
#' Latitude in decimal degrees. Must be the same length as `lng`.
#' @param key Optional.
#' AutoNavi API key. You can also set this globally via
#' `options(amap_key = "your-key")`.
#' @param poitype Optional.
#' Return nearby POI types. Only meaningful when `extensions = "all"`.
#' @param radius Optional.
#' Search radius in metres (0-3000).
#' @param extensions Optional.
#' Either `"base"` (default) or `"all"` to request extended detail payloads.
#' @param roadlevel Optional.
#' Road level filter. Only applies when `extensions = "all"`.
#' @param sig Optional.
#' Manual digital signature. Most workflows can enable automatic signing via
#' [with_amap_signature()] or [amap_config()].
#' @param output Optional.
#' Output format. Supported values are `"tibble"` (default), `"JSON"`,
#' and `"XML"`.
#' @param callback Optional.
#' JSONP callback. When supplied the raw response string is returned.
#' @param homeorcorp Optional.
#' Optimise POI ordering: `0` (default) for none, `1` for home-centric, `2` for
#' corporate-centric ordering.
#' @param keep_bad_request Optional.
#' When `TRUE` (default) API errors are converted into placeholder rows so that
#' batched workflows continue. When `FALSE` errors are raised as
#' `amap_api_error` conditions.
#' @param batch Optional.
#' When `TRUE`, requests are chunked into groups of ten coordinates using the
#' API's batch mode. Defaults to `FALSE` for backwards compatibility.
#' @param details Optional.
#' Character vector describing which extended list-columns to include in the
#' parsed output. Supported values are `"pois"`, `"roads"`, `"roadinters"`,
#' and `"aois"`. Use `"all"` to include every detail payload. Defaults to
#' `NULL`, which omits nested payloads.
#' @param ... Optional.
#' Included for forward compatibility only.
#'
#' @return
#' When `output = "tibble"`, a `tibble` with one row per coordinate is
#' returned. The table preserves the input order and gains a `rate_limit`
#' attribute containing any rate limit headers returned by the API. When
#' `details` are requested, corresponding list-columns (`pois`, `roads`,
#' `roadinters`, `aois`) contain nested `tibble` objects. When `output` is
#' `"JSON"` or `"XML"`, the parsed body is returned without further
#' processing.
#'
#' @seealso [extractLocation()], [with_amap_signature()], [amap_config()]
#' @export
#'
#' @examples
#' \dontrun{
#' getLocation(104.043284, 30.666864)
#'
#' # Request extended POI details
#' getLocation(104.043284, 30.666864,
#'             extensions = "all", details = "pois")
#'
#' # Batch reverse-geocode ten points at a time
#' lngs <- rep(104.043284, 12)
#' lats <- rep(30.666864, 12)
#' getLocation(lngs, lats, batch = TRUE)
#' }
getLocation <- function(lng,
                        lat,
                        key = NULL,
                        poitype = NULL,
                        radius = NULL,
                        extensions = NULL,
                        roadlevel = NULL,
                        sig = NULL,
                        output = "tibble",
                        callback = NULL,
                        homeorcorp = 0,
                        keep_bad_request = TRUE,
                        batch = FALSE,
                        details = NULL,
                        ...) {
  if (length(lng) != length(lat)) {
    rlang::abort("The numbers of longitude and latitude values are mismatched", call = NULL)
  }
  output_upper <- toupper(output)
  details <- normalize_location_details(details)
  coords <- num_coord_to_str_loc(lng, lat)

  if (output_upper != "TIBBLE") {
    return(get_location_raw(
      coords,
      key = key,
      poitype = poitype,
      radius = radius,
      extensions = extensions,
      roadlevel = roadlevel,
      sig = sig,
      output = output,
      callback = callback,
      homeorcorp = homeorcorp,
      keep_bad_request = keep_bad_request
    ))
  }

  rows <- list()
  rate_limits <- list()
  query_index <- seq_along(coords)

  perform_request <- function(query, key, chunk_size = 1L) {
    tryCatch(
      amap_request(
        endpoint = "geocode/regeo",
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

  if (isTRUE(batch) && length(coords) > 1L) {
    indices <- split(seq_along(coords), ceiling(seq_along(coords) / 10))
    for (idx in indices) {
      chunk_coords <- coords[idx]
      query <- list(
        location = paste(chunk_coords, collapse = "|"),
        batch = "true",
        poitype = poitype,
        radius = radius,
        extensions = extensions,
        roadlevel = roadlevel,
        sig = sig,
        homeorcorp = homeorcorp
      )
      resp <- perform_request(query, key, chunk_size = length(idx))
      if (inherits(resp, "amap_request_error")) {
        rows[[length(rows) + 1L]] <- location_placeholder(length(idx), details)
        rows[[length(rows)]]$query_index <- query_index[idx]
        rows[[length(rows)]]$query_lng <- lng[idx]
        rows[[length(rows)]]$query_lat <- lat[idx]
        next
      }
      rate_limits[[length(rate_limits) + 1L]] <- attr(resp, "rate_limit")
      rows[[length(rows) + 1L]] <- parse_batch_location(
        resp$body,
        coords = chunk_coords,
        lng = lng[idx],
        lat = lat[idx],
        indices = query_index[idx],
        details = details
      )
    }
  } else {
    for (i in seq_along(coords)) {
      query <- list(
        location = coords[[i]],
        poitype = poitype,
        radius = radius,
        extensions = extensions,
        roadlevel = roadlevel,
        sig = sig,
        homeorcorp = homeorcorp
      )
      resp <- perform_request(query, key)
      if (inherits(resp, "amap_request_error")) {
        rows[[length(rows) + 1L]] <- location_placeholder(1L, details)
        rows[[length(rows)]]$query_index <- i
        rows[[length(rows)]]$query_lng <- lng[[i]]
        rows[[length(rows)]]$query_lat <- lat[[i]]
        next
      }
      rate_limits[[length(rate_limits) + 1L]] <- attr(resp, "rate_limit")
      rows[[length(rows) + 1L]] <- parse_single_location(
        resp$body,
        lng = lng[[i]],
        lat = lat[[i]],
        index = i,
        details = details
      )
    }
  }

  combined <- dplyr::bind_rows(rows)
  if (!nrow(combined)) {
    return(location_finalize(combined, details))
  }
  combined <- combined |> dplyr::arrange(query_index)
  result <- location_finalize(combined, details)

  rate_limit <- Filter(Negate(is.null), rate_limits)
  if (length(rate_limit)) {
    attr(result, "rate_limit") <- rate_limit[[length(rate_limit)]]
  }
  attr(result, "query") <- tibble::tibble(lng = lng, lat = lat)
  result
}

get_location_raw <- function(coords,
                            key = NULL,
                            poitype = NULL,
                            radius = NULL,
                            extensions = NULL,
                            roadlevel = NULL,
                            sig = NULL,
                            output = "JSON",
                            callback = NULL,
                            homeorcorp = 0,
                            keep_bad_request = TRUE) {
  mapper <- function(coord) {
    query <- list(
      location = coord,
      poitype = poitype,
      radius = radius,
      extensions = extensions,
      roadlevel = roadlevel,
      sig = sig,
      homeorcorp = homeorcorp
    )
    tryCatch(
      {
        resp <- amap_request(
          endpoint = "geocode/regeo",
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
  results <- lapply(coords, mapper)
  if (length(coords) == 1L) {
    results <- results[[1L]]
  }
  results
}

#' Extract location from coordinate request
#'
#' @param res Required.
#' Response object returned by [getLocation()] with `output = "JSON"` or by the
#' AutoNavi reverse-geocoding API.
#' @param details Optional.
#' Character vector describing which extended detail payloads to parse into
#' list-columns. Valid values are `"pois"`, `"roads"`, `"roadinters"`, and
#' `"aois"`. Use `"all"` to include every detail payload.
#'
#' @return
#' A `tibble` describing the parsed reverse-geocode results. Each row
#' corresponds to an element in the API response. When no data is present a
#' single placeholder row filled with `NA` values is returned.
#'
#' @examples
#' \dontrun{
#' raw <- getLocation(104.043284, 30.666864, output = "JSON")
#' extractLocation(raw, details = c("pois", "roads"))
#' }
#'
#' @seealso [getLocation()]
#' @export
extractLocation <- function(res, details = NULL) {
  details <- normalize_location_details(details)
  entries <- location_entries_from_body(res)
  if (!length(entries)) {
    out <- location_placeholder(1L, details)
    out <- dplyr::select(out, -query_index, -query_lng, -query_lat)
    return(out)
  }
  rows <- lapply(entries, function(entry) location_entry_to_dt(entry, details = details))
  tbl <- dplyr::bind_rows(rows)
  drop <- intersect(c("query_index", "query_lng", "query_lat"), names(tbl))
  if (length(drop)) {
    tbl <- dplyr::select(tbl, -dplyr::all_of(drop))
  }
  tbl
}

normalize_location_details <- function(details) {
  if (is.null(details)) {
    return(character())
  }
  details <- tolower(details)
  if ("all" %in% details) {
    details <- c(details, "pois", "roads", "roadinters", "aois")
  }
  valid <- c("pois", "roads", "roadinters", "aois")
  invalid <- setdiff(details, valid)
  if (length(invalid)) {
    rlang::abort(sprintf("Unknown detail type(s): %s", paste(invalid, collapse = ", ")), call = NULL)
  }
  unique(intersect(details, valid))
}

location_entries_from_body <- function(body) {
  parsed <- normalize_location_response(body)
  entries <- parsed$regeocodes
  if (is.null(entries) && !is.null(parsed$regeocode)) {
    entries <- list(parsed$regeocode)
  }
  entries %||% list()
}

normalize_location_response <- function(res) {
  if (inherits(res, "xml_document")) {
    res <- xml2::as_list(res)$response
  }
  if (is.list(res) && length(res) == 1L && !is.null(res$response)) {
    res <- res$response
  }
  res
}

parse_single_location <- function(body, lng, lat, index, details) {
  entries <- location_entries_from_body(body)
  if (!length(entries)) {
    out <- location_placeholder(1L, details)
    out$query_index <- index
    out$query_lng <- lng
    out$query_lat <- lat
    return(out)
  }
  rows <- lapply(entries, function(entry) location_entry_to_dt(entry, details = details))
  tbl <- dplyr::bind_rows(rows)
  tbl$query_index <- index
  tbl$query_lng <- lng
  tbl$query_lat <- lat
  tbl
}

parse_batch_location <- function(body, coords, lng, lat, indices, details) {
  entries <- location_entries_from_body(body)
  rows <- vector("list", length(indices))
  for (i in seq_along(indices)) {
    entry <- if (length(entries) >= i) entries[[i]] else NULL
    rows[[i]] <- location_entry_to_dt(entry, details = details)
    rows[[i]]$query_index <- indices[[i]]
    rows[[i]]$query_lng <- lng[[i]]
    rows[[i]]$query_lat <- lat[[i]]
  }
  dplyr::bind_rows(rows)
}

location_finalize <- function(tbl, details) {
  base_cols <- c(
    "formatted_address", "country", "province", "city", "district",
    "township", "citycode", "towncode", "adcode", "street", "number",
    "neighborhood", "building"
  )
  detail_cols <- intersect(c("pois", "roads", "roadinters", "aois"), details)
  query_index <- query_lng <- query_lat <- NULL
  if (!nrow(tbl)) {
    result <- dplyr::select(tbl, dplyr::all_of(c(base_cols, detail_cols, "query_index", "query_lng", "query_lat")))
  } else {
    ordered <- c("query_index", "query_lng", "query_lat", base_cols, detail_cols)
    present <- intersect(ordered, names(tbl))
    tbl <- dplyr::arrange(tbl, query_index)
    result <- dplyr::select(tbl, dplyr::all_of(present))
  }
  drop <- intersect(c("query_index", "query_lng", "query_lat"), names(result))
  if (length(drop)) {
    result <- dplyr::select(result, -dplyr::all_of(drop))
  }
  result
}

location_placeholder <- function(n = 1L, details = character()) {
  tbl <- location_template(n, details)
  tbl
}

location_template <- function(n = 1L, details = character()) {
  tbl <- tibble::tibble(
    formatted_address = rep(NA_character_, n),
    country = rep(NA_character_, n),
    province = rep(NA_character_, n),
    city = rep(NA_character_, n),
    district = rep(NA_character_, n),
    township = rep(NA_character_, n),
    citycode = rep(NA_character_, n),
    towncode = rep(NA_character_, n),
    adcode = rep(NA_character_, n),
    street = rep(NA_character_, n),
    number = rep(NA_character_, n),
    neighborhood = rep(NA_character_, n),
    building = rep(NA_character_, n),
    query_index = rep(NA_integer_, n),
    query_lng = rep(NA_real_, n),
    query_lat = rep(NA_real_, n)
  )
  if ("pois" %in% details) {
    tbl$pois <- rep(list(empty_detail_table("pois")), n)
  }
  if ("roads" %in% details) {
    tbl$roads <- rep(list(empty_detail_table("roads")), n)
  }
  if ("roadinters" %in% details) {
    tbl$roadinters <- rep(list(empty_detail_table("roadinters")), n)
  }
  if ("aois" %in% details) {
    tbl$aois <- rep(list(empty_detail_table("aois")), n)
  }
  tbl
}

location_entry_to_dt <- function(entry, details = character()) {
  row <- location_template(1L, details)
  if (is.null(entry)) {
    return(row)
  }
  formatted_address_val <- scalar_or_na(entry$formatted_address)
  address_component <- entry$addressComponent %||% list()
  street_number <- address_component$streetNumber %||% list()
  neighborhood_val <- address_component$neighborhood %||% list()
  building_val <- address_component$building %||% list()
  row <- dplyr::mutate(row,
    formatted_address = formatted_address_val,
    country = scalar_or_na(address_component$country),
    province = scalar_or_na(address_component$province),
    city = scalar_or_na(address_component$city),
    district = scalar_or_na(address_component$district),
    township = scalar_or_na(address_component$township),
    citycode = scalar_or_na(address_component$citycode),
    towncode = scalar_or_na(address_component$towncode),
    adcode = scalar_or_na(address_component$adcode),
    street = scalar_or_na(street_number$street),
    number = scalar_or_na(street_number$number),
    neighborhood = scalar_or_na(neighborhood_val$name),
    building = scalar_or_na(building_val$name)
  )
  if ("pois" %in% details) {
    row$pois <- list(detail_table(entry$pois, "pois"))
  }
  if ("roads" %in% details) {
    row$roads <- list(detail_table(entry$roads, "roads"))
  }
  if ("roadinters" %in% details) {
    row$roadinters <- list(detail_table(entry$roadinters, "roadinters"))
  }
  if ("aois" %in% details) {
    row$aois <- list(detail_table(entry$aois, "aois"))
  }
  row
}

empty_detail_table <- function(type) {
  fields <- location_detail_fields()[[type]]
  if (is.null(fields)) {
    return(tibble::tibble())
  }
  empty <- rep(list(character()), length(fields))
  names(empty) <- fields
  dt <- tibble::as_tibble(empty)
  dplyr::slice(dt, 0)
}

detail_table <- function(items, type) {
  fields <- location_detail_fields()[[type]]
  if (is.null(items) || length(items) == 0) {
    return(empty_detail_table(type))
  }
  rows <- lapply(items, function(item) {
    values <- lapply(fields, function(field) scalar_or_na(item[[field]]))
    tibble::as_tibble(as.list(rlang::set_names(values, fields)))
  })
  dplyr::bind_rows(rows)
}

location_detail_fields <- function() {
  list(
    pois = c("id", "name", "type", "typecode", "distance", "direction",
             "address", "location", "businessarea"),
    roads = c("id", "name", "direction", "distance", "location"),
    roadinters = c("direction", "distance", "location", "first_id",
                   "first_name", "second_id", "second_name"),
    aois = c("id", "name", "adcode", "location", "area", "distance", "type")
  )
}
