test_that("convertCoord returns converted numeric coordinates", {
  vcr::use_cassette("convert_basic", {
    res <- convertCoord("116.481499,39.990475", coordsys = "gps")
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  expect_true(!is.na(res$lng))
  expect_true(!is.na(res$lat))
})

test_that("extractConvertCoord parses raw response", {
  raw <- vcr::use_cassette("convert_basic_json", {
    convertCoord("116.481499,39.990475", coordsys = "gps", output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractConvertCoord(raw)
  expect_true(!is.na(parsed$lng))
  expect_true(!is.na(parsed$lat))
})
