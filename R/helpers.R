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

#' Create a local parallel cluster
#'
#' @param max_core Optional \cr
#' A threshold of max cores for parallel operation. There is no need to set a `max_core` generally.
#' But for some extreme high performance case, like `AMD Threadripper` and `Intel Xeon`,
#' super multiple-core CPU will meet the limitation of queries per second.
#' @return
#' A local parallel cluster
parallel_cluster_maker <- function(max_core = NULL){
  # detect the number of logical cores
  # generally, to avoid the OS stuck, we often drop at least 1 core.
  # however, http request is really a light weight task for modern device, even a arm v7 device,
  # we use all the cores to speed up the request.
    if (is.null(max_core)) {
    core_num <-
      parallel::detectCores()
  } else {
    core_num <-
      parallel::detectCores()
    core_num <-
      ifelse(core_num > max_core, max_core, core_num)
  }
  cluster <- parallel::makeCluster(core_num)
}
