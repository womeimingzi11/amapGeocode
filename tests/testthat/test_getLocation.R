# Test whether getCoord can retrun right class
test_that('Reuturn detailed tibble with correct coordinate', {
  skip_if(is.null(getOption('amap_key')))
  res <- getLocation(104, 30)
  f_a_class <-
    class(res$formatted_address)
  f_a_is_na <-
    any(is.na(res$formatted_address))
  expect_equal(f_a_class, 'character')
  expect_equal(f_a_is_na, FALSE)
})

# Test whether getCoord can retrun right class withou to_tibble
test_that('Reuturn raw respone with correct coordinate', {
  skip_if(is.null(getOption('amap_key')))
  res <- getLocation(104, 30, to_table = F)
  res_class <-
    class(res)

  expect_equal(any(stringr::str_detect(res_class, 'list')), TRUE)
})

# Test whether getCoord can retrun right class with wrong location
test_that('Reuturn na tibble with correct coordinate', {
  skip_if(is.null(getOption('amap_key')))
  res <- getLocation(104, 300)
  res_class <-
    class(res)
  expect_equal(any(stringr::str_detect(res_class, 'tbl_df')),  TRUE)
  expect_equal(all(is.na(res)), TRUE)
})

test_that('Test parallel request', {
  skip_if(is.null(getOption('amap_key')))
  lng_ls <- rep_len(x = 104, length.out = 100)
  lat_ls <- rep_len(x = 30, length.out = 100)
  res <- getLocation(lng = lng_ls, lat = lat_ls, max_core = 12)
  unique_res <-
    unique(res)
  expect_equal(unique_res$province,  '四川省')
})
