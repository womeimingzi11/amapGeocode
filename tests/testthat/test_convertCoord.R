test_that("convertCoord returns converted numeric coordinates", {
  vcr::use_cassette("convert_basic", {
    res <- convertCoord("116.481499,39.990475", coordsys = "gps")
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "tbl_df")
  expect_true(!is.na(res$lng[1]))
  expect_true(!is.na(res$lat[1]))
})

test_that("extractConvertCoord parses raw response", {
  raw <- NULL
  vcr::use_cassette("convert_basic_json", {
    raw <- convertCoord("116.481499,39.990475", coordsys = "gps", output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractConvertCoord(raw)
  expect_true(tibble::is_tibble(parsed))
  expect_true(nrow(parsed) > 0)
  expect_true(!is.na(parsed$lng[1]))
  expect_true(!is.na(parsed$lat[1]))
})
