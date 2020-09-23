
<!-- README.md is generated from README.Rmd. Please edit that file -->

[amapGeocode](https://github.com/womeimingzi11/amapGeocode)
===========================================================

<!-- badges: start -->

<img src="man/figures/hexSticker-logo.png" width="100" />
<!-- badges: end -->

Geocoding and Reverse Geocoding Services are widely used to provide data
about coordinate and location information, including longitude,
latitude, formatted location name, administrative region with different
levels. There are some package can provide geocode service such as
[tidygeocoder](https://cran.r-project.org/web/packages/tidygeocoder/index.html),
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). However, some of them
not always provide precise information in China, and some of them is
unavailable with upgrade backend API.

amapGeocode is built to provide high precise geocoding and reverse
gecoding service, and it provides an interface for the AutoNavi(高德)
Maps API geocoding services. API docs can be foun
[here](https://lbs.amap.com/) and
[here](https://lbs.amap.com/api/webservice/summary/). Here are two main
functions to use are `getCoord()` which takes a character location name
as an input and `getLocation()` which takes two numeric longitude and
latitude values as inputs.

The `getCoord()` function extracts coordinate information from input
character location name and output the result as `tibble`, `XML` or
`JSON (as list)`. And the `getLocation()` function extracts location
information from input numeric longitude and latitude values and output
the result as `tibble`, `XML` or `JSON (as list)`. With the `tibble`
format as output, it’s highly readable and easy to be used to `tidy`
workflow.

This project is still in a very early stage and only the geocoding
function has been developed. So all the functions may change or
supersede, so it’s not recommended to use this package in production
environment till it goes to stable stage. When will the stable stage
come? It depends my graduate progress.

amapGeocode is inspired by
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). If you want to choose
the Baidu Map API, these packages are good choice.

Baidu or AutoNavi? Here is the main differences:

1.  AutoNavi has significant high precise, in my case, the Results from
    Baidu were unsatisfactory.
2.  Baidu with free verification provides really high request:
    300,000/month for each geocode/reverse-geocode, while AutoNavi only
    provide 6,000/month.

Installation
------------

amapGeocode may be published to [CRAN](https://CRAN.R-project.org) once
the first available version been finished.

For now, please install amapGeocode from GitHub following this command:

    remotes::install_github('womeimingzi11/amapGeocode')

<!-- You can install the released version of amapGeocode from [CRAN](https://CRAN.R-project.org) with: -->
<!-- ``` r -->
<!-- install.packages("amapGeocode") -->
<!-- ``` -->

Usage
-----

### Geocoding

Before start geocoding and reverse geocoding, please apply a [AutoNavi
Map API Key](https://lbs.amap.com/dev/). Set `amap_key` globally by
following command:

Then get result of geocoding, by `getCoord` function.

    library(amapGeocode)
    res <-
      getCoord('成都中医药大学')
    knitr::kable(res)

|      lng |      lat | formatted\_address               | country | province | city   | district | township | street | number | citycode | adcode |
|---------:|---------:|:---------------------------------|:--------|:---------|:-------|:---------|:---------|:-------|:-------|:---------|:-------|
| 104.0433 | 30.66686 | 四川省成都市金牛区成都中医药大学 | 中国    | 四川省   | 成都市 | 金牛区   | NA       | NA     | NA     | 028      | 510106 |

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to `tibble`, [a modern reimagining of
the data.frame](https://tibble.tidyverse.org/), by setting `to_table`
argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, please set
`to_table = TRUE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extractCoord`.

    res <-
      getCoord('成都中医药大学', to_table = FALSE)
    res
    #> {xml_document}
    #> <response>
    #> [1] <status>1</status>
    #> [2] <info>OK</info>
    #> [3] <infocode>10000</infocode>
    #> [4] <count>1</count>
    #> [5] <geocodes type="list">\n  <geocode>\n    <formatted_address>四川省成都市金牛区成都中医 ...

`extractCoord` is created to get result as tibble.

    res
    #> {xml_document}
    #> <response>
    #> [1] <status>1</status>
    #> [2] <info>OK</info>
    #> [3] <infocode>10000</infocode>
    #> [4] <count>1</count>
    #> [5] <geocodes type="list">\n  <geocode>\n    <formatted_address>四川省成都市金牛区成都中医 ...
    tb <- 
      extractCoord(res)
    knitr::kable(tb)

|      lng |      lat | formatted\_address               | country | province | city   | district | township | street | number | citycode | adcode |
|---------:|---------:|:---------------------------------|:--------|:---------|:-------|:---------|:---------|:-------|:-------|:---------|:-------|
| 104.0433 | 30.66686 | 四川省成都市金牛区成都中医药大学 | 中国    | 四川省   | 成都市 | 金牛区   | NA       | NA     | NA     | 028      | 510106 |

### Reverse Geocoding

get result of reverse geocoding, by `get` function.

    res <- 
      getLocation(104.043284, 30.666864)
    knitr::kable(res)

| formatted\_address                                                                   | country | province | city   | district | township   | citycode | towncode     |
|:-------------------------------------------------------------------------------------|:--------|:---------|:-------|:---------|:-----------|:---------|:-------------|
| 四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二桥校区) | 中国    | 四川省   | 成都市 | 金牛区   | 西安路街道 | 028      | 510106024000 |

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to `tibble`, [a modern reimagining of
the data.frame](https://tibble.tidyverse.org/), by setting `to_table`
argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, please set
`to_table = TRUE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extractLocation`.

    res <-
       getLocation(104.043284, 30.666864, to_table = FALSE)
    res
    #> {xml_document}
    #> <response>
    #> [1] <status>1</status>
    #> [2] <info>OK</info>
    #> [3] <infocode>10000</infocode>
    #> [4] <regeocode>\n  <formatted_address>四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二 ...

`extractLocation` is created to get result as tibble.

    res
    #> {xml_document}
    #> <response>
    #> [1] <status>1</status>
    #> [2] <info>OK</info>
    #> [3] <infocode>10000</infocode>
    #> [4] <regeocode>\n  <formatted_address>四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二 ...
    tb <- 
      extractLocation(res)
    knitr::kable(tb)

| formatted\_address                                                                   | country | province | city   | district | township   | citycode | towncode     |
|:-------------------------------------------------------------------------------------|:--------|:---------|:-------|:---------|:-----------|:---------|:-------------|
| 四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二桥校区) | 中国    | 四川省   | 成都市 | 金牛区   | 西安路街道 | 028      | 510106024000 |

For more functions and improvements, Coming Soon!

Bug report
----------

It’s very common for API upgrades to make the downstream application,
like amapGeocode, to be unavailable. Feel free to [let me
know](mailto://chenhan28@gmail.com) once it’s broken or just open an
issue.

Acknowledgements
----------------

Hex Sticker was created by [hexSticker
package](https://github.com/GuangchuangYu/hexSticker) with the world
data from
[rnaturalearth](https://cran.r-project.org/web/packages/rnaturalearth/index.html).
