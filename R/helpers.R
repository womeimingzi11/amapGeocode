#' Take longitude and latitude from location string out.
#'
#' @param str_location Required. \cr
#' Location string from response
#'
#' @return
#' vector contains Longitude and Latitude in numeric
str_loc_to_num_coord <- function(str_location) {
  if (length(str_location) == 0) {
    return(c(NA_real_, NA_real_))
  }
  empty <- is.na(str_location) | !nzchar(str_location)
  out <- matrix(NA_real_, nrow = length(str_location), ncol = 2)
  if (any(!empty)) {
    parts <- strsplit(str_location[!empty], split = ",", fixed = TRUE)
    coords <- lapply(parts, function(x) as.numeric(x[1:2]))
    out[!empty, ] <- do.call(rbind, coords)
  }
  if (length(str_location) == 1L) {
    return(out[1L, ])
  }
  out
}

#' Take longitude and latitude from location string out.
#'
#' @param lng Required. \cr
#' Longitude in decimal
#' @param lat Required. \cr
#' Latitude in decimal
#' @return
#' Comma binded coordinate string
num_coord_to_str_loc <- function(lng, lat) {
  # From the document of AutoNavi Map API,
  # the significant figures of Longitude and Latitude
  # should be lower than 6
  paste(round(lng, 6), round(lat, 6), sep = ",")
}
