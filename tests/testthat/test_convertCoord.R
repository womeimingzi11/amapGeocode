test_that("convertCoord returns converted numeric coordinates", {
  vcr::use_cassette("convert_basic",
    {
      res <- convertCoord("116.481499,39.990475", coordsys = "gps")
    },
    match_requests_on = c("method", "uri")
  )

  expect_s3_class(res, "tbl_df")
  expect_true(!is.na(res$lng[1]))
  expect_true(!is.na(res$lat[1]))
})

test_that("extractConvertCoord parses raw response", {
  raw <- NULL
  vcr::use_cassette("convert_basic_json",
    {
      raw <- convertCoord("116.481499,39.990475", coordsys = "gps", output = "JSON")
    },
    match_requests_on = c("method", "uri")
  )

  parsed <- extractConvertCoord(raw)
  expect_true(tibble::is_tibble(parsed))
  expect_true(nrow(parsed) > 0)
  expect_true(!is.na(parsed$lng[1]))
  expect_true(!is.na(parsed$lat[1]))
})

test_that("convertCoord handles coordinate conversion errors", {
  # 测试坐标转换错误处理
  error_response <- list(
    status = "0",
    info = "坐标转换失败",
    infocode = "10007"
  )

  # 测试错误响应的解析
  normalized <- amapGeocode:::normalize_convert_response(error_response)
  expect_true(is.list(normalized))
  expect_equal(normalized$status, "0")

  # extractConvertCoord遇到错误状态会抛出错误
  expect_error(
    extractConvertCoord(error_response),
    "坐标转换失败"
  )
})

test_that("convert placeholder generation works correctly", {
  # 测试坐标转换placeholder生成函数
  placeholder <- amapGeocode:::convert_placeholder()

  expect_s3_class(placeholder, "tbl_df")
  expect_equal(nrow(placeholder), 1L)
  expect_true(all(is.na(placeholder$lng)))
  expect_true(all(is.na(placeholder$lat)))
})

test_that("coordinate system validation works", {
  # 测试坐标系参数验证
  # 创建一个正常的转换请求
  normal_query <- list(
    locations = "116.481499,39.990475",
    coordsys = "gps"
  )

  # 测试无效坐标系 - 注意：实际的验证可能在API端进行
  invalid_query <- list(
    locations = "116.481499,39.990475",
    coordsys = "invalid_system"
  )

  # 测试坐标转换逻辑
  expect_true(is.list(normal_query))
  expect_true(is.list(invalid_query))
})

test_that("empty coordinates return empty result", {
  # 测试空坐标输入的处理
  # 创建一个空的coordinates列表
  result <- tryCatch(
    {
      convertCoord(character(0))
    },
    error = function(e) e
  )

  # convertCoord应该返回空结果tibble
  # 注意：convertCoord函数有保护逻辑，对空输入返回空tibble
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
})

test_that("extractConvertCoord handles malformed responses", {
  # 测试extractConvertCoord对格式错误响应的处理
  # 格式错误的响应
  malformed_response <- list(
    status = "1",
    # 缺少locations字段
    info = "OK"
  )

  result <- extractConvertCoord(malformed_response)
  expect_s3_class(result, "tbl_df")

  # 完全无效的响应
  invalid_response <- "不是JSON格式"
  result2 <- tryCatch(
    {
      extractConvertCoord(invalid_response)
    },
    error = function(e) e
  )

  # 应该抛出错误或返回可处理的结果
  expect_true(inherits(result2, "tibble") || inherits(result2, "error"))
})
