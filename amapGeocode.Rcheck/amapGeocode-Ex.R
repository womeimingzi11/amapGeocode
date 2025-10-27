pkgname <- "amapGeocode"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('amapGeocode')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("convertCoord")
### * convertCoord

flush(stderr()); flush(stdout())

### Name: convertCoord
### Title: Convert coordinate from different coordinate systems to AutoNavi
###   system
### Aliases: convertCoord

### ** Examples

## Not run: 
##D library(amapGeocode)
##D 
##D # Before the `convertCoord()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `convertCoord()`
##D 
##D # get result of converted coordinate system as a data.table
##D convertCoord("116.481499,39.990475", coordsys = "gps")
##D # get result of converted coordinate system as a XML
##D convertCoord("116.481499,39.990475", coordsys = "gps", to_table = FALSE)
## End(Not run)




cleanEx()
nameEx("extractAdmin")
### * extractAdmin

flush(stderr()); flush(stdout())

### Name: extractAdmin
### Title: Get Subordinate Administrative Region from getAdmin request Now,
###   it only support extract the first layer of subordinate administrative
###   region information.
### Aliases: extractAdmin

### ** Examples

## Not run: 
##D library(dplyr)
##D library(amapGeocode)
##D 
##D # Before the `getAdmin()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `getAdmin()`
##D 
##D # Get subordinate administrative regions as a XML
##D getAdmin("Sichuan Province", output = "XML")  |>
##D   # extract subordinate administrative regions as a data.table
##D   extractAdmin()
## End(Not run)




cleanEx()
nameEx("extractConvertCoord")
### * extractConvertCoord

flush(stderr()); flush(stdout())

### Name: extractConvertCoord
### Title: Extract converted coordinate points from convertCoord request
### Aliases: extractConvertCoord

### ** Examples

## Not run: 
##D library(dplyr)
##D library(amapGeocode)
##D 
##D # Before the `convertCoord()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `convertCoord()`
##D 
##D # get result of converted coordinate system as a XML
##D convertCoord("116.481499,39.990475", coordsys = "gps", to_table = FALSE) %>%
##D   # extract result of converted coordinate system as a data.table
##D   extractConvertCoord()
## End(Not run)




cleanEx()
nameEx("extractCoord")
### * extractCoord

flush(stderr()); flush(stdout())

### Name: extractCoord
### Title: Extract coordinate from location request
### Aliases: extractCoord

### ** Examples

## Not run: 
##D library(dplyr)
##D library(amapGeocode)
##D 
##D # Before the `getCoord()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `getCoord()`
##D 
##D # Get geocode as a XML
##D getCoord("IFS Chengdu", output = "XML")  |>
##D   # extract geocode regions as a data.table
##D   extractCoord()
## End(Not run)




cleanEx()
nameEx("extractLocation")
### * extractLocation

flush(stderr()); flush(stdout())

### Name: extractLocation
### Title: Extract location from coordinate request
### Aliases: extractLocation

### ** Examples

## Not run: 
##D library(dplyr)
##D library(amapGeocode)
##D 
##D # Before the `getLocation()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `getLocation()`
##D # Get reverse-geocode as a XML
##D getLocation(104.043284, 30.666864, output = "XML") |>
##D   # extract reverse-geocode regions as a table
##D   extractLocation()
## End(Not run)




cleanEx()
nameEx("getAdmin")
### * getAdmin

flush(stderr()); flush(stdout())

### Name: getAdmin
### Title: Get Subordinate Administrative Regions from location
### Aliases: getAdmin

### ** Examples

## Not run: 
##D library(amapGeocode)
##D 
##D # Before the `getAdmin()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `getAdmin()`
##D 
##D # Get subordinate administrative regions as a data.table
##D getAdmin("Sichuan Province")
##D # Get subordinate administrative regions as a XML
##D getCoord("Sichuan Province", output = "XML")
## End(Not run)




cleanEx()
nameEx("getCoord")
### * getCoord

flush(stderr()); flush(stdout())

### Name: getCoord
### Title: Get coordinate from location
### Aliases: getCoord

### ** Examples

## Not run: 
##D library(amapGeocode)
##D 
##D # Before the `getCoord()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `getCoord()`
##D 
##D # Get geocode as a data.table
##D getCoord("IFS Chengdu")
##D # Get geocode as a XML
##D getCoord("IFS Chengdu", output = "XML")
## End(Not run)




cleanEx()
nameEx("getLocation")
### * getLocation

flush(stderr()); flush(stdout())

### Name: getLocation
### Title: Get location from coordinate
### Aliases: getLocation

### ** Examples

## Not run: 
##D library(amapGeocode)
##D 
##D # Before the `getLocation()` is executed,
##D # the token should be set by `option(amap_key = 'key')`
##D # or set by key argument in `getLocation()`
##D 
##D # Get reverse-geocode as a table
##D getLocation(104.043284, 30.666864)
##D # Get reverse-geocode as a XML
##D getLocation("104.043284, 30.666864", output = "XML")
## End(Not run)




### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
