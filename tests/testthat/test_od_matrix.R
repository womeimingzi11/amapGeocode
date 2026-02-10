test_that("getOdMatrix parses cached distance responses", {
  cache_dir <- file.path(tempdir(), "amap_cache_od")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  old_cache <- getOption("amap_cache")
  on.exit(options(amap_cache = old_cache), add = TRUE)
  amap_cache_enable(cache_dir, ttl_days = 30)

  origins <- tibble::tibble(
    id = c("o1", "o2"),
    lng = c(104.043284, 104.05),
    lat = c(30.666864, 30.67)
  )
  destinations <- tibble::tibble(
    id = "h1",
    lng = 104.055,
    lat = 30.672
  )

  # Pre-populate cache for the single expected request.
  query <- list(
    origins = paste(amapGeocode:::num_coord_to_str_loc(origins$lng, origins$lat), collapse = "|"),
    destination = amapGeocode:::num_coord_to_str_loc(destinations$lng, destinations$lat),
    type = "1"
  )
  prepared <- amapGeocode:::amap_prepare_request("distance", query = query, key = NULL, output = NULL)
  request_id <- amapGeocode:::amap_request_id(
    base_url = amapGeocode:::amap_base_url(),
    endpoint = "distance",
    query = prepared$query,
    key_hash = amapGeocode:::amap_key_hash(prepared$query$key),
    output = NULL,
    callback = NULL
  )

  body <- list(
    status = "1",
    infocode = "10000",
    results = list(
      list(origin_id = "1", dest_id = "1", distance = "1000", duration = "600"),
      list(origin_id = "2", dest_id = "1", distance = "2000", duration = "900")
    )
  )
  amapGeocode:::amap_cache_put("distance", request_id, body, meta = list(http_status = 200, infocode = "10000"))

  od <- getOdMatrix(origins, destinations, mode = "driving")
  expect_s3_class(od, "tbl_df")
  expect_equal(nrow(od), 2L)
  expect_equal(od$from_id, c("o1", "o2"))
  expect_equal(od$to_id, c("h1", "h1"))
  expect_equal(od$distance_m, c(1000, 2000))
  expect_equal(od$duration_s, c(600, 900))
})

test_that("asAccessibilityInput creates travel_time in minutes", {
  od <- tibble::tibble(from_id = "o1", to_id = "h1", duration_s = 600)
  out <- asAccessibilityInput(od)
  expect_equal(out$travel_time, 10)
})
