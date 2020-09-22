#' Get coordinate from location
#'
#' @param address Required.\cr
#' Structured address information. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building. \cr
#' For instance '北京市朝阳区阜通东大街6号'. If you want to get multiple adresses, please seperate adresses by '|', and set *batch* as **TRUE**.\cr
#' Maxmium seperated addresses is 10
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}
#' @param city Optional.\cr
#' Specify the City. \cr
#' Support: city in Chinese, full pinyin, citycode, adcode\url{https://lbs.amap.com/api/webservice/download}.\cr
#' The default value is NULL which will search country-wide. The default value is NULL
#' @param batch Optional.\cr
#' Specify whether batch search or not. \cr
#' If batch is TRUE, the maximum 10 address with '|' sign will return. If batch is FALSE, only the first address with '|' returned. The default value is FALSE.
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
#' Transform response content to tibble.\cr
#' If set to_table as TRUE, there is no necessary to parse result by extractCoord anymore.\cr
#' Please note, once to_table was set as TRUE, the output parameter will be replaced by XML
#'
#' @return
#' Returns a JSON, XML or Tibble of results containing detailed geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.
#' @export

getCoord <-
  function(address,
           key = NULL,
           city = NULL,
           batch = NULL,
           sig = NULL,
           output = 'XML',
           callback = NULL,
           to_table = TRUE
           ) {

# Arguments check ---------------------------------------------------------
    # Check if the adress is multiple or not
    if (stringr::str_detect(address, string = stringr::fixed('|'))) {
      if(!isTRUE(batch)){
        warning('Multiple address has been detected by | sign, unfortunately batch argument is not TRUE yet!' )
      }
    }
    # Check if key argument is set or not
    # If there is no key, try to get amap_key from option and set as key
    if(is.null(key)){
      if(is.null(getOption('amap_key'))){
        stop('Please set key argument or set amap_key globally by this command
             options(amap_key = your key)')
      }
      key = getOption('amap_key')
    }
    # If to_table has been set, replace output as XML
    # Will be remove once JSON extract function finished
    if(isTRUE(to_table)){
      output = 'XML'
    }

# assemble url and parameter ----------------------------------------------


    base_url = 'https://restapi.amap.com/v3/geocode/geo'

    query_parm = list(
      key = key,
      address = address,
      city = city,
      batch = batch,
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

    if(isTRUE(to_table)) {
      extractCoord(res_content) %>%
        return()
    } else {
      return(res_content)
    }
  }

#' Extract coordiniation from location request
#'
#' Extract coordiniation result from Response of getCoord. For now, only single place response is supported.
#'
#' @param res. Required.\cr
#' Response from getCoord.
#'
#' @return
#' Returns a tibble which extracts detailed coordiniation information from results of getCoord. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.

#' @export
extractCoord <- function(res) {

# Detect what kind of response will be parse ------------------------------
  class_detect <-
    dplyr::case_when(
      any(stringr::str_detect(class(res), 'xml_document')) ~ 'xml',
      # any(stringr::str_detect(class(res), 'tbl')) ~ 'tibble',
      any(stringr::str_detect(class(res), 'list')) ~ 'json_list'
    )


# Parse xml ---------------------------------------------------------------
  if (class_detect == 'xml') {
    # get the number of retruned address
    obj_count <-
      res %>% xml2::xml_find_all(
        'count'
      ) %>% xml2::xml_text()

    # get geocodes node for futher parse
    geocodes <-
      res %>% xml2::xml_find_all('geocodes')

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
    } else if(obj_count == 1){
      # get geocode from geocodes
      geocode <-
        geocodes %>% xml2::xml_find_all('geocode')
      # parse lng and lat from location
      location =
        xml2::xml_find_all(geocode, 'location') %>% xml2::xml_text() %>%
        stringr::str_split(pattern = ',',simplify = TRUE)

      # assemble information tible
      tibble::tibble(
        lng = location[[1]],
        lat = location[[2]],
        formatted_address = xml2::xml_find_all(geocode, 'formatted_address') %>% xml2::xml_text(),
        country = xml2::xml_find_all(geocode, 'country') %>% xml2::xml_text(),
        province = xml2::xml_find_all(geocode, 'province') %>% xml2::xml_text(),
        city = xml2::xml_find_all(geocode, 'city') %>% xml2::xml_text(),
        district = xml2::xml_find_all(geocode, 'district') %>% xml2::xml_text(),
        township = xml2::xml_find_all(geocode, 'township') %>% xml2::xml_text(),
        street = xml2::xml_find_all(geocode, 'street') %>% xml2::xml_text(),
        number = xml2::xml_find_all(geocode, 'number') %>% xml2::xml_text(),
        citycode = xml2::xml_find_all(geocode, 'citycode') %>% xml2::xml_text(),
        adcode = xml2::xml_find_all(geocode, 'adcode') %>% xml2::xml_text()
      )
    } else {
      stop('Do not support multiple return yet')
    }
  } else if(class_detect == 'json_list'){
    stop('Sorry, this function is not finished yet')
  } else {
    stop('Only support JSON and XML class.')
  }
}
