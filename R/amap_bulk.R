# Bulk request helper that integrates cache + audit for prepared requests.

amap_perform_prepared <- function(prepared, max_active = 3) {
  if (!length(prepared)) {
    return(list())
  }

  start_time <- Sys.time()
  base_url <- amap_base_url()

  resolve_request <- function(prep) {
    key_hash <- amap_key_hash(prep$query$key %||% NA_character_)
    request_id <- amap_request_id(
      base_url = base_url,
      endpoint = prep$endpoint,
      query = prep$query,
      key_hash = key_hash,
      output = prep$output,
      callback = prep$callback
    )

    cached <- amap_cache_get(prep$endpoint, request_id)
    if (!is.null(cached)) {
      out <- structure(
        list(
          body = cached$body,
          response = NULL,
          query = prep$query
        ),
        class = "amap_response",
        rate_limit = cached$meta$rate_limit %||% NULL
      )
      attr(out, "request_id") <- request_id
      amap_audit_write(list(
        ts = format(as.POSIXct(Sys.time(), tz = "UTC"), tz = "UTC", usetz = TRUE),
        request_id = request_id,
        endpoint = prep$endpoint,
        cache_hit = TRUE,
        ok = TRUE,
        http_status = cached$meta$http_status %||% NA_integer_,
        infocode = cached$meta$infocode %||% NA_character_,
        duration_ms = 0,
        query = amap_sanitize_query_for_log(prep$query)
      ))
      return(list(hit = TRUE, value = out, request_id = request_id))
    }

    list(hit = FALSE, value = prep, request_id = request_id)
  }

  resolved <- lapply(prepared, resolve_request)
  hits <- vapply(resolved, function(x) isTRUE(x$hit), logical(1))

  outputs <- vector("list", length(prepared))
  for (i in which(hits)) {
    outputs[[i]] <- resolved[[i]]$value
  }

  if (all(hits)) {
    return(outputs)
  }

  miss_idx <- which(!hits)
  miss_prepared <- lapply(resolved[miss_idx], `[[`, "value")
  reqs <- lapply(miss_prepared, function(x) x$req)

  resps <- httr2::req_perform_parallel(
    reqs,
    on_error = "return",
    progress = FALSE,
    max_active = max_active
  )

  for (i in seq_along(resps)) {
    idx <- miss_idx[[i]]
    prep <- miss_prepared[[i]]
    request_id <- resolved[[idx]]$request_id
    t0 <- Sys.time()

    out <- tryCatch(
      {
        if (inherits(resps[[i]], "httr2_response")) {
          amap_process_response(
            resp = resps[[i]],
            endpoint = prep$endpoint,
            query = prep$query,
            output = prep$output,
            callback = prep$callback
          )
        } else {
          rlang::abort("Request failed", parent = resps[[i]])
        }
      },
      error = function(e) e
    )

    dt <- as.numeric(difftime(Sys.time(), t0, units = "secs")) * 1000

    if (inherits(out, "amap_response")) {
      attr(out, "request_id") <- request_id
      rate_limit <- attr(out, "rate_limit")
      meta <- list(
        http_status = tryCatch(httr2::resp_status(out$response), error = function(e) NA_integer_),
        infocode = out$body$infocode %||% out$body$infoCode %||% NA_character_,
        rate_limit = rate_limit %||% NULL
      )
      amap_cache_put(prep$endpoint, request_id, out$body, meta)
      amap_audit_write(list(
        ts = format(as.POSIXct(Sys.time(), tz = "UTC"), tz = "UTC", usetz = TRUE),
        request_id = request_id,
        endpoint = prep$endpoint,
        cache_hit = FALSE,
        ok = TRUE,
        http_status = meta$http_status,
        infocode = meta$infocode,
        duration_ms = dt,
        query = amap_sanitize_query_for_log(prep$query)
      ))
      outputs[[idx]] <- out
    } else {
      api <- NULL
      if (inherits(out, "amap_api_error")) {
        api <- out
      }
      amap_audit_write(list(
        ts = format(as.POSIXct(Sys.time(), tz = "UTC"), tz = "UTC", usetz = TRUE),
        request_id = request_id,
        endpoint = prep$endpoint,
        cache_hit = FALSE,
        ok = FALSE,
        http_status = if (!is.null(api)) api$http_status %||% NA_integer_ else NA_integer_,
        infocode = if (!is.null(api)) api$infocode %||% NA_character_ else NA_character_,
        duration_ms = dt,
        error = conditionMessage(out),
        query = amap_sanitize_query_for_log(prep$query)
      ))
      attr(out, "request_id") <- request_id
      outputs[[idx]] <- out
    }
  }

  outputs
}

