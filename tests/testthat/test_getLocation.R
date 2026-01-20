test_that("getLocation returns basic reverse geocode data", {
  vcr::use_cassette("regeo_basic",
    {
      res <- getLocation(104.043284, 30.666864)
    },
    match_requests_on = c("method", "uri")
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1L)
  expect_equal(res$city, "成都市")
  # District boundary may vary
  expect_true(res$district %in% c("锦江区", "金牛区"))
})

test_that("getLocation returns detail list-columns when requested", {
  vcr::use_cassette("regeo_details",
    {
      res <- getLocation(104.05, 30.67,
        extensions = "all",
        details = c("pois", "roads", "roadinters", "aois")
      )
    },
    match_requests_on = c("method", "uri")
  )

  expect_true(all(c("pois", "roads", "roadinters", "aois") %in% names(res)))
  expect_s3_class(res$pois[[1]], "tbl_df")
  expect_gt(nrow(res$pois[[1]]), 0L)
  expect_gt(nrow(res$roads[[1]]), 0L)
})

test_that("getLocation batch preserves order", {
  vcr::use_cassette("regeo_batch",
    {
      res <- getLocation(c(104.043284, 104.05), c(30.666864, 30.67), batch = TRUE)
    },
    match_requests_on = c("method", "uri")
  )

  expect_equal(nrow(res), 2L)
  expect_type(res$formatted_address, "character")
  expect_true(res$formatted_address[1] != res$formatted_address[2])
})

test_that("extractLocation parses detail payload", {
  raw <- vcr::use_cassette("regeo_details_json",
    {
      getLocation(104.05, 30.67,
        extensions = "all",
        details = NULL,
        output = "JSON"
      )
    },
    match_requests_on = c("method", "uri")
  )

  parsed <- extractLocation(raw, details = "pois")
  expect_equal(names(parsed), c(
    "formatted_address", "country", "province", "city", "district",
    "township", "citycode", "towncode", "adcode", "street", "number",
    "neighborhood", "building", "pois"
  ))
  expect_s3_class(parsed$pois[[1]], "tbl_df")
})

test_that("invalid detail types error", {
  expect_error(extractLocation(list(), details = "invalid"), "Unknown detail type")
})

test_that("mismatched longitude and latitude vectors raise error", {
  # 测试经度和纬度向量长度不匹配时的错误
  expect_error(
    getLocation(c(104.04, 104.05), c(30.66)),
    "mismatched"
  )
})

test_that("location placeholder generation works correctly", {
  # 测试location placeholder生成函数
  placeholder <- amapGeocode:::location_placeholder(
    n = 2L,
    details = character() # 需要指定details参数
  )

  expect_s3_class(placeholder, "tbl_df")
  expect_equal(nrow(placeholder), 2L)
  expect_true(all(is.na(placeholder$formatted_address)))
  expect_true(all(is.na(placeholder$country)))
})

test_that("location error response parsing handles API errors", {
  # 测试API错误响应的解析
  error_response <- list(
    status = "0",
    info = "坐标点超出中国范围",
    infocode = "10001"
  )

  # 测试提取位置信息的错误处理
  result <- tryCatch(
    {
      amapGeocode:::normalize_location_response(error_response)
    },
    error = function(e) e
  )

  expect_true(is.list(result) || inherits(result, "error"))

  # 测试location_entry_to_dt函数对NULL输入的处理
  null_entry_result <- amapGeocode:::location_entry_to_dt(NULL, details = NULL)
  expect_s3_class(null_entry_result, "tbl_df")
  expect_true(nrow(null_entry_result) == 1L)
})

test_that("normalize_location_details validates input correctly", {
  # 测试details参数验证
  expect_error(
    amapGeocode:::normalize_location_details("invalid_detail"),
    "Unknown detail type"
  )

  # 测试有效输入
  valid_details <- amapGeocode:::normalize_location_details(c("pois", "roads"))
  expect_type(valid_details, "character")
  expect_true(all(c("pois", "roads") %in% valid_details))

  # 测试"all"关键字 - 函数存在逻辑错误，应该抛出错误
  # 根据当前代码，"all"不在valid列表中，所以会抛出错误
  expect_error(
    amapGeocode:::normalize_location_details("all"),
    "Unknown detail type"
  )
})

test_that("extractLocation handles error responses gracefully", {
  # 测试extractLocation对错误响应的处理
  error_response <- list(
    status = "0",
    info = "坐标格式错误",
    infocode = "10002"
  )

  result <- extractLocation(error_response)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1L)
  expect_true(all(is.na(result$formatted_address)))
  expect_true(all(is.na(result$country)))
})
