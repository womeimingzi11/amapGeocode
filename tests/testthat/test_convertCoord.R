# Test whether convertCoord can retrun right class
test_that("Reuturn detailed tibble with correct location", {
  skip_if(is.null(getOption("amap_key")))
  res <- convertCoord(c("116.481499,39.990475", "116.481499,49.990475"))
  lng_class <-
    class(res$lng)
  lng_is_na <-
    any(is.na(res$lng))
  expect_equal(lng_class, "numeric")
  expect_equal(lng_is_na, FALSE)
})

# Test whether getAdmin can retrun right class
test_that("Reuturn raw respone with correct location", {
  skip_if(is.null(getOption("amap_key")))
  res <- convertCoord("116.481499,39.990475", output = "JSON")
  res_class <-
    class(res)

  expect_equal(any(stringr::str_detect(res_class, "list")), TRUE)
})
