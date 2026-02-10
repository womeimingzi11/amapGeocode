test_that("amap_request reads from cache and writes audit log without secrets", {
  cache_dir <- file.path(tempdir(), "amap_cache_test")
  audit_dir <- file.path(tempdir(), "amap_audit_test")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

  old_cache <- getOption("amap_cache")
  old_audit <- getOption("amap_audit")
  on.exit({
    options(amap_cache = old_cache)
    options(amap_audit = old_audit)
  }, add = TRUE)

  amap_cache_enable(cache_dir, ttl_days = 30)
  amap_audit_enable(audit_dir)

  query <- list(origins = "104.043284,30.666864", destination = "104.055,30.672", type = "1")
  key <- getOption("amap_key")
  expect_true(nzchar(key))

  prepared <- amapGeocode:::amap_prepare_request("distance", query = query, key = NULL, output = "JSON")
  request_id <- amapGeocode:::amap_request_id(
    base_url = amapGeocode:::amap_base_url(),
    endpoint = "distance",
    query = prepared$query,
    key_hash = amapGeocode:::amap_key_hash(prepared$query$key),
    output = "JSON",
    callback = NULL
  )

  body <- list(status = "1", info = "OK", infocode = "10000", results = list())
  amapGeocode:::amap_cache_put("distance", request_id, body, meta = list(http_status = 200, infocode = "10000"))

  resp <- amapGeocode:::amap_request("distance", query = query, output = "JSON")
  expect_s3_class(resp, "amap_response")
  expect_equal(resp$body$infocode, "10000")
  expect_equal(attr(resp, "request_id"), request_id)

  audit_path <- file.path(audit_dir, "amap_audit.jsonl")
  expect_true(file.exists(audit_path))
  lines <- readLines(audit_path, warn = FALSE)
  expect_true(length(lines) >= 1L)
  last <- jsonlite::fromJSON(lines[[length(lines)]], simplifyVector = FALSE)
  expect_true(isTRUE(last$cache_hit))
  expect_false(grepl(key, lines[[length(lines)]], fixed = TRUE))
})

test_that("expired cache entries are ignored", {
  cache_dir <- file.path(tempdir(), "amap_cache_test_expired")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

  old_cache <- getOption("amap_cache")
  on.exit(options(amap_cache = old_cache), add = TRUE)

  amap_cache_enable(cache_dir, ttl_days = 30)

  request_id <- "expired"
  path <- file.path(cache_dir, "distance", paste0(request_id, ".rds"))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  saveRDS(
    list(
      body = list(status = "1", infocode = "10000"),
      meta = list(
        created_at = "1970-01-01 00:00:00 UTC",
        expires_at = "1970-01-01 00:00:00 UTC",
        pkg_version = "dev",
        endpoint = "distance"
      )
    ),
    path
  )

  got <- amapGeocode:::amap_cache_get("distance", request_id)
  expect_null(got)
})
