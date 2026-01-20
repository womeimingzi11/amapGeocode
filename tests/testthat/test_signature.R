test_that("amap_sign generates canonical md5 signature", {
  params <- list(address = "Chengdu", key = "FAKE_KEY")
  sig <- amap_sign(params, secret = "secret", path = "v3/geocode/geo")
  expect_equal(sig, "30c9d0ed28b0106eee98b5410b37db08")
})

test_that("with_amap_signature temporarily sets signature config", {
  old <- getOption("amap_signature")
  res <- with_amap_signature("shh", {
    cfg <- amapGeocode:::amap_signature_settings()
    cfg
  })
  expect_true(is.list(res))
  expect_true(isTRUE(res$enabled))
  expect_equal(res$secret, "shh")
  expect_identical(getOption("amap_signature"), old)
})

test_that("amap_config updates global signature settings", {
  old <- getOption("amap_signature")
  on.exit(options(amap_signature = old), add = TRUE)

  amap_config(secret = "globalsecret")
  cfg <- amapGeocode:::amap_signature_settings()
  expect_equal(cfg$secret, "globalsecret")

  amap_config(signature = FALSE)
  expect_null(getOption("amap_signature"))
})

test_that("amap_sign validates empty secret", {
  # 测试空密钥验证
  expect_error(
    amap_sign(list(key = "test"), secret = "", path = "v3/test"),
    "non-empty string"
  )
})

test_that("amap_sign validates empty parameters", {
  # 测试空参数验证
  expect_error(
    amap_sign(list(), secret = "secret", path = "v3/test"),
    "at least one key/value pair"
  )
})

test_that("amap_config validates invalid inputs", {
  # 测试amap_config对无效输入的验证
  old_max_active <- getOption("amap_max_active")
  old_throttle <- getOption("amap_throttle")
  on.exit({
    options(amap_max_active = old_max_active)
    options(amap_throttle = old_throttle)
  })

  # 测试无效的max_active
  expect_error(
    amap_config(max_active = 0),
    "positive number"
  )

  expect_error(
    amap_config(max_active = c(1, 2)),
    "single positive number"
  )

  # 测试无效的signature参数
  expect_error(
    amap_config(signature = 123),
    "must be FALSE, a single string, or a list"
  )

  # 测试无效的throttle参数
  expect_error(
    amap_config(throttle = 123),
    "must be FALSE, TRUE, or a list"
  )
})

test_that("throttle settings handle edge cases", {
  # 测试节流设置处理边界情况
  old_settings <- getOption("amap_throttle")
  on.exit(options(amap_throttle = old_settings))

  # 清除节流设置
  options(amap_throttle = NULL)
  default_settings <- amapGeocode:::amap_throttle_settings()
  expect_true(is.list(default_settings))
  expect_true(default_settings$enabled)
  expect_equal(default_settings$rate, 3)

  # 测试部分覆盖的设置
  partial_settings <- list(enabled = FALSE)
  options(amap_throttle = partial_settings)
  resolved <- amapGeocode:::amap_throttle_settings()
  expect_false(resolved$enabled)

  # 测试无效设置的回退
  options(amap_throttle = list(rate = NULL, capacity = NULL))
  resolved2 <- amapGeocode:::amap_throttle_settings()
  expect_equal(resolved2$rate, 3)
})

test_that("signature settings handle edge cases", {
  # 测试签名设置处理边界情况
  old_settings <- getOption("amap_signature")
  on.exit(options(amap_signature = old_settings))

  # 清除签名设置
  options(amap_signature = NULL)
  default_settings <- amapGeocode:::amap_signature_settings()
  expect_true(is.list(default_settings))
  expect_false(default_settings$enabled)
  expect_null(default_settings$secret)

  # 测试部分覆盖
  options(amap_signature = list(secret = "test"))
  resolved <- amapGeocode:::amap_signature_settings()
  expect_true(resolved$enabled)
  expect_equal(resolved$secret, "test")
})

test_that("HTTP utilities handle edge cases", {
  # 测试HTTP工具函数处理边界情况
  # 测试amap_compact
  expect_equal(amapGeocode:::amap_compact(list()), list())
  expect_equal(
    amapGeocode:::amap_compact(list(a = 1, b = NULL, c = 2)),
    list(a = 1, c = 2)
  )

  # 测试scalar_or_na
  expect_equal(amapGeocode:::scalar_or_na(NULL), NA_character_)
  expect_equal(amapGeocode:::scalar_or_na(list()), NA_character_)
  expect_equal(amapGeocode:::scalar_or_na(list(NA)), NA_character_)
  expect_equal(amapGeocode:::scalar_or_na(list("test")), "test")

  # 测试amap_base_url
  old_base <- getOption("amap_base_url")
  on.exit(options(amap_base_url = old_base))

  options(amap_base_url = NULL)
  expect_match(amapGeocode:::amap_base_url(), "^https://")

  options(amap_base_url = "https://test.com/")
  expect_equal(amapGeocode:::amap_base_url(), "https://test.com")
})
