#' Get Subordinate Administrative Regions from location
#'
#' @param keywords Required.\cr
#' Search keywords. \cr
#' Rules: Country/Region, Province/State,
#' City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from 'AutoNavi' Map API
#' official website\url{https://lbs.amap.com/dev/}
#' @param subdistrict Optional.\cr
#' Subordinate Administrative Level.\cr
#' Display level of subordinate administrative regions.
#' Available value: 0,1,2,3.\cr
#' `0` do not return subordinate administrative regions.\cr
#' `1` return first one subordinate administrative regions.\cr
#' `2` return first two subordinate administrative regions.\cr
#' `3` return first three subordinate administrative regions.
#' @param page Optional.\cr
#' Which page to return.\cr
#' Each time the outmost layer will return a maximum of 20 records.
#' If the limit is exceeded,
#' please request the next page of records with the page argument.
#' @param offset Optional.\cr
#' Maximum records per page.\cr
#' Maximum value is 20.
#' @param extensions Optional.\cr
#' Return results controller.\cr
#' `base`: does not return the coordinates of
#' the administrative district boundary.\cr
#' `all`: returns only the boundary value of the current query district,
#' not the boundary value of the child node.
#' @param filter Optional.\cr
#' Filter administrative regions.\cr
#' Filtering by designated administrative divisions,
#' which returns information only for the province/municipality.\cr
#' It is strongly recommended to fill in this parameter
#' in order to ensure the correct records.
#' @param callback Optional.\cr
#' Callback Function. \cr
#' The value of callback is the customized function.
#' Only available with JSON output.
#' If you don't understand, it means you don't need it, just like me.
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON, XML and data.table. The default value is data.table.
#' @param keep_bad_request Optional.\cr
#' Keep Bad Request to avoid breaking a workflow,
#' especially meaningful in a batch request
#'
#' @param ... Optional.\cr
#' For compatibility only
#'
#' @return
#' Returns a JSON or XML of results
#' containing detailed subordinate administrative region information.
#' See \url{https://lbs.amap.com/api/webservice/guide/api/district}
#' for more information.
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
#' # Get subordinate administrative regions as a data.table
#' getAdmin("Sichuan Province")
#' # Get subordinate administrative regions as a XML
#' getCoord("Sichuan Province", output = "XML")
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
           output = "data.table",
           keep_bad_request = TRUE,
           ...) {
      # handle multiple or solo address,
      # parallel operation will be applied
      # if a strategy has been chosen by `future::plan()`
      ls_queries <-
        furrr::future_map(
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
          keep_bad_request = keep_bad_request
        )

      # if there is only one keyword, there is no need
      # to return a list which only contain one element.
      if (length(keywords) == 1) ls_queries <- ls_queries[[1]]

      # here, getAdmin doesn't support bind rows
      # because what the `getAdmin.individual` get general is a data.table
      # `rbindlist` has the potential probability to
      # confuse the dimension of data.tables
      ls_queries
  }

#' Get an individual data.table of
#' Subordinate Administrative Regions from location
#'
#' @param keywords Required.\cr
#' Search keywords. \cr
#' Rules: Country/Region, Province/State,
#' City, County/District, Town, Country, Road, Number, Room, Building.
#' @param key Optional.\cr
#' Amap Key. \cr
#' Applied from 'AutoNavi' Map API
#' official website\url{https://lbs.amap.com/dev/}
#' @param subdistrict Optional.\cr
#' Subordinate Administrative Level.\cr
#' Display level of subordinate administrative regions.
#' Available value: 0,1,2,3.\cr
#' `0` do not return subordinate administrative regions.\cr
#' `1` return first one subordinate administrative regions.\cr
#' `2` return first two subordinate administrative regions.\cr
#' `3` return first three subordinate administrative regions.
#' @param page Optional.\cr
#' Which page to return.\cr
#' Each time the outmost layer will return a maximum of 20 records.
#' If the limit is exceeded,
#' please request the next page of records with the page argument.
#' @param offset Optional.\cr
#' Maximum records per page.\cr
#' Maximum value is 20.
#' @param extensions Optional.\cr
#' Return results controller.\cr
#' `base`: does not return the coordinates of
#' the administrative district boundary.\cr
#' `all`: returns only the boundary value of the current query district,
#' not the boundary value of the child node.
#' @param filter Optional.\cr
#' Filter administrative regions.\cr
#' Filtering by designated administrative divisions,
#' which returns information only for the province/municipality.\cr
#' It is strongly recommended to fill in this parameter
#' in order to ensure the correct records.
#' @param callback Optional.\cr
#' Callback Function. \cr
#' The value of callback is the customized function.
#' Only available with JSON output.
#' If you don't understand, it means you don't need it, just like me.
#' @param output Optional.\cr
#'  Output Data Structure. \cr
#' Support JSON, XML and data.table. The default value is data.table.
#' @param keep_bad_request Optional.\cr
#' Keep Bad Request to avoid breaking a workflow,
#' especially meaningful in a batch request
#'
#' @param ... Optional.\cr
#' For compatibility only
#'
#' @return
#' Returns a JSON or XML of results
#' containing detailed subordinate administrative region information.
#' See \url{https://lbs.amap.com/api/webservice/guide/api/district}
#' for more information.
getAdmin.individual <-
  function(keywords,
           key = NULL,
           subdistrict = NULL,
           page = NULL,
           offset = NULL,
           extensions = NULL,
           filter = NULL,
           callback = NULL,
           output = "data.table",
           keep_bad_request = TRUE,
           ...) {
    # Arguments check ---------------------------------------------------------
    # Check if key argument is set or not
    # If there is no key, try to get amap_key from option and set as key
    if (is.null(key)) {
      if (is.null(getOption("amap_key"))) {
        stop(
          "Please set key argument or set amap_key globally by this command
               options(amap_key = your key)",
          call. = FALSE
        )
      }
      key <- getOption("amap_key")
    }

    # Check wether output argument is data.table
    # If it is, override argument, because the API did not support data.table
    # the convert will be performed locally.
    if (output == "data.table") {
      output <- NULL
    }

    # assemble url and parameter ----------------------------------------------
    base_url <- "https://restapi.amap.com/v3/config/district"

    query_parm <- list(
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
      httr::RETRY("GET", url = base_url, query = query_parm)

    if (!keep_bad_request) {
      httr::stop_for_status(res)
    } else {
      httr::warn_for_status(res,
                            paste0(keywords,
                                   "makes an unsuccessfully request"))
    }

    res_content <-
      httr::content(res)

    # Transform response to data.table or return directly ---------

    if (is.null(output)) {
      return(extractAdmin(res_content))
    } else {
      return(res_content)
    }
  }

#' Get Subordinate Administrative Region from getAdmin request
#' Now, it only support extract the first layer of
#' subordinate administrative region information.
#'
#' @param res
#' Response from getAdmin.
#'
#' @return
#' Returns a data.table which extracts
#' detailed subordinate administrative region information
#' from results of getCoord.
#' See \url{https://lbs.amap.com/api/webservice/guide/api/district}
#' for more information.
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
#' # Get subordinate administrative regions as a XML
#' getAdmin("Sichuan Province", output = "XML") %>%
#'   # extract subordinate administrative regions as a data.table
#'   extractAdmin()
#' }
#'
#' @seealso \code{\link{getAdmin}}

extractAdmin <- function(res) {
  # Detect what kind of response will go to parse ------------------------------

  # If there is a bad request, return a data.table directly.
  if (length(res) == 0) {
    data.table::data.table(
      lng = NA,
      lat = NA,
      name = "Bad Request",
      level = NA,
      citycode = NA,
      adcode = NA
    )
  } else {
    xml_detect <-
      any(stringr::str_detect(class(res), "xml_document"))
    # Convert xml2 to list
    if (isTRUE(xml_detect)) {
      # get the number of retruned address
      res <-
        xml2::as_list(res)
      res <-
        res$response
    }

    # detect whether request succeed or not
    if (res$status != 1) {
      stop(res$info, call. = FALSE)
    }

    # detect thee number of response
    obj_count <-
      res$count

    if (obj_count == 0) {
      data.table::data.table(
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
        c(
          "name",
          "level",
          "citycode",
          "adcode"
        )

      lapply(sub_res$districts, function(district) {
        # parse lng and lat from location (district$center)
        location_in_coord <-
          # Internal Function from Helpers, no export
          str_loc_to_num_coord(district$center)
        # parse other information
        ls_var <-
          lapply(var_name, function(var_n) {
            ifelse(sjmisc::is_empty(district[[var_n]]), NA, district[[var_n]])
          }) %>%
          as.data.frame() %>%
          stats::setNames(var_name)
        # assemble information and coordinate
        data.table::data.table(
          lng = location_in_coord[[1]],
          lat = location_in_coord[[2]],
          ls_var
        )
      }) %>%
        data.table::rbindlist()
    } else {
      "Not support current extraction task."
    }
  }
}
