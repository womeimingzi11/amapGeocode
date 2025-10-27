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
