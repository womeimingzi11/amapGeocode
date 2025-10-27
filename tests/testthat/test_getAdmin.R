test_that("getAdmin flattens multiple parent districts", {
  vcr::use_cassette("admin_multi", {
    res <- getAdmin("Sichuan", subdistrict = 1)
  }, match_requests_on = c("method", "uri"))

  expect_s3_class(res, "data.table")
  expect_equal(nrow(res), 3L)
  expect_true(all(c("parent_name", "parent_adcode", "depth") %in% names(res)))
  expect_equal(unique(res$parent_name), c("Sichuan Province", "Sichuan Alt"))
  expect_true(all(res$depth >= 1L))
})

test_that("getAdmin can include polylines", {
  vcr::use_cassette("admin_polyline", {
    res <- getAdmin("Sichuan", subdistrict = 0,
                    extensions = "all", include_polyline = TRUE)
  }, match_requests_on = c("method", "uri"))

  expect_true("polyline" %in% names(res))
  expect_equal(res$polyline[[1]], "104.065735,30.659462;104.066000,30.660000")
})

test_that("extractAdmin handles raw response", {
  raw <- vcr::use_cassette("admin_multi", {
    getAdmin("Sichuan", subdistrict = 1, output = "JSON")
  }, match_requests_on = c("method", "uri"))

  parsed <- extractAdmin(raw)
  expect_equal(nrow(parsed), 3L)
  expect_equal(parsed$name[parsed$parent_name == "Sichuan Province"],
               c("Chengdu City", "Mianyang City"))
})
