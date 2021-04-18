# Test whether getCoord can retrun right class
test_that("Reuturn detailed tibble with correct location", {
  skip_if(is.null(getOption("amap_key")))
  res <- getCoord("成都中医药大学")
  lng_class <-
    class(res$lng)
  lng_is_na <-
    any(is.na(res$lng))
  expect_equal(lng_class, "numeric")
  expect_equal(lng_is_na, FALSE)
})

# Test whether getCoord can retrun right class withou to_tibble
test_that("Reuturn raw respone with correct location", {
  skip_if(is.null(getOption("amap_key")))
  res <- getCoord("成都中医药大学", output = "JSON")
  res_class <-
    class(res)

  expect_equal(any(stringr::str_detect(res_class, "list")), TRUE)
})

# Test whether getCoord can retrun right class with wrong location
test_that("Reuturn NA tibble with wrong location", {
  skip_if(is.null(getOption("amap_key")))
  res <- getCoord("place unkown")
  res_class <-
    class(res)
  expect_equal(any(stringr::str_detect(res_class, "data.frame")), TRUE)
  expect_equal(all(is.na(res)), TRUE)
})

# Test parallel request
test_that("Test parallel request", {
  skip_if(is.null(getOption("amap_key")))
  add_ls <- rep_len(x = "成都中医药大学", length.out = 10)
  res <- getCoord(add_ls, max_core = 4)
  unique_res <-
    unique(res)
  expect_equal(unique_res$province, "四川省")
})
