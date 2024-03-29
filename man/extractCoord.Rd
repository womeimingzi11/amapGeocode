% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getCoord.R
\name{extractCoord}
\alias{extractCoord}
\title{Extract coordinate from location request}
\usage{
extractCoord(res)
}
\arguments{
\item{res}{Required.\cr
Response from getCoord.}
}
\value{
Returns a data.table which extracts
detailed coordinate information from results of getCoord.
See \url{https://lbs.amap.com/api/webservice/guide/api/georegeo}
for more information.
}
\description{
Extract coordinate from location request
}
\examples{
\dontrun{
library(dplyr)
library(amapGeocode)

# Before the `getCoord()` is executed,
# the token should be set by `option(amap_key = 'key')`
# or set by key argument in `getCoord()`

# Get geocode as a XML
getCoord("IFS Chengdu", output = "XML")  |>
  # extract geocode regions as a data.table
  extractCoord()
}

}
\seealso{
\code{\link{getCoord}}
}
