#' Get Subordinate Administrative Regions from location
#'
#' @param keywords Required.\cr
#' Search keywords. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from 'AutoNavi' Map API official website\url{https://lbs.amap.com/dev/}
#' @param subdistrict Optional.\cr
#' Subordinate Administrative Level.\cr
#' Display level of subordinate administrative regions. Available value: 0,1,2,3.\cr
#' `0` do not return subordinate administrative regions.\cr
#' `1` return first one subordinate administrative regions.\cr
#' `2` return first two subordinate administrative regions.\cr
#' `3` return first three subordinate administrative regions.
#' @param page Optional.\cr
#' Which page to return.\cr
#' Each time the outmost layer will return a maximum of 20 records. If the limit is exceeded, please request the next page of records with the page argument.
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
#' @param to_table Optional.\cr
#' Transform response content to tibble.\cr
#' @return
#' Returns a JSON or XML of results containing detailed subordinate administrative region information. See \url{https://lbs.amap.com/api/webservice/guide/api/district} for more information.
#' @export
#'
#' @examples
#' \dontrun{
#' library(amapGeocode)
#'
#' # Before the `getAdmin()` is executed,
#' # the token should be set by `option(amap_key = 'key')`
#' # or set by key argument in `getAdmin()`
#'
#' # Get subordinate administrative regions as a tibble
#' getAdmin('Sichuan Province')
#' # Get subordinate administrative regions as a XML
#' getCoord('Sichuan Province', output = 'XML')
#'
#' }
#'
#' @seealso \code{\link{extractAdmin}}
getAdmin <-
  function(keywords,
           key = NULL,
           subdistrict = NULL,
           page = NULL,
           offset = NULL,
           extensions = NULL,
           filter = NULL,
           callback = NULL,
           output = NULL,
           to_table = TRUE) {
    if (length(keywords) == 1) {
      # if there is one address, use getCoord.individual directly
      getAdmin.individual(
        keywords,
        key = key,
        subdistrict = subdistrict,
        page = page,
        offset = offset,
        extensions = extensions,
        filter = filter,
        callback = callback,
        output = output,
        to_table = to_table
      )
    } else {
      # if there is multiple addresses, use getCoord.individual by laapply
      ls_queries <-
        purrr::map(
          keywords,
          getAdmin.individual,
          key = key,
          subdistrict = subdistrict,
          page = page,
          offset = offset,
          extensions = extensions,
          filter = filter,
          callback = callback,
          output = output,
          to_table = to_table
        )
      # here, getAdmin doesn't support bind_rows
      # because what the `getAdmin.individual` get general is a tibble
      # `bind_rows` has the potential probability to confuse the dimension of tibbles
      return(ls_queries)
    }
  }

#' Get an individual tibble of Subordinate Administrative Regions from location
#'
#' @param keywords Required.\cr
#' Search keywords. \cr
#' Rules: Country/Region, Province/State, City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from 'AutoNavi' Map API official website\url{https://lbs.amap.com/dev/}
#' @param subdistrict Optional.\cr
#' Subordinate Administrative Level.\cr
#' Display level of subordinate administrative regions. Available value: 0,1,2,3.\cr
#' `0` do not return subordinate administrative regions.\cr
#' `1` return first one subordinate administrative regions.\cr
#' `2` return first two subordinate administrative regions.\cr
#' `3` return first three subordinate administrative regions.
#' @param page Optional.\cr
#' Which page to return.\cr
#' Each time the outmost layer will return a maximum of 20 records. If the limit is exceeded, please request the next page of records with the page argument.
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
#' @param to_table Optional.\cr
#' Transform response content to tibble.\cr
#' @return
#' Returns a JSON or XML of results containing detailed subordinate administrative region information. See \url{https://lbs.amap.com/api/webservice/guide/api/district} for more information.
getAdmin.individual <-
  function(keywords,
           key = NULL,
           subdistrict = NULL,
           page = NULL,
           offset = NULL,
           extensions = NULL,
           filter = NULL,
           callback = NULL,
           output = NULL,
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

    if (isTRUE(to_table)) {
      extractAdmin(res_content) %>%
        return()
    } else {
      return(res_content)
    }
  }

#' Get Subordinate Administrative Region from getAdmin request
#' Now, it only support extract the first layer of subordinate administrative region information.
#'
#' @param res
#' Response from getAdmin.
#'
#' @return
#' Returns a tibble which extracts detailed subordinate administrative region information from results of getCoord. See \url{https://lbs.amap.com/api/webservice/guide/api/district} for more information.
#' @export
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#' library(amapGeocode)
#'
#' # Before the `getAdmin()` is executed,
#' # the token should be set by `option(amap_key = 'key')`
#' # or set by key argument in `getAdmin()`
#'
#' #Get subordinate administrative regions as a XML
#' getAdmin('Sichuan Province', output = 'XML') %>%
#'    # extract subordinate administrative regions as a tibble
#'    extractAdmin()
#' }
#'
#' @seealso \code{\link{getAdmin}}

extractAdmin <- function(res) {
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

  if (obj_count == 0) {
    tibble::tibble(
      lng = NA,
      lat = NA,
      name = NA,
      level = NA,
      citycode = NA,
      adcode = NA
    )
  } else if (obj_count == 1) {
    # Take Subordinate Administrative Regions out
    sub_res <-
      res$districts[[1]]
    # Select what variable do we need, except coordinate point
    var_name <-
      c('name',
        'level',
        'citycode',
        'adcode')


    sub_res$districts %>%
      lapply(function(district) {
        # parse lng and lat from location (district$center)
        location_in_coord =
          district$center %>%
          # Internal Function from Helpers, no export
          str_loc_to_num_coord()
        # parse other information
        ls_var <-
          lapply(var_name, function(var_n) {
            ifelse(sjmisc::is_empty(district[[var_n]]), NA, district[[var_n]])
          }) %>%
          as.data.frame() %>%
          stats::setNames(var_name)
        # assemble information and coordinate
        tibble::tibble(lng = location_in_coord[[1]],
                       lat = location_in_coord[[2]],
                       ls_var)
      }) %>%
      dplyr::bind_rows()

  } else {
    'Not support current extraction task.'
  }
}
