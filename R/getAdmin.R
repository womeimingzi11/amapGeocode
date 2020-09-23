#' Get Subordinate Administrative Region from location
#'
#' @param keywords Required.\cr
#' Search keywords. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}
#' @param subdistrict Optional.\cr
#' Subordinate Administrative Level.\cr
#' Display level of subordinate administrative regions. Available value: 0,1,2,3.\cr
#' `0` do not return subordinate administrative regions.\cr
#' `1` return first one subordinate administrative regions.\cr
#' `2` return first two subordinate administrative regions.\cr
#' `3` return first three subordinate administrative regions.
#' @param page Optional.\cr
#' Which page to return.\cr
#' Everytime the outmost layer will return a maximum of 20 records. If the limit is exceeded, please request the next page of records with the page argument.
#' @param offset Optional.\cr
#' Maximum records per page.\cr
#' Maximum value is 20.
#' @param extensions Optional.\cr
#' Return results controller.\cr
#' `base`: does not return the coordinates of the administrative district boundary.\cr
#' `all`: returns only the boundary value of the current query district, not the boundary value of the child node.
#' @param filter Optional.\cr
#' Filter administrative regions.\cr
#' Filtering by designated administrative divisions, which returns information only for the province/municipality.\cr
#' It is strongly recommended to fill in this parameter in order to ensure the correct records.
#' @param callback Optional.\cr
#' Callback Function. \cr
#' The value of callback is the customized function. Only available with JSON output.
#' If you don't understand, it means you don't need it, just like me.
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON and XML. The default value is JSON.
#' @return
#' Returns a JSON or XML of results containing detailed subordinate administrative region information. See \url{https://lbs.amap.com/api/webservice/guide/api/district} for more information.
#' @export
getAdmin <-
  function(keywords,
           key = NULL,
           subdistrict = NULL,
           page = NULL,
           offset = NULL,
           extensions = NULL,
           filter = NULL,
           callback = NULL,
           output = 'JSON') {
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
    base_url = 'https://restapi.amap.com/v3/config/district'

    query_parm = list(
      key = key,
      keywords = keywords,
      subdistrict = subdistrict,
      page = page,
      offset = offset,
      extensions = extensions,
      filter = filter,
      callback = callback,
      output = output
    )

    # GET a response with full url --------------------------------------------
    res <-
      httr::RETRY('GET', url = base_url, query = query_parm)
    httr::stop_for_status(res)
    res_content <-
      httr::content(res)

    # Transform response to tibble or return directly -------------------------
#
#     if (isTRUE(to_table)) {
#       extractCoord(res_content) %>%
#         return()
#     } else {
      return(res_content)
#     }
  }
