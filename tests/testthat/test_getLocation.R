test_that("getLocation returns basic reverse geocode data", {
  vcr::use_cassette("regeo_basic", {
    res <- getLocation(104.043284, 30.666864)
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  expect_equal(nrow(res), 1L)
  expect_equal(res$city, "Chengdu")
  expect_equal(res$district, "Jinjiang")
})

test_that("getLocation returns detail list-columns when requested", {
  vcr::use_cassette("regeo_details", {
    res <- getLocation(104.05, 30.67,
                       extensions = "all",
                       details = c("pois", "roads", "roadinters", "aois"))
  }, match_requests_on = c("method", "uri"))

  expect_true(all(c("pois", "roads", "roadinters", "aois") %in% names(res)))
  expect_s3_class(res$pois[[1]], "data.table")
  expect_equal(res$pois[[1]]$name, "Mall")
  expect_equal(res$roads[[1]]$name, "Zhonghua Road")
})

test_that("getLocation batch preserves order", {
  vcr::use_cassette("regeo_batch", {
    res <- getLocation(c(104.043284, 104.05), c(30.666864, 30.67), batch = TRUE)
  }, match_requests_on = c("method", "uri"))

  expect_equal(nrow(res), 2L)
  expect_equal(res$formatted_address, c("Addr A", "Addr B"))
})

test_that("extractLocation parses detail payload", {
  raw <- vcr::use_cassette("regeo_details", {
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
  expect_equal(parsed$pois[[1]]$name, "Mall")
})

test_that("invalid detail types error", {
  expect_error(extractLocation(list(), details = "invalid"), "Unknown detail type")
})
