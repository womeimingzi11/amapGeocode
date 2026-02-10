# Cache utilities for amapGeocode

amap_cache_settings <- function() {
  settings <- getOption("amap_cache")
  defaults <- list(
    enabled = FALSE,
    path = NULL,
    ttl_days = 30,
    key_scope = "hash_key",
    compress = TRUE
  )
  if (is.null(settings)) {
    return(defaults)
  }
  utils::modifyList(defaults, settings)
}

amap_cache_enabled <- function() {
  settings <- amap_cache_settings()
  isTRUE(settings$enabled) && !is.null(settings$path) && nzchar(settings$path)
}

amap_cache_dir <- function() {
  settings <- amap_cache_settings()
  settings$path
}

amap_pkg_version <- function() {
  tryCatch(as.character(utils::packageVersion("amapGeocode")), error = function(e) "dev")
}

amap_key_hash <- function(key) {
  if (is.null(key) || !nzchar(key)) {
    return(NA_character_)
  }
  digest::digest(key, algo = "md5", serialize = FALSE)
}

amap_cache_normalize_query <- function(query) {
  if (is.null(query)) {
    return(list())
  }
  query <- query
  query$key <- NULL
  query$sig <- NULL
  query
}

amap_query_fingerprint <- function(query) {
  query <- amap_cache_normalize_query(query)
  if (!length(query)) {
    return(digest::digest(list(), algo = "md5", serialize = TRUE))
  }
  query_names <- names(query)
  if (!is.null(query_names)) {
    query <- query[order(query_names)]
  }
  digest::digest(query, algo = "md5", serialize = TRUE)
}

amap_request_id <- function(base_url, endpoint, query, key_hash = NA_character_, output = NULL, callback = NULL) {
  settings <- amap_cache_settings()
  key_scope <- settings$key_scope %||% "hash_key"
  if (!key_scope %in% c("hash_key", "shared")) {
    key_scope <- "hash_key"
  }
  parts <- list(
    base_url = base_url,
    endpoint = endpoint,
    query_fingerprint = amap_query_fingerprint(query),
    pkg_version = amap_pkg_version(),
    output = output %||% "",
    callback = callback %||% ""
  )
  if (identical(key_scope, "hash_key")) {
    parts$key_hash <- key_hash %||% NA_character_
  }
  digest::digest(parts, algo = "md5", serialize = TRUE)
}

amap_cache_path_for <- function(endpoint, request_id) {
  endpoint_safe <- gsub("[^A-Za-z0-9_./-]", "_", endpoint)
  file.path(amap_cache_dir(), endpoint_safe, paste0(request_id, ".rds"))
}

amap_cache_get <- function(endpoint, request_id) {
  if (!amap_cache_enabled()) {
    return(NULL)
  }
  path <- amap_cache_path_for(endpoint, request_id)
  if (!file.exists(path)) {
    return(NULL)
  }
  entry <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(entry) || !is.list(entry) || is.null(entry$meta)) {
    return(NULL)
  }
  expires_at <- entry$meta$expires_at
  if (!is.null(expires_at)) {
    expires_at <- suppressWarnings(as.POSIXct(expires_at, tz = "UTC"))
    if (!is.na(expires_at) && expires_at < as.POSIXct(Sys.time(), tz = "UTC")) {
      return(NULL)
    }
  }
  entry
}

amap_cache_put <- function(endpoint, request_id, body, meta) {
  if (!amap_cache_enabled()) {
    return(invisible(FALSE))
  }
  settings <- amap_cache_settings()
  ttl_days <- settings$ttl_days %||% 30
  now <- as.POSIXct(Sys.time(), tz = "UTC")
  expires_at <- now + as.difftime(ttl_days, units = "days")
  meta <- utils::modifyList(
    list(
      created_at = format(now, tz = "UTC", usetz = TRUE),
      expires_at = format(expires_at, tz = "UTC", usetz = TRUE),
      pkg_version = amap_pkg_version(),
      endpoint = endpoint
    ),
    meta %||% list()
  )
  path <- amap_cache_path_for(endpoint, request_id)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  entry <- list(body = body, meta = meta)
  saveRDS(entry, path, compress = isTRUE(settings$compress))
  invisible(TRUE)
}

#' Enable request cache for amapGeocode
#'
#' @param path Required.
#' Directory used for the cache store.
#' @param ttl_days Optional.
#' Number of days before cached responses expire. Defaults to 30.
#' @param key_scope Optional.
#' `"hash_key"` (default) isolates caches per API key (stored only as a hash),
#' while `"shared"` shares cache entries across keys.
#' @param compress Optional.
#' Whether to compress cached RDS files. Defaults to `TRUE`.
#' @export
amap_cache_enable <- function(path,
                              ttl_days = 30,
                              key_scope = c("hash_key", "shared"),
                              compress = TRUE) {
  key_scope <- match.arg(key_scope)
  if (missing(path) || is.null(path) || !nzchar(path)) {
    rlang::abort("`path` must be a non-empty string.", call = NULL)
  }
  if (!is.numeric(ttl_days) || length(ttl_days) != 1L || is.na(ttl_days) || ttl_days < 0) {
    rlang::abort("`ttl_days` must be a single non-negative number.", call = NULL)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  options(amap_cache = list(
    enabled = TRUE,
    path = path,
    ttl_days = ttl_days,
    key_scope = key_scope,
    compress = isTRUE(compress)
  ))
  invisible(NULL)
}

#' Disable request cache for amapGeocode
#' @export
amap_cache_disable <- function() {
  options(amap_cache = list(enabled = FALSE))
  invisible(NULL)
}
