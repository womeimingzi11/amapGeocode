test_that("getCoord returns best match with rate limit metadata", {
  vcr::use_cassette("geocode_best", {
    res <- getCoord("Chengdu IFS")
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  expect_equal(nrow(res), 1L)
  expect_equal(res$city, "成都市")
  expect_equal(names(res), c(
    "lng", "lat", "formatted_address", "country", "province",
    "city", "district", "township", "street", "number",
    "citycode", "adcode"
  ))
  rl <- attr(res, "rate_limit")
  # expect_true(!is.null(rl))
  # expect_equal(unname(rl[["X-RateLimit-Remaining"]]), "9999")
})

test_that("getCoord mode = 'all' returns multi-match table", {
  vcr::use_cassette("geocode_multi", {
    res <- getCoord("朝阳区", mode = "all")
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  # "朝阳区" exists in Beijing and Changchun.
  expect_gt(nrow(res), 1L)
  expect_equal(res$match_rank[1:2], c(1L, 2L))
  expect_equal(res$query[1], "朝阳区")
})

test_that("getCoord batch aligns outputs with inputs", {
  vcr::use_cassette("geocode_batch", {
    res <- getCoord(c("天安门", "故宫"), batch = TRUE)
  }, match_requests_on = c("method", "uri"))

  expect_equal(nrow(res), 2L)
  expect_true(grepl("天安门", res$formatted_address[1]))
  expect_true(grepl("故宫", res$formatted_address[2]))
})

test_that("extractCoord parses multi-match payload", {
  raw <- vcr::use_cassette("geocode_multi_json", {
    getCoord("朝阳区", output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractCoord(raw)
  expect_gt(nrow(parsed), 1L)
  expect_equal(parsed$match_rank[1:2], c(1L, 2L))
})

test_that("rate limit errors raise structured amap_api_error", {
  skip("Requires mock")
  expect_error(
    vcr::use_cassette("geocode_rate_limit", {
      getCoord("RateLimited", keep_bad_request = FALSE)
    }, match_requests_on = c("method", "uri")),
    class = "amap_api_error"
  )
})

test_that("permission errors propagate infocode", {
  skip("Requires mock")
  err <- tryCatch({
    vcr::use_cassette("geocode_permission", {
      getCoord("NeedPermission", keep_bad_request = FALSE)
    }, match_requests_on = c("method", "uri"))
    NULL
  }, amap_api_error = function(e) e)

  expect_s3_class(err, "amap_api_error")
  expect_equal(err$infocode, "10034")
})
