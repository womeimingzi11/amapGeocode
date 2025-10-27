test_that("convertCoord returns converted numeric coordinates", {
  vcr::use_cassette("convert_basic", {
    res <- convertCoord("116.481499,39.990475", coordsys = "gps")
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  expect_equal(res$lng, 116.487585)
  expect_equal(res$lat, 39.991754)
})

test_that("extractConvertCoord parses raw response", {
  raw <- vcr::use_cassette("convert_basic", {
    convertCoord("116.481499,39.990475", coordsys = "gps", output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractConvertCoord(raw)
  expect_equal(parsed$lng, 116.487585)
  expect_equal(parsed$lat, 39.991754)
})
