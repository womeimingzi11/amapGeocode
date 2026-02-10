# Reproducible medical accessibility case study script
#
# This script is intended for paper/benchmark runs (not for CRAN examples).
# It uses caching + audit logs and produces a small accessibility table.
#
# Usage (shell):
#   AMAP_KEY=... Rscript inst/scripts/medical_accessibility_case.R
#
# Optional:
#   http_proxy/https_proxy/all_proxy may need to be unset in some environments.

options(warn = 1)

if (!requireNamespace("amapGeocode", quietly = TRUE)) {
  stop("Please install or load amapGeocode first.")
}

key <- Sys.getenv("AMAP_KEY")
if (!nzchar(key)) {
  stop("Set AMAP_KEY in your environment before running this script.")
}
options(amap_key = key)

amapGeocode::amap_config(throttle = TRUE, max_active = 2)

cache_dir <- file.path(tempdir(), "amap_cache_case")
audit_dir <- file.path(tempdir(), "amap_audit_case")
amapGeocode::amap_cache_enable(cache_dir, ttl_days = 30)
amapGeocode::amap_audit_enable(audit_dir)

origins <- utils::read.csv(system.file("extdata", "origins_sample.csv", package = "amapGeocode"))
destinations <- utils::read.csv(system.file("extdata", "hospitals_sample.csv", package = "amapGeocode"))

od <- amapGeocode::getOdMatrix(origins = origins, destinations = destinations, mode = "driving")

# Simple cumulative opportunities metric: number of hospitals within 15 minutes.
threshold_min <- 15
od$within_threshold <- !is.na(od$duration_s) & (od$duration_s / 60 <= threshold_min)

accessibility <- aggregate(within_threshold ~ from_id, data = od, FUN = sum)
names(accessibility) <- c("origin_id", "hospitals_within_15min")

out_path <- file.path(getwd(), "medical_accessibility_out.csv")
utils::write.csv(accessibility, out_path, row.names = FALSE)

message("Wrote: ", out_path)

# Audit summary
report_path <- file.path(getwd(), "amap_audit_report.csv")
amapGeocode::amap_audit_report(report_path, format = "csv")
message("Wrote: ", report_path)

