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
#' Output format. Supported values are `"data.table"` (default), `"JSON"`,
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
#' When `output = "data.table"`, a `data.table` with one row per coordinate is
#' returned. The table preserves the input order and gains a `rate_limit`
#' attribute containing any rate limit headers returned by the API. When
#' `details` are requested, corresponding list-columns (`pois`, `roads`,
#' `roadinters`, `aois`) contain nested `data.table` objects. When `output` is
#' `"JSON"` or `"XML"`, the parsed body is returned without further
#' processing.
#'
#' @seealso [extractLocation()], [with_amap_signature()], [amap_config()]
#' @export
#'
#' @examples
#' \\dontrun{
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
                        output = "data.table",
                        callback = NULL,
                        homeorcorp = 0,
                        keep_bad_request = TRUE,
                        batch = FALSE,
                        details = NULL,
                        ...) {
  if (length(lng) != length(lat)) {
    stop("The numbers of longitude and latitude values are mismatched", call. = FALSE)
  }
  output_upper <- toupper(output)
  details <- normalize_location_details(details)
  coords <- num_coord_to_str_loc(lng, lat)

  if (output_upper != "DATA.TABLE") {
    return(getLocation_raw(
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
        rows[[length(rows)]][, `:=`(
          query_index = query_index[idx],
          query_lng = lng[idx],
          query_lat = lat[idx]
        )]
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
        rows[[length(rows)]][, `:=`(query_index = i, query_lng = lng[[i]], query_lat = lat[[i]])]
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

  combined <- data.table::rbindlist(rows, fill = TRUE)
  if (!nrow(combined)) {
    return(location_finalize(combined, details))
  }
  combined <- combined[order(query_index)]
  result <- location_finalize(combined, details)

  rate_limit <- Filter(Negate(is.null), rate_limits)
  if (length(rate_limit)) {
    attr(result, "rate_limit") <- rate_limit[[length(rate_limit)]]
  }
  attr(result, "query") <- data.frame(lng = lng, lat = lat)
  result
}

getLocation_raw <- function(coords,
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
#' A `data.table` describing the parsed reverse-geocode results. Each row
#' corresponds to an element in the API response. When no data is present a
#' single placeholder row filled with `NA` values is returned.
#'
#' @examples
#' \\dontrun{
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
    out[, c("query_index", "query_lng", "query_lat") := NULL]
    return(out)
  }
  rows <- lapply(entries, function(entry) location_entry_to_dt(entry, details = details))
  tbl <- data.table::rbindlist(rows, fill = TRUE)
  drop <- intersect(c("query_index", "query_lng", "query_lat"), names(tbl))
  if (length(drop)) {
    tbl[, (drop) := NULL]
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
    stop(sprintf("Unknown detail type(s): %s", paste(invalid, collapse = ", ")), call. = FALSE)
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
    out[, `:=`(query_index = index, query_lng = lng, query_lat = lat)]
    return(out)
  }
  rows <- lapply(entries, function(entry) location_entry_to_dt(entry, details = details))
  tbl <- data.table::rbindlist(rows, fill = TRUE)
  tbl[, `:=`(query_index = index, query_lng = lng, query_lat = lat)]
  tbl
}

parse_batch_location <- function(body, coords, lng, lat, indices, details) {
  entries <- location_entries_from_body(body)
  rows <- vector("list", length(indices))
  for (i in seq_along(indices)) {
    entry <- if (length(entries) >= i) entries[[i]] else NULL
    rows[[i]] <- location_entry_to_dt(entry, details = details)
    rows[[i]][, `:=`(query_index = indices[[i]], query_lng = lng[[i]], query_lat = lat[[i]])]
  }
  data.table::rbindlist(rows, fill = TRUE)
}

location_finalize <- function(tbl, details) {
  base_cols <- c(
    "formatted_address", "country", "province", "city", "district",
    "township", "citycode", "towncode", "adcode", "street", "number",
    "neighborhood", "building"
  )
  detail_cols <- intersect(c("pois", "roads", "roadinters", "aois"), details)
  if (!nrow(tbl)) {
    result <- tbl[, c(base_cols, detail_cols, "query_index", "query_lng", "query_lat"), with = FALSE]
  } else {
    ordered <- c("query_index", "query_lng", "query_lat", base_cols, detail_cols)
    present <- intersect(ordered, names(tbl))
    data.table::setorder(tbl, query_index)
    result <- tbl[, ..present]
  }
  drop <- intersect(c("query_index", "query_lng", "query_lat"), names(result))
  if (length(drop)) {
    result[, (drop) := NULL]
  }
  result
}

location_placeholder <- function(n = 1L, details = character()) {
  tbl <- location_template(n, details)
  tbl
}

location_template <- function(n = 1L, details = character()) {
  tbl <- data.table::data.table(
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
    tbl[, pois := rep(list(empty_detail_table("pois")), n)]
  }
  if ("roads" %in% details) {
    tbl[, roads := rep(list(empty_detail_table("roads")), n)]
  }
  if ("roadinters" %in% details) {
    tbl[, roadinters := rep(list(empty_detail_table("roadinters")), n)]
  }
  if ("aois" %in% details) {
    tbl[, aois := rep(list(empty_detail_table("aois")), n)]
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
  row[, `:=`(
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
  )]
  if ("pois" %in% details) {
    row[, pois := list(list(detail_table(entry$pois, "pois")))]
  }
  if ("roads" %in% details) {
    row[, roads := list(list(detail_table(entry$roads, "roads")))]
  }
  if ("roadinters" %in% details) {
    row[, roadinters := list(list(detail_table(entry$roadinters, "roadinters")))]
  }
  if ("aois" %in% details) {
    row[, aois := list(list(detail_table(entry$aois, "aois")))]
  }
  row
}

empty_detail_table <- function(type) {
  fields <- location_detail_fields()[[type]]
  if (is.null(fields)) {
    return(data.table::data.table())
  }
  empty <- rep(list(character()), length(fields))
  names(empty) <- fields
  dt <- data.table::as.data.table(empty)
  data.table::setnames(dt, fields)
  dt[0]
}

detail_table <- function(items, type) {
  fields <- location_detail_fields()[[type]]
  if (is.null(items) || length(items) == 0) {
    return(empty_detail_table(type))
  }
  rows <- lapply(items, function(item) {
    values <- lapply(fields, function(field) scalar_or_na(item[[field]]))
    data.table::as.data.table(as.list(stats::setNames(values, fields)))
  })
  data.table::rbindlist(rows, fill = TRUE)
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
