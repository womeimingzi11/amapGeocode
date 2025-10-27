# Internal HTTP utilities for amapGeocode

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) {
    y
  } else {
    x
  }
}

scalar_or_na <- function(x) {
  if (is.null(x) || sjmisc::is_empty(x)) {
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
  sub("/+\$", "", base)
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

amap_config <- function(signature = NULL, secret = NULL, key = NULL, enabled = TRUE) {
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
  invisible(NULL)
}

with_amap_signature <- function(secret, expr, key = NULL, enabled = TRUE) {
  old <- getOption("amap_signature")
  on.exit(options(amap_signature = old), add = TRUE)
  options(amap_signature = list(secret = secret, key = key, enabled = enabled))
  force(expr)
}

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
    body = err$body
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

amap_request <- function(endpoint,
                         query = list(),
                         key = NULL,
                         method = "GET",
                         body = NULL,
                         output = NULL,
                         callback = NULL) {
  key <- amap_get_key(key)
  query <- amap_compact(query)
  query$key <- key
  if (!is.null(output) && !identical(output, "data.table")) {
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
      sprintf("amapGeocode/%s (https://github.com/womeimingzi11/amapGeocode)",
              as.character(utils::packageVersion("amapGeocode")))
    )
  )
  req <- httr2::req_retry(
    req,
    max_tries = getOption("amap_retry_max_tries", 3),
    max_seconds = getOption("amap_retry_max_seconds", 30),
    backoff = httr2::req_retry_exponential(),
    is_transient = httr2::req_retry_statuses()
  )
  resp <- httr2::req_perform(req)
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
