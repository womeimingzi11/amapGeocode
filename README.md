
<!-- README.md is generated from README.Rmd. Please edit that file -->

amapGeocode
===========

<!-- badges: start -->
<!-- badges: end -->

**amapGeocode** provides an interface for the AutoNavi(高德) Maps API
geocoding services. API docs can be foun [here](https://lbs.amap.com/)
and [here](https://lbs.amap.com/api/webservice/summary/). For now,
amapGeocode can be used for both forward and revese geocoding powered by
high-precision AutoNavi Maps API.

It’s very common for API upgrades to make the downstream application,
like amapGeocode, to be unavilable. Feel free to [let me
know](mailto://chenhan28@gmail.com) once it’s broken or just open an
issue. \#\# Installation amapGeocode may be published to
[CRAN](https://CRAN.R-project.org) once the first available version been
finished.

For now, please install amapGeocode from GitHub following this command:

    # remotes::install_github('womeimingzi11/amapGeocode')

<!-- You can install the released version of amapGeocode from [CRAN](https://CRAN.R-project.org) with: -->
<!-- ``` r -->
<!-- install.packages("amapGeocode") -->
<!-- ``` -->

Example
-------

This is a basic example which shows you how to solve a common problem:

    library(amapGeocode)
    ## basic example code

What is special about using `README.Rmd` instead of just `README.md`?
You can include R chunks like so:

    summary(cars)
    #>      speed           dist       
    #>  Min.   : 4.0   Min.   :  2.00  
    #>  1st Qu.:12.0   1st Qu.: 26.00  
    #>  Median :15.0   Median : 36.00  
    #>  Mean   :15.4   Mean   : 42.98  
    #>  3rd Qu.:19.0   3rd Qu.: 56.00  
    #>  Max.   :25.0   Max.   :120.00

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date.

You can also embed plots, for example:

<img src="man/figures/README-pressure-1.png" width="100%" />

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub!
