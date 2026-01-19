test_that("getLocation returns basic reverse geocode data", {
  vcr::use_cassette("regeo_basic", {
    res <- getLocation(104.043284, 30.666864)
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  expect_equal(nrow(res), 1L)
  expect_equal(res$city, "成都市")
  expect_equal(res$district, "锦江区")
})

test_that("getLocation returns detail list-columns when requested", {
  vcr::use_cassette("regeo_details", {
    res <- getLocation(104.05, 30.67,
                       extensions = "all",
                       details = c("pois", "roads", "roadinters", "aois"))
  }, match_requests_on = c("method", "uri"))

  expect_true(all(c("pois", "roads", "roadinters", "aois") %in% names(res)))
  expect_s3_class(res$pois[[1]], "data.table")
  expect_gt(nrow(res$pois[[1]]), 0L)
  expect_gt(nrow(res$roads[[1]]), 0L)
})

test_that("getLocation batch preserves order", {
  vcr::use_cassette("regeo_batch", {
    res <- getLocation(c(104.043284, 104.05), c(30.666864, 30.67), batch = TRUE)
  }, match_requests_on = c("method", "uri"))

  expect_equal(nrow(res), 2L)
  expect_type(res$formatted_address, "character")
  expect_true(res$formatted_address[1] != res$formatted_address[2])
})

test_that("extractLocation parses detail payload", {
  raw <- vcr::use_cassette("regeo_details_json", {
    getLocation(104.05, 30.67,
                extensions = "all",
                details = NULL,
                output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractLocation(raw, details = "pois")
  expect_equal(names(parsed), c(
    "formatted_address", "country", "province", "city", "district",
    "township", "citycode", "towncode", "adcode", "street", "number",
    "neighborhood", "building", "pois"
  ))
  expect_s3_class(parsed$pois[[1]], "data.table")
})

test_that("invalid detail types error", {
  expect_error(extractLocation(list(), details = "invalid"), "Unknown detail type")
})
