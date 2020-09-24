#' Take longitude and latitude from location string out.
#'
#' @param str_location Required. \cr
#' Location string from response
#'
#' @return
#' vector contains Longitude and Latitude in numeric
str_loc_to_coord <- function(str_location) {
  str_location %>%
    stringr::str_split(pattern = ',', simplify = TRUE) %>%
    as.numeric()
}
