test_that("geocodeData deduplicates and joins back in order (cached)", {
  cache_dir <- file.path(tempdir(), "amap_cache_geocode_data")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  old_cache <- getOption("amap_cache")
  on.exit(options(amap_cache = old_cache), add = TRUE)
  amap_cache_enable(cache_dir, ttl_days = 30)

  data <- tibble::tibble(address = c("A", "B", "A"))

  # geocodeData will batch unique addresses (A,B) into one request.
  query <- list(address = "A|B", batch = "true", sig = NULL)
  prepared <- amapGeocode:::amap_prepare_request("geocode/geo", query = query, key = NULL, output = NULL, callback = NULL)
  request_id <- amapGeocode:::amap_request_id(
    base_url = amapGeocode:::amap_base_url(),
    endpoint = "geocode/geo",
    query = prepared$query,
    key_hash = amapGeocode:::amap_key_hash(prepared$query$key),
    output = NULL,
    callback = NULL
  )

  body <- list(
    status = "1",
    infocode = "10000",
    count = "2",
    geocodes = list(
      list(location = "104.0,30.0", formatted_address = "Addr A", city = "成都市", adcode = "510100"),
      list(location = "104.1,30.1", formatted_address = "Addr B", city = "成都市", adcode = "510100")
    )
  )
  amapGeocode:::amap_cache_put("geocode/geo", request_id, body, meta = list(http_status = 200, infocode = "10000"))

  out <- geocodeData(data, address_col = address, mode = "best", deduplicate = TRUE, join_back = TRUE)
  expect_equal(nrow(out), 3L)
  expect_true(all(c("lng", "lat", "formatted_address") %in% names(out)))
  expect_equal(out$formatted_address, c("Addr A", "Addr B", "Addr A"))
})

