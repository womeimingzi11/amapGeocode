#' Get geocoding
#'
#' @param key Required.\cr
#' Amap Key. \cr
#' Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}
#' @param address Required.\cr
#' Structured address information. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building. \cr
#' For instance '北京市朝阳区阜通东大街6号'. If you want to get multiple adresses, please seperate adresses by '|', and set *batch* as **TRUE**.\cr
#' Maxmium seperated addresses is 10
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
#'
#' @return
#' Returns a JSON or XML of results containing detailed geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo} for more information.
#' @export

getCoord <- function(key, address, city = NULL, batch = NULL, sig = NULL, output = 'XML', callback = NULL) {
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

  RETRY('GET', url = base_url, query = query_parm) %>%
    content()
}
