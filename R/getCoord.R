#' Get coordinate from location
#'
#' @param address Required.\cr
#' Structured address information. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from 'AutoNavi' Map API official website\url{https://lbs.amap.com/dev/}
#' @param city Optional.\cr
#' Specify the City. \cr
#' Support: city in Chinese, full pinyin, citycode, adcode\url{https://lbs.amap.com/api/webservice/download}.\cr
#' The default value is NULL which will search country-wide. The default value is NULL
#' @param sig Optional.\cr
#' Digital Signature.\cr
#' How to use this argument? Please check here{https://lbs.amap.com/faq/account/key/72}
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON and XML. The default value is JSON.
#' @param callback Optional.\cr
#' Callback Function. \cr
#' The value of callback is the customized function. Only available with JSON output.
#' If you don't understand, it means you don't need it, just like me.
#' @param to_table Optional.\cr
#' Transform response content to tibble.\cr#'
#' @return
#' Returns a JSON, XML or Tibble of results containing detailed geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.
#' @export
#'
#' @examples
#' \dontrun{
#' library(amapGeocode)
#'
#' # Before the `getCoord()` is executed,
#' # the token should be set by `option(amap_key = 'key')`
#' # or set by key argument in `getCoord()`
#'
#' # Get geocode as a tibble
#' getCoord('IFS Chengdu')
#' # Get geocode as a XML
#' getCoord('IFS Chengdu', output = 'XML')
#'
#' }
#'
#' @seealso \code{\link{extractCoord}}

getCoord <-
  # A wrap of getCoord.individual
  function(address,
           key = NULL,
           city = NULL,
           sig = NULL,
           output = NULL,
           callback = NULL,
           to_table = TRUE) {
    if (length(address) == 1) {
      # if there is one address, use getCoord.individual directly
      getCoord.individual(
        key = key,
        address = address,
        city = city,
        sig = sig,
        output = output,
        callback = callback,
        to_table = to_table
      )
    } else {
      # if there is multiple addresses, use getCoord.individual by laapply
      ls_queries <-
        purrr::map(
        address,
        getCoord.individual,
        key = key,
        city = city,
        sig = sig,
        output = output,
        callback = callback,
        to_table = to_table
      )
      # detect return list of raw requests or `bind_rows` parsed tibble
      if (isTRUE(to_table)) {
        ls_queries %>%
          dplyr::bind_rows() %>%
          return()
      } else {
        return(ls_queries)
      }
    }
  }

#' Get an individual coordinate from location
#'
#' @param address Required.\cr
#' Structured address information. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from 'AutoNavi' Map API official website\url{https://lbs.amap.com/dev/}
#' @param city Optional.\cr
#' Specify the City. \cr
#' Support: city in Chinese, full pinyin, citycode, adcode\url{https://lbs.amap.com/api/webservice/download}.\cr
#' The default value is NULL which will search country-wide. The default value is NULL
#' @param sig Optional.\cr
#' Digital Signature.\cr
#' How to use this argument? Please check here{https://lbs.amap.com/faq/account/key/72}
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON and XML. The default value is JSON.
#' @param callback Optional.\cr
#' Callback Function. \cr
#' The value of callback is the customized function. Only available with JSON output.
#' If you don't understand, it means you don't need it, just like me.
#' @param to_table Optional.\cr
#' Transform response content to tibble.\cr#'
#' @return
#' Returns a JSON, XML or Tibble of results containing detailed geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.
getCoord.individual <-
  function(address,
           key = NULL,
           city = NULL,
           sig = NULL,
           output = NULL,
           callback = NULL,
           to_table = TRUE) {
    # Arguments check ---------------------------------------------------------
    # Check if key argument is set or not
    # If there is no key, try to get amap_key from option and set as key
    if (is.null(key)) {
      if (is.null(getOption('amap_key'))) {
        stop(
          'Please set key argument or set amap_key globally by this command
             options(amap_key = your key)'
        )
      }
      key = getOption('amap_key')
    }
    # If to_table has been set, replace output as XML
    # Will be remove once JSON extract function finished
    # if (isTRUE(to_table)) {
    #   output = 'XML'
    # }

    # assemble url and parameter ----------------------------------------------
    base_url = 'https://restapi.amap.com/v3/geocode/geo'

    query_parm = list(
      key = key,
      address = address,
      city = city,
      sig = sig,
      output = output,
      callback = callback
    )

    # GET a response with full url --------------------------------------------
    res <-
      httr::RETRY('GET', url = base_url, query = query_parm)
    httr::stop_for_status(res)
    res_content <-
      httr::content(res)

    # Transform response to tibble or return directly -------------------------

    if (isTRUE(to_table)) {
      extractCoord(res_content) %>%
        return()
    } else {
      return(res_content)
    }
  }

#' Extract coordinate from location request
#'
#' @param res Required.\cr
#' Response from getCoord.
#'
#' @return
#' Returns a tibble which extracts detailed coordinate information from results of getCoord. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.
#' @export
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#' library(amapGeocode)
#'
#' # Before the `getCoord()` is executed,
#' # the token should be set by `option(amap_key = 'key')`
#' # or set by key argument in `getCoord()`
#'
#' # Get geocode as a XML
#' getCoord('IFS Chengdu', output = 'XML') %>%
#'    # extract geocode regions as a tibble
#'    extractCoord()
#' }
#'
#' @seealso \code{\link{getCoord}}

extractCoord <- function(res) {
  # Detect what kind of response will go to parse ------------------------------
  xml_detect <-
    any(stringr::str_detect(class(res), 'xml_document'))
  # Convert xml2 to list
  if (isTRUE(xml_detect)) {
    # get the number of retruned address
    res <-
      res %>% xml2::as_list() %>% '$'('response')
  }

    # detect whether request succeed or not
  if (res$status != 1) {
    stop(res$info)
  }

  # detect thee number of response
  obj_count <-
    res$count
  # Return a row with all NA
  if (obj_count == 0) {
    tibble::tibble(
      lng = NA,
      lat = NA,
      formatted_address = NA,
      country = NA,
      province = NA,
      city = NA,
      district = NA,
      township = NA,
      street = NA,
      number = NA,
      citycode = NA,
      adcode = NA
    )
  } else if (obj_count == 1) {
    # get geocodes node for futher parse
    geocode <-
      res$geocodes[[1]]
    # parse lng and lat from location
    location_in_coord =
      geocode$location %>%
      # Internal Function from Helpers, no export
      str_loc_to_num_coord()
    # set parameter name
    var_name <-
      c(
        'formatted_address',
        'country',
        'province',
        'city',
        'district',
        'township',
        'street',
        'number',
        'citycode',
        'adcode'
      )
    # extract value of above parameters
    ls_var <- lapply(var_name,
                     function(x) {
                       x = ifelse(sjmisc::is_empty(geocode[[x]]), NA, geocode[[x]])
                     }) %>%
      as.data.frame()

    tibble::tibble(lng = location_in_coord[[1]],
                   lat = location_in_coord[[2]],
                   ls_var) %>%
      # set name of tibble
      stats::setNames(c('lng', 'lat', var_name))
  }
}
