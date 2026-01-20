# Internal HTTP utilities for amapGeocode

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) {
    y
  } else {
    x
  }
}

scalar_or_na <- function(x) {
  if (is.null(x) || rlang::is_empty(x)) {
    return(NA_character_)
  }
  value <- x[[1L]]
  if (is.null(value) || (length(value) == 1L && is.na(value))) {
    return(NA_character_)
  }
  as.character(value)
}

amap_compact <- function(x) {
  if (!length(x)) {
    return(x)
  }
  keep <- !vapply(x, is.null, logical(1))
  x[keep]
}

amap_base_url <- function() {
  base <- getOption("amap_base_url", "https://restapi.amap.com")
  sub("/+$", "", base)
}

amap_get_key <- function(key = NULL) {
  if (!is.null(key)) {
    return(key)
  }
  option_key <- getOption("amap_key")
  if (is.null(option_key) || option_key == "") {
    rlang::abort(
      "Please supply an AutoNavi API key via the `key` argument or `options(amap_key=)`.",
      class = "amap_missing_key_error"
    )
  }
  option_key
}

amap_signature_settings <- function() {
  settings <- getOption("amap_signature")
  if (is.null(settings)) {
    return(list(enabled = FALSE, secret = NULL, key = NULL))
  }
  defaults <- list(enabled = TRUE, secret = NULL, key = NULL)
  utils::modifyList(defaults, settings)
}

amap_throttle_settings <- function() {
  settings <- getOption("amap_throttle")
  defaults <- list(
    enabled = TRUE,
    rate = 3,
    capacity = NULL,
    fill_time_s = 1,
    realm = NULL
  )
  if (is.null(settings)) {
    return(defaults)
  }
  resolved <- utils::modifyList(defaults, settings)
  if (is.null(resolved$rate) && is.null(resolved$capacity)) {
    resolved$rate <- 3
  }
  resolved
}

#' Configure Amap settings
#' @param signature Optional.
#' Signature configuration. Use `FALSE` to disable, a single string secret, or a list.
#' @param secret Optional.
#' Secret key used for request signing.
#' @param key Optional.
#' Optional API key override when signing is enabled.
#' @param enabled Optional.
#' Logical flag to enable or disable signing.
#' @param max_active Optional.
#' Maximum number of active concurrent HTTP requests when bulk operations are
#' executed with `httr2::req_perform_parallel()`. Defaults to 3.
#' @param throttle Optional.
#' Throttling configuration for outgoing HTTP requests.
#' Use `FALSE` to disable throttling, `TRUE` to enable with defaults, or a list
#' with any of the following fields:
#' `enabled` (logical), `rate` (numeric), `capacity` (numeric),
#' `fill_time_s` (numeric), and `realm` (character).
#'
#' Defaults are safe for AutoNavi's QPS limits: `max_active = 3` and
#' `throttle = list(rate = 3, fill_time_s = 1)`.
#' @export
amap_config <- function(signature = NULL,
                        secret = NULL,
                        key = NULL,
                        enabled = TRUE,
                        max_active = NULL,
                        throttle = NULL) {
  if (!is.null(signature)) {
    if (isFALSE(signature)) {
      options(amap_signature = NULL)
      return(invisible(NULL))
    }
    if (is.character(signature) && length(signature) == 1L) {
      options(amap_signature = list(secret = signature, key = key, enabled = enabled))
      return(invisible(NULL))
    }
    if (is.list(signature)) {
      current <- amap_signature_settings()
      updated <- utils::modifyList(current, signature)
      options(amap_signature = updated)
      return(invisible(NULL))
    }
    rlang::abort("`signature` must be FALSE, a single string, or a list when supplied.")
  }
  if (!is.null(secret)) {
    options(amap_signature = list(secret = secret, key = key, enabled = enabled))
  }

  if (!is.null(max_active)) {
    if (!is.numeric(max_active) || length(max_active) != 1L || is.na(max_active) || max_active < 1) {
      rlang::abort("`max_active` must be a single positive number when supplied.")
    }
    options(amap_max_active = as.integer(max_active))
  }

  if (!is.null(throttle)) {
    if (isFALSE(throttle)) {
      options(amap_throttle = list(enabled = FALSE))
    } else if (isTRUE(throttle)) {
      options(amap_throttle = list(enabled = TRUE))
    } else if (is.list(throttle)) {
      current <- amap_throttle_settings()
      updated <- utils::modifyList(current, throttle)
      options(amap_throttle = updated)
    } else {
      rlang::abort("`throttle` must be FALSE, TRUE, or a list when supplied.")
    }
  }

  invisible(NULL)
}

#' Execute code with temporary signature settings
#' @param secret Required.
#' Secret key used for request signing.
#' @param expr Required.
#' Expression to evaluate with signing enabled.
#' @param key Optional.
#' Optional API key override when signing is enabled.
#' @param enabled Optional.
#' Logical flag to enable or disable signing.
#' @export
with_amap_signature <- function(secret, expr, key = NULL, enabled = TRUE) {
  old <- getOption("amap_signature")
  on.exit(options(amap_signature = old), add = TRUE)
  options(amap_signature = list(secret = secret, key = key, enabled = enabled))
  force(expr)
}

#' Generate Amap signature
#' @param params Required.
#' Named list of request parameters to sign.
#' @param secret Required.
#' Secret key used for request signing.
#' @param path Required.
#' Request path portion of the API URL.
#' @export
amap_sign <- function(params, secret, path) {
  if (is.null(secret) || !nzchar(secret)) {
    rlang::abort("`secret` must be a non-empty string when creating an AutoNavi signature.")
  }
  params <- amap_compact(params)
  params$sig <- NULL
  if (!length(params)) {
    rlang::abort("`params` must contain at least one key/value pair for signature generation.")
  }
  names_sorted <- sort(names(params))
  encode_value <- function(value) {
    if (length(value) == 0 || (length(value) == 1 && is.na(value))) {
      value <- ""
    }
    if (is.logical(value)) {
      value <- tolower(as.character(value))
    }
    if (length(value) > 1) {
      value <- paste(value, collapse = ",")
    }
    utils::URLencode(as.character(value), reserved = TRUE)
  }
  query <- paste0(
    names_sorted,
    "=",
    vapply(params[names_sorted], encode_value, character(1L)),
    collapse = "&"
  )
  clean_path <- paste0("/", sub("^/+", "", path))
  digest::digest(paste0(clean_path, "?", query, secret), algo = "md5", serialize = FALSE)
}

amap_api_error <- function(message,
                           status = NULL,
                           info = NULL,
                           infocode = NULL,
                           http_status = NULL,
                           request = NULL,
                           headers = NULL,
                           body = NULL) {
  structure(
    list(
      message = message,
      status = status,
      info = info,
      infocode = infocode,
      http_status = http_status,
      request = request,
      headers = headers,
      body = body
    ),
    class = "amap_api_error"
  )
}

abort_amap <- function(message, ...) {
  err <- amap_api_error(message, ...)
  rlang::abort(
    message = err$message,
    class = c("amap_api_error", "rlang_error"),
    status = err$status,
    info = err$info,
    infocode = err$infocode,
    http_status = err$http_status,
    request = err$request,
    headers = err$headers,
    response_body = err$body
  )
}

amap_rate_limit <- function(resp) {
  headers <- httr2::resp_headers(resp)
  if (!length(headers)) {
    return(NULL)
  }
  keep <- grepl("ratelimit", names(headers), ignore.case = TRUE)
  if (!any(keep)) {
    return(NULL)
  }
  structure(headers[keep], class = "amap_rate_limit")
}

amap_parse_body <- function(body_raw, output = NULL, callback = NULL) {
  if (!is.null(callback)) {
    return(rawToChar(body_raw))
  }
  if (is.null(output) || identical(tolower(output), "json")) {
    if (!length(body_raw)) {
      return(list())
    }
    jsonlite::fromJSON(rawToChar(body_raw), simplifyVector = FALSE)
  } else if (identical(tolower(output), "xml")) {
    xml2::read_xml(body_raw)
  } else {
    rawToChar(body_raw)
  }
}

amap_check_status <- function(parsed, resp, endpoint, query) {
  if (!is.list(parsed)) {
    return(parsed)
  }
  status <- parsed$status %||% parsed$Status %||% parsed$code
  status_num <- suppressWarnings(as.numeric(status))
  if (!is.na(status_num) && identical(status_num, 1)) {
    return(parsed)
  }
  if (!is.null(status) && identical(as.character(status), "1")) {
    return(parsed)
  }
  message <- parsed$info %||% parsed$message %||% "AutoNavi API request failed"
  abort_amap(
    message = message,
    status = status,
    info = parsed$info %||% parsed$message,
    infocode = parsed$infocode %||% parsed$infoCode,
    http_status = httr2::resp_status(resp),
    request = list(
      method = resp$request$method,
      url = httr2::resp_url(resp),
      endpoint = endpoint,
      query = query
    ),
    headers = httr2::resp_headers(resp),
    body = parsed
  )
}

amap_prepare_request <- function(endpoint,
                                 query = list(),
                                 key = NULL,
                                 method = "GET",
                                 body = NULL,
                                 output = NULL,
                                 callback = NULL) {
  key <- amap_get_key(key)
  query <- amap_compact(query)
  query$key <- key
  if (!is.null(output) && !identical(output, "tibble")) {
    query$output <- output
  }
  if (!is.null(callback)) {
    query$callback <- callback
  }

  settings <- amap_signature_settings()
  if (isTRUE(settings$enabled) && is.null(query$sig) && !is.null(settings$secret)) {
    candidate <- utils::modifyList(query, list(key = settings$key %||% key))
    query$sig <- amap_sign(candidate, settings$secret, file.path("v3", endpoint))
  }

  req <- httr2::request(amap_base_url())
  req <- httr2::req_url_path_append(req, "v3")
  req <- httr2::req_url_path_append(req, endpoint)
  req <- httr2::req_method(req, method)
  if (!is.null(body)) {
    req <- httr2::req_body_raw(req, body)
  }
  req <- httr2::req_url_query(req, !!!query)
  req <- httr2::req_user_agent(
    req,
    getOption(
      "amap_user_agent",
      sprintf(
        "amapGeocode/%s (https://github.com/womeimingzi11/amapGeocode)",
        tryCatch(as.character(utils::packageVersion("amapGeocode")), error = function(e) "dev")
      )
    )
  )
  req <- httr2::req_retry(
    req,
    max_tries = getOption("amap_retry_max_tries", 3),
    max_seconds = getOption("amap_retry_max_seconds", 30)
  )

  throttle_settings <- amap_throttle_settings()
  if (isTRUE(throttle_settings$enabled)) {
    if (!is.null(throttle_settings$rate)) {
      req <- httr2::req_throttle(
        req,
        rate = throttle_settings$rate,
        fill_time_s = throttle_settings$fill_time_s,
        realm = throttle_settings$realm
      )
    } else {
      req <- httr2::req_throttle(
        req,
        capacity = throttle_settings$capacity,
        fill_time_s = throttle_settings$fill_time_s,
        realm = throttle_settings$realm
      )
    }
  }

  structure(
    list(
      req = req,
      endpoint = endpoint,
      query = query,
      output = output,
      callback = callback
    ),
    class = "amap_prepared_request"
  )
}

amap_process_response <- function(resp,
                                  endpoint,
                                  query,
                                  output = NULL,
                                  callback = NULL) {
  rate_limit <- amap_rate_limit(resp)
  status_code <- httr2::resp_status(resp)
  body_raw <- httr2::resp_body_raw(resp)
  if (status_code >= 400) {
    parsed_err <- tryCatch(
      jsonlite::fromJSON(rawToChar(body_raw), simplifyVector = FALSE),
      error = function(e) NULL
    )
    abort_amap(
      message = parsed_err$info %||% parsed_err$message %||% httr2::resp_status_desc(resp),
      status = parsed_err$status,
      info = parsed_err$info,
      infocode = parsed_err$infocode,
      http_status = status_code,
      request = list(
        method = resp$request$method,
        url = httr2::resp_url(resp),
        endpoint = endpoint,
        query = query
      ),
      headers = httr2::resp_headers(resp),
      body = parsed_err %||% rawToChar(body_raw)
    )
  }
  parsed <- amap_parse_body(body_raw, output = output, callback = callback)
  parsed <- amap_check_status(parsed, resp, endpoint, query)
  structure(
    list(
      body = parsed,
      response = resp,
      query = query
    ),
    class = "amap_response",
    rate_limit = rate_limit
  )
}

amap_request <- function(endpoint,
                         query = list(),
                         key = NULL,
                         method = "GET",
                         body = NULL,
                         output = NULL,
                         callback = NULL) {
  prepared <- amap_prepare_request(
    endpoint = endpoint,
    query = query,
    key = key,
    method = method,
    body = body,
    output = output,
    callback = callback
  )
  resp <- httr2::req_perform(prepared$req)
  amap_process_response(
    resp = resp,
    endpoint = prepared$endpoint,
    query = prepared$query,
    output = prepared$output,
    callback = prepared$callback
  )
}
