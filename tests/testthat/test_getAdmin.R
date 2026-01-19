test_that("getAdmin flattens multiple parent districts", {
  vcr::use_cassette("admin_multi", {
    res <- getAdmin("四川省", subdistrict = 1)
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "tbl_df")
  expect_gt(nrow(res), 1L)
  expect_true(all(c("parent_name", "parent_adcode", "depth") %in% names(res)))
  expect_equal(unique(res$parent_name), "四川省")
  expect_true(all(res$depth >= 1L))
})

test_that("getAdmin can include polylines", {
  vcr::use_cassette("admin_polyline", {
    res <- getAdmin("四川省", subdistrict = 0,
                    extensions = "all", include_polyline = TRUE)
  }, match_requests_on = c("method", "uri"))

  expect_true("polyline" %in% names(res))
  expect_true(nzchar(res$polyline[[1]]))
})

test_that("extractAdmin handles raw response", {
  raw <- NULL
  vcr::use_cassette("admin_multi_json", {
    raw <- getAdmin("四川省", subdistrict = 1, output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractAdmin(raw)
  expect_true(tibble::is_tibble(parsed))
  expect_gt(nrow(parsed), 1L)
  # At least one child should exist for the province
  expect_true(any(parsed$parent_name == "四川省"))
})
