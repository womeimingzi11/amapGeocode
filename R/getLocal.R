#' Get location from coordinate
#'
#' @param lng Required. \cr
#' Longitude in decimal
#' @param lat Required. \cr
#' Latitude in decimal
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}
#' @param poitype Optional.\cr
#' Return nearby POI types.\cr
#' When `extensions = all`, this argument makes sense. For detailed poitype type, please refer\url{https://lbs.amap.com/api/webservice/download}
#' @param radius Optional.\cr
#' Searching radius.\cr
#' radius ranges from 0 to 3000, the default value is 1000, unit: meter.
#' @param extensions Optional.\cr
#' Return results controller.\cr
#' Once it is `base`, the default value, it only return base information about coordinate.\cr
#' Once it is `all`, it will return nearby POI, road information and cross information.
#' @param batch Not work yet.\cr
#' Specify whether batch search or not. \cr
#' If batch is TRUE, the maximum 10 address with '|' sign will return. If batch is FALSE, only the first address with '|' returned. The default value is FALSE.
#' @param roadlevel Optional.\cr
#' Road levels.\cr
#' When `extensions = all`, this argument makes sense. \cr
#' `roadlevel=0`, return all roads.\cr
#' `roadlevel=1`, only return main roads.
#' @param sig Optional.\cr
#' Digital Signature.\cr
#' How to use this argument? Please check here{https://lbs.amap.com/faq/account/key/72}
#' @param output Optional.\cr
#' Output Data Structure. \cr
#' Support JSON and XML. The default value is JSON.
#' @param callback Optional.\cr
#' Callback Function. \cr
#' The value of callback is the customized function. Only available with JSON output.
#' If you don't understand, it means you don't need it, just like me.
#' @param homeorcorp Optional.\cr
#' Optimize the order of returned POI or not.\cr
#' When `extensions = all`, this argument makes sense. \cr
#' `homeorcorp=0`, do not optimize, by default.\cr
#' `homeorcorp=1`, home related POIs are first, by default.\cr
#' `homeorcorp=2`, corporation related POIs are first, by default.\cr
#' @param to_table Optional.\cr
#' Transform response content to tibble.\cr
#' If set to_table as TRUE, there is no necessary to parse result by extractCoord anymore.\cr
#' Please note, once to_table was set as TRUE, the output parameter will be replaced by XML
#'
#' @return
#' Returns a JSON, XML or Tibble of results containing detailed reverse geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.
#' @export

getLocation <-
  function(lng,
           lat,
           key = NULL,
           poitype = NULL,
           radius = NULL,
           extensions = NULL,
           batch = NULL,
           roadlevel = NULL,
           sig = NULL,
           output = 'XML',
           callback = NULL,
           homeorcorp = 0,
           to_table = TRUE
  ) {
    # Arguments check ---------------------------------------------------------
    # Combine lng and lat as location which significant figures lower than 6
    location = paste(round(lng, 6), round(lat, 6), sep = ',')
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
    base_url = 'https://restapi.amap.com/v3/geocode/regeo'

    query_parm = list(
      key = key,
      location = location,
      poitype = poitype,
      radius = radius,
      extensions = extensions,
      batch = batch,
      roadlevel = roadlevel,
      sig = sig,
      output = output,
      callback = callback,
      homeorcorp = homeorcorp
    )

    # GET a response with full url --------------------------------------------
    res <-
      httr::RETRY('GET', url = base_url, query = query_parm)
    httr::stop_for_status(res)
    res_content <-
      httr::content(res)

    # Transform response to tibble or return directly -------------------------

    if(isTRUE(to_table)) {
      extractLocation(res_content) %>%
        return()
    } else {
      return(res_content)
    }
  }

#' Extract location from coordiniation request
#'
#' Extract location result from Response of getCoord. For now, only single place response is supported.
#'
#' @param res. Required.\cr
#' Response from getLocation.
#'
#' @return
#' Returns a tibble which extracts detailed location information from results of getLocation. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.

#' @export
extractLocation <- function(res) {
  # Detect what kind of response will be parse ------------------------------
  class_detect <-
    dplyr::case_when(
      any(stringr::str_detect(class(res), 'xml_document')) ~ 'xml',
      # any(stringr::str_detect(class(res), 'tbl')) ~ 'tibble',
      any(stringr::str_detect(class(res), 'list')) ~ 'json_list'
    )


  # Parse xml ---------------------------------------------------------------
  if (class_detect == 'xml') {
    # check the status of request
    obj_stat <-
      res %>% xml2::xml_find_all(
        'status'
      ) %>% xml2::xml_text()

    # get geocodes node for futher parse
    regeocode <-
      res %>% xml2::xml_find_all('regeocode')

    if (obj_stat == '0') {
      tibble::tibble(
        formatted_address = NA,
        country = NA,
        province = NA,
        city = NA,
        district = NA,
        township = NA,
        citycode = NA,
        towncode = NA
      )
    } else if(obj_stat == '1'){
      # get addressComponent from regeocode
      addressComponent <-
        regeocode %>% xml2::xml_find_all('addressComponent')

      # assemble information tible
      tibble::tibble(
        formatted_address = regeocode %>% xml2::xml_find_all('formatted_address') %>% xml2::xml_text(),
        country = addressComponent %>% xml2::xml_find_all('country') %>% xml2::xml_text(),
        province = addressComponent %>% xml2::xml_find_all('province') %>% xml2::xml_text(),
        city = addressComponent %>% xml2::xml_find_all('city') %>% xml2::xml_text(),
        district = addressComponent %>% xml2::xml_find_all('district') %>% xml2::xml_text(),
        township = addressComponent %>% xml2::xml_find_all('township') %>% xml2::xml_text(),
        citycode = addressComponent %>% xml2::xml_find_all('citycode') %>% xml2::xml_text(),
        towncode = addressComponent %>% xml2::xml_find_all('towncode') %>% xml2::xml_text()
      )
    } else {
      stop(res %>% xml2::xml_find_all(
        'info'
      ) %>% xml2::xml_text())
    }
  } else if(class_detect == 'json_list'){
    stop('Sorry, this function is not finished yet')
  } else {
    stop('Only support JSON and XML class.')
  }
}
