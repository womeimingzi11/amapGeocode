#' Convert coordinate from different coordinate systems to AutoNavi system
#'
#' \Sexpr[results=rd]{lifecycle::badge("experimental")}
#' This function is a wrap of coordinate convert API of AutoNavi Map Service.\cr
#' While how to input the origin coordinate is sill unstable and 95\% sure that it will have a breaking change in the future.
#' Please consider carefully if introduced this function in product environment.
#'
#' @param locations Required. \cr
#' String coordinate point from other coordinate system
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}
#' @param coordsys Optional.\cr
#' Coordinate System. \cr
#' Support: `gps`,`mapbar`,`baidu` and `autonavi`-not convert
#' @param sig Optional.\cr
#' Digital Signature.\cr
#' How to use this argument? Please check here{https://lbs.amap.com/faq/account/key/72}
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON and XML. The default value is JSON.
#' @param to_table Optional.\cr
#' Transform response content to tibble.
#' @return
#' Returns a JSON, XML or Tibble of results containing detailed geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/convert} for more information.
#' @export
#' @examples
#' \dontrun{
#' library(amapGeocode)
#'
#' # Before the `convertCoord()` is executed,
#' # the token should be set by `option(amap_key = 'key')`
#' # or set by key argument in `convertCoord()`
#'
#' # get result of converted coordinate system as a tibble
#' convertCoord('116.481499,39.990475',coordsys = 'gps')
#' # get result of converted coordinate system as a XML
#' convertCoord('116.481499,39.990475',coordsys = 'gps', to_table = FALSE)
#' }
#'
#' @seealso \code{\link{convertCoord}}
convertCoord <-
  function(
    locations,
    key = NULL,
    coordsys = NULL,
    sig = NULL,
    output = NULL,
    to_table = TRUE
  ){
    if (length(locations) == 1) {
      # if there is one address, use getCoord.individual directly
      convertCoord.individual(
        locations = locations,
        key = key,
        coordsys = coordsys,
        sig = sig,
        output = output,
        to_table = to_table
      )
    } else {
      # if there is multiple addresses, use getCoord.individual by laapply
      ls_queries <-
        purrr::map(
          locations,
          convertCoord.individual,
          key = key,
          coordsys = coordsys,
          sig = sig,
          output = output,
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

#' Convert an individual coordinate from different coordinate systems to AutoNavi system
#'
#' @param locations Required. \cr
#' String coordinate point from other coordinate system
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}
#' @param coordsys Optional.\cr
#' Coordinate System. \cr
#' Support: `gps`,`mapbar`,`baidu` and `autonavi`-not convert
#' @param sig Optional.\cr
#' Digital Signature.\cr
#' How to use this argument? Please check here{https://lbs.amap.com/faq/account/key/72}
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON and XML. The default value is JSON.
#' @param to_table Optional.\cr
#' Transform response content to tibble.\cr#'
#' @return
#' Returns a JSON, XML or Tibble of results containing detailed geocode information. See \url{https://lbs.amap.com/api/webservice/guide/api/convert} for more information.
convertCoord.individual <- function(
  locations,
  key = NULL,
  coordsys = NULL,
  sig = NULL,
  output = NULL,
  to_table = TRUE
) {
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

  # assemble url and parameter ----------------------------------------------

  base_url = 'https://restapi.amap.com/v3/assistant/coordinate/convert'

  query_parm = list(
    key = key,
    locations = locations,
    coordsys = coordsys,
    sig = sig,
    output = output
  )

  # GET a response with full url --------------------------------------------

  res <-
    httr::RETRY('GET', url = base_url, query = query_parm)
  httr::stop_for_status(res)
  res_content <-
    httr::content(res)

  # Transform response to tibble or return directly -------------------------

  if (isTRUE(to_table)) {
    extractConvertCoord(res_content) %>%
      return()
  } else {
    return(res_content)
  }
}
#' Extract converted coordinate points from convertCoord request
#'
#' @param res Required.\cr
#' Response from convertCoord.
#'
#' @return
#' Returns a tibble which extracts converted coordinate points from request of convertCoord. See \url{https://lbs.amap.com/api/webservice/guide/api/convert} for more information.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#' library(amapGeocode)
#'
#' # Before the `convertCoord()` is executed,
#' # the token should be set by `option(amap_key = 'key')`
#' # or set by key argument in `convertCoord()`
#'
#' # get result of converted coordinate system as a XML
#' convertCoord('116.481499,39.990475',coordsys = 'gps', to_table = FALSE) %>%
#'    # extract result of converted coordinate system as a tibble
#'    extractConvertCoord()
#' }
#'
#' @seealso \code{\link{convertCoord}}
extractConvertCoord <- function(res) {
  # Detect what kind of response will go to parse ------------------------------
  xml_detect <-
    any(stringr::str_detect(class(res), 'xml_document'))
  # Convert xml2 to list
  if (isTRUE(xml_detect)) {
    # get the number of retruned address
    res <-
      res %>% xml2::as_list() %>% '$'('response')
  }

  # check the status of request
  request_stat <-
    res$status

  # If request_stat is failure
  # Return the failure information
  if(request_stat == '0'){
    stop(res$info)
  }

  # parse lng and lat from location
  location_in_coord =
    res$locations %>%
    # Internal Function from Helpers, no export
    str_loc_to_num_coord()
  tibble::tibble(
    lng = location_in_coord[[1]],
    lat = location_in_coord[[2]]
  )
}
