# Audit logging utilities for amapGeocode

amap_audit_settings <- function() {
  settings <- getOption("amap_audit")
  defaults <- list(enabled = FALSE, path = NULL)
  if (is.null(settings)) {
    return(defaults)
  }
  utils::modifyList(defaults, settings)
}

amap_audit_enabled <- function() {
  settings <- amap_audit_settings()
  isTRUE(settings$enabled) && !is.null(settings$path) && nzchar(settings$path)
}

amap_audit_path <- function() {
  settings <- amap_audit_settings()
  settings$path
}

amap_sanitize_query_for_log <- function(query) {
  if (is.null(query) || !length(query)) {
    return(list())
  }
  query <- query
  if (!is.null(query$key)) {
    query$key <- "<redacted>"
  }
  if (!is.null(query$sig)) {
    query$sig <- "<redacted>"
  }
  query
}

amap_audit_write <- function(event) {
  if (!amap_audit_enabled()) {
    return(invisible(FALSE))
  }
  path <- amap_audit_path()
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  json <- jsonlite::toJSON(event, auto_unbox = TRUE, null = "null")
  cat(json, file = path, sep = "\n", append = TRUE)
  invisible(TRUE)
}

#' Enable audit logging for amapGeocode
#'
#' @param path Required.
#' Directory where `amap_audit.jsonl` will be written.
#' @export
amap_audit_enable <- function(path) {
  if (missing(path) || is.null(path) || !nzchar(path)) {
    rlang::abort("`path` must be a non-empty string.", call = NULL)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  options(amap_audit = list(
    enabled = TRUE,
    path = file.path(path, "amap_audit.jsonl")
  ))
  invisible(NULL)
}

#' Disable audit logging for amapGeocode
#' @export
amap_audit_disable <- function() {
  options(amap_audit = list(enabled = FALSE))
  invisible(NULL)
}

#' Summarise audit logs produced by amapGeocode
#'
#' @param path_out Required.
#' Output file path for the report.
#' @param format Optional.
#' Report format. Supports `"csv"` (default) and `"json"`.
#' @export
amap_audit_report <- function(path_out, format = c("csv", "json")) {
  format <- match.arg(format)
  settings <- amap_audit_settings()
  if (is.null(settings$path) || !file.exists(settings$path)) {
    rlang::abort("No audit log is available. Enable logging with `amap_audit_enable()` first.", call = NULL)
  }
  lines <- readLines(settings$path, warn = FALSE)
  if (!length(lines)) {
    rlang::abort("Audit log is empty.", call = NULL)
  }
  events <- lapply(lines, function(x) jsonlite::fromJSON(x, simplifyVector = FALSE))
  to_row <- function(ev) {
    tibble::tibble(
      ts = ev$ts %||% NA_character_,
      endpoint = ev$endpoint %||% NA_character_,
      cache_hit = isTRUE(ev$cache_hit),
      ok = isTRUE(ev$ok),
      http_status = ev$http_status %||% NA_integer_,
      infocode = ev$infocode %||% NA_character_,
      duration_ms = ev$duration_ms %||% NA_real_
    )
  }
  tbl <- dplyr::bind_rows(lapply(events, to_row))
  summary <- tbl |>
    dplyr::group_by(.data$endpoint) |>
    dplyr::summarise(
      n = dplyr::n(),
      ok = sum(.data$ok, na.rm = TRUE),
      cache_hit = sum(.data$cache_hit, na.rm = TRUE),
      cache_hit_rate = ifelse(n > 0, cache_hit / n, NA_real_),
      duration_ms_mean = mean(.data$duration_ms, na.rm = TRUE),
      .groups = "drop"
    )

  if (identical(format, "csv")) {
    utils::write.csv(summary, file = path_out, row.names = FALSE)
  } else {
    json <- jsonlite::toJSON(summary, auto_unbox = TRUE, pretty = TRUE)
    cat(json, file = path_out)
  }
  invisible(summary)
}
