% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convertCoord.R
\name{convertCoord.individual}
\alias{convertCoord.individual}
\title{Convert an individual coordinate from
different coordinate systems to AutoNavi system}
\usage{
convertCoord.individual(
  locations,
  key = NULL,
  coordsys = NULL,
  sig = NULL,
  output = "data.table",
  keep_bad_request = TRUE,
  ...
)
}
\arguments{
\item{locations}{Required. \cr
String coordinate point from other coordinate system}

\item{key}{Optional.\cr
Amap Key. \cr
Applied from AutoNavi Map API official website\url{https://lbs.amap.com/dev/}}

\item{coordsys}{Optional.\cr
Coordinate System. \cr
Support: `gps`,`mapbar`,`baidu` and `autonavi`-not convert}

\item{sig}{Optional.\cr
Digital Signature.\cr
How to use this argument?
Please check here{https://lbs.amap.com/faq/account/key/72}}

\item{output}{Optional.\cr
Output Data Structure. \cr
Support JSON, XML and data.table. The default value is data.table.}

\item{keep_bad_request}{Optional.\cr
Keep Bad Request to avoid breaking a workflow,
especially meaningful in a batch request}

\item{...}{Optional.\cr
For compatibility only}
}
\value{
Returns a JSON, XML or data.table of results
containing detailed geocode information.
See \url{https://lbs.amap.com/api/webservice/guide/api/convert}
for more information.
}
\description{
Convert an individual coordinate from
different coordinate systems to AutoNavi system
}
