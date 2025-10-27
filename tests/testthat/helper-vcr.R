if (requireNamespace("httptest2", quietly = TRUE)) {
  httptest2::start_vcr(path = "fixtures/vcr_cassettes")
} else if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(dir = "fixtures/vcr_cassettes")
}

options(amap_key = "FAKE_KEY")
