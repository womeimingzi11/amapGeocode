test_that("resolveGeocode prefers admin constraints and yields confidence diagnostics", {
  candidates <- tibble::tibble(
    query = c("朝阳区", "朝阳区"),
    query_index = c(1L, 1L),
    match_rank = c(1L, 2L),
    lng = c(116.5, 125.3),
    lat = c(39.9, 43.9),
    formatted_address = c("北京市朝阳区", "吉林省长春市朝阳区"),
    province = c("北京市", "吉林省"),
    city = c("北京市", "长春市"),
    district = c("朝阳区", "朝阳区"),
    adcode = c("110105", "220104")
  )

  resolved <- resolveGeocode(
    candidates,
    admin = list(province = "北京市", city = "北京市")
  )

  expect_true(is.list(resolved))
  expect_true(all(c("best", "candidates", "diagnostics") %in% names(resolved)))
  expect_equal(nrow(resolved$best), 1L)
  expect_equal(resolved$best$province, "北京市")
  expect_true(is.numeric(resolved$best$confidence))
  expect_true(is.logical(resolved$best$needs_review))
  expect_equal(resolved$diagnostics$query, "朝阳区")
})

