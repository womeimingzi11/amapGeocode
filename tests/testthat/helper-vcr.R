key <- Sys.getenv("AMAP_KEY")
if (key == "") {
  key <- "FAKE_KEY"
}

options(amap_key = key)

if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(
    dir = "fixtures/vcr_cassettes",
    filter_sensitive_data = list("FAKE_KEY" = key)
  )
}
