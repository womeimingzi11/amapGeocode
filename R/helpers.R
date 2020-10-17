#' Take longitude and latitude from location string out.
#'
#' @param str_location Required. \cr
#' Location string from response
#'
#' @return
#' vector contains Longitude and Latitude in numeric
str_loc_to_num_coord <- function(str_location) {
  # seperate a location strings by comma
  sperated_str_loc <-
    stringr::str_split(str_location, pattern = ',', simplify = TRUE)

  as.numeric(sperated_str_loc)
}

#' Take longitude and latitude from location string out.
#'
#' @param lng Required. \cr
#' Longitude in decimal
#' @param lat Required. \cr
#' Latitude in decimal
#' @return
#' Comma binded coordinate string
num_coord_to_str_loc <- function(lng, lat){
  # From the document of AutoNavi Map API, the significant figures of Longitude and Latitude should be lower than 6
  paste(round(lng, 6), round(lat, 6), sep = ',')
}
