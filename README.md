
<!-- README.md is generated from README.Rmd. Please edit that file -->

[amapGeocode](https://github.com/womeimingzi11/amapGeocode)
===========================================================

<!-- badges: start -->
<!-- badges: end -->

**amapGeocode** provides an interface for the AutoNavi(高德) Maps API
geocoding services. API docs can be foun [here](https://lbs.amap.com/)
and [here](https://lbs.amap.com/api/webservice/summary/). For now,
amapGeocode can be used for both forward and revese geocoding powered by
high-precision AutoNavi Maps API.

This project is still in a very early stage and only the geocodig
function has been developed. So all the functions may change or
supersede, so it’s not recommanded to use this package in production
environment till it goes to stable stage. When will the stable stage
come? It depends my graduate progress.

amapGeocode is inspired by
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). If you want to choose
the Baidu Map API, these packages are good choice.

Baidu or AutoNavi? Here is the main differences:

1.  AutoNavi has significant high precise, in my case, the Results from
    Baidu were unsatisfactory.
2.  Baidu with free verification provices really high request:
    300,000/month for each geocode/reverse-geocode, while AutoNavi only
    provide 6000/month.

Installation
------------

amapGeocode may be published to [CRAN](https://CRAN.R-project.org) once
the first available version been finished.

For now, please install amapGeocode from GitHub following this command:

<!-- You can install the released version of amapGeocode from [CRAN](https://CRAN.R-project.org) with: -->
<!-- ``` r -->
<!-- install.packages("amapGeocode") -->
<!-- ``` -->

Usage
-----

Before start geocoding and reverse geocoding, please (apply a AutoNavi
Map API
Key)\[<a href="https://lbs.amap.com/dev/" class="uri">https://lbs.amap.com/dev/</a>\].
Set `amap_key` globally by following command:

Then get result of geocoding, by `getCoord` function:

    library(amapGeocode)
    res <-
      getCoord('成都中医药大学')
    res
    #> {xml_document}
    #> <response>
    #> [1] <status>1</status>
    #> [2] <info>OK</info>
    #> [3] <infocode>10000</infocode>
    #> [4] <count>1</count>
    #> [5] <geocodes type="list">\n  <geocode>\n    <formatted_address>四川省成都市金牛区成都中医 ...

What we get from `getCoord` is **JSON** or **XML**. For readability,
`extractCoord` is created to get result as `tibble`, [a modern
reimagining of the data.frame](https://tibble.tidyverse.org/).

    tb <- extractCoord(res)
    knitr::kable(tb)

| lng        | lat       | formatted\_address               | country | province | city   | district | township | street | number | citycode | adcode |
|:-----------|:----------|:---------------------------------|:--------|:---------|:-------|:---------|:---------|:-------|:-------|:---------|:-------|
| 104.043284 | 30.666864 | 四川省成都市金牛区成都中医药大学 | 中国    | 四川省   | 成都市 | 金牛区   |          |        |        | 028      | 510106 |

For more functions and improvements, Coming Soon!

Bug report
----------

It’s very common for API upgrades to make the downstream application,
like amapGeocode, to be unavilable. Feel free to [let me
know](mailto://chenhan28@gmail.com) once it’s broken or just open an
issue.
