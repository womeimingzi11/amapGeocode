
<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- Place this tag in your head or just before your close body tag. -->

<!--<script async defer src="https://buttons.github.io/buttons.js"></script>-->

# [amapGeocode](https://github.com/womeimingzi11/amapGeocode)

<!-- badges: start -->

[![Total downloads
badge](https://cranlogs.r-pkg.org/badges/grand-total/amapGeocode?color=blue)](https://CRAN.R-project.org/package=amapGeocode)
[![CRAN
status](https://www.r-pkg.org/badges/version/amapGeocode)](https://CRAN.R-project.org/package=amapGeocode)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/297431889.svg)](https://zenodo.org/badge/latestdoi/297431889)
[![Codecov test
coverage](https://codecov.io/gh/womeimingzi11/amapGeocode/branch/master/graph/badge.svg)](https://codecov.io/gh/womeimingzi11/amapGeocode?branch=master)
[![R-CMD-check](https://github.com/womeimingzi11/amapGeocode/workflows/R-CMD-check/badge.svg)](https://github.com/womeimingzi11/amapGeocode/actions)
<!-- badges: end -->

中文版介绍:
[博客](https://blog.washman.top/post/amapgeocode-%E4%BD%BF%E7%94%A8r%E8%BF%9B%E8%A1%8C%E9%AB%98%E5%BE%B7%E5%9C%B0%E5%9B%BE%E5%9C%B0%E7%90%86%E7%BC%96%E7%A0%81-%E9%80%86%E7%BC%96%E7%A0%81.zh-hans/)
or [知乎](https://zhuanlan.zhihu.com/p/264281505)

## Introduction <img src="man/figures/hexSticker-logo.png" align="right" width="100"/>

Geocoding and Reverse Geocoding Services are widely used to provide data
about coordinate and location information, including longitude,
latitude, formatted location name, administrative region with different
levels. There are some packages can provide geocode service such as
[tidygeocoder](https://CRAN.R-project.org/package=tidygeocoder),
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). However, some of them
do not always provide precise information in China, and some of them are
unavailable with the upgrade backend API.

amapGeocode is built to provide high precise geocoding and reverse
geocoding service, and it provides an interface for the AutoNavi(高德)
Maps API geocoding services. API docs can be found
[here](https://lbs.amap.com/) and
[here](https://lbs.amap.com/api/webservice/summary/). Here are two main
functions to use, one is `getCoord()` which needs a character location
name as an input, while the other one is `getLocation()` which needs two
numeric longitude and latitude values as inputs.

The `getCoord()` function extracts coordinate information from input
character location name and outputs the results as `data.table`, `XML`
or `JSON (as list)`. And the `getLocation()` function extracts location
information from input numeric longitude and latitude values and outputs
the results as `data.table`, `XML` or `JSON (as list)`. With the
`data.table` format as output, it’s highly readable and can be used as
an alternative of `data.frame`

amapGeocode is inspired by
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). If you want to choose
the Baidu Map API, these packages are good choices.

However, AutoNavi has significant high precise, in my case, the Results
from Baidu were unsatisfactory.

## Highlights

- Unified HTTP handling via [{httr2}](https://httr2.r-lib.org) with
  structured diagnostics (`amap_api_error`) and automatic propagation of
  rate-limit headers.
- Opt-in request signing through `amap_sign()`, `with_amap_signature()`,
  and `amap_config()` keeps sensitive secrets out of function calls.
- `getCoord()` now supports `mode = "all"` for multi-match lookups as
  well as `batch = TRUE` to resolve up to ten addresses per request
  while preserving input order.
- `getLocation()` gains batching plus rich POI, road, intersection, and
  AOI list-columns via the `details` argument when `extensions = "all"`.
- `extractAdmin()` traverses every matching parent region, returning
  tidy parent metadata and optional boundary polylines when
  `extensions = "all"`.

## Installation

You can install the released version of amapGeocode from
[CRAN](https://CRAN.R-project.org/package=amapGeocode) with:

``` r
install.packages("amapGeocode")
```

To install the development version, run following command:

``` r
remotes::install_github('womeimingzi11/amapGeocode')
```

## Usage

### Geocoding

Before start geocoding and reverse geocoding, please apply a [AutoNavi
Map API Key](https://lbs.amap.com/dev/). Set `amap_key` globally by
following command:

Then get results of geocoding, by `getCoord` function.

``` r
library(amapGeocode)
# An individual request
res <- getCoord("四川省博物馆")
knitr::kable(res)
```

| lng | lat | formatted_address | country | province | city | district | township | street | number | citycode | adcode |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 104.0765 | 30.6517 | 四川省 | 中国 | 四川省 | NA | NA | NA | NA | NA | NA | 510000 |

``` r
# Batch requests
res <- getCoord(c("四川省博物馆", "成都市博物馆", "四川省成都市武侯区金楠天街"),
    batch = TRUE)
knitr::kable(res)
```

| lng | lat | formatted_address | country | province | city | district | township | street | number | citycode | adcode |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 104.0765 | 30.65170 | 四川省 | 中国 | 四川省 | NA | NA | NA | NA | NA | NA | 510000 |
| 104.0663 | 30.57296 | 四川省成都市 | 中国 | 四川省 | 成都市 | NA | NA | NA | NA | 028 | 510100 |
| 103.9961 | 30.64860 | 四川省成都市武侯区金楠天街 | 中国 | 四川省 | 成都市 | 武侯区 | NA | 金楠天街 | NA | 028 | 510107 |

Retrieve every candidate for a single query:

``` r
getCoord("四川省博物馆", mode = "all")
```

The responses we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to
[`data.table`](https://CRAN.R-project.org/package=data.table), by
setting `output` argument as `data.table` by default.

If you want to extract information from **JSON** or **XML**. The results
can further be parsed by `extractCoord`.

``` r
# An individual request
res <- getCoord("四川省博物馆", output = "JSON")
res
#> $status
#> [1] "1"
#> 
#> $info
#> [1] "OK"
#> 
#> $infocode
#> [1] "10000"
#> 
#> $count
#> [1] "1"
#> 
#> $geocodes
#> $geocodes[[1]]
#> $geocodes[[1]]$formatted_address
#> [1] "四川省"
#> 
#> $geocodes[[1]]$country
#> [1] "中国"
#> 
#> $geocodes[[1]]$province
#> [1] "四川省"
#> 
#> $geocodes[[1]]$city
#> list()
#> 
#> $geocodes[[1]]$district
#> list()
#> 
#> $geocodes[[1]]$township
#> list()
#> 
#> $geocodes[[1]]$neighborhood
#> $geocodes[[1]]$neighborhood$name
#> list()
#> 
#> $geocodes[[1]]$neighborhood$type
#> list()
#> 
#> 
#> $geocodes[[1]]$building
#> $geocodes[[1]]$building$name
#> list()
#> 
#> $geocodes[[1]]$building$type
#> list()
#> 
#> 
#> $geocodes[[1]]$adcode
#> [1] "510000"
#> 
#> $geocodes[[1]]$street
#> list()
#> 
#> $geocodes[[1]]$number
#> list()
#> 
#> $geocodes[[1]]$location
#> [1] "104.076452,30.651696"
#> 
#> $geocodes[[1]]$level
#> [1] "省"
```

`extractCoord` is created to get a result as a data.table.

``` r
tb <- extractCoord(res)
knitr::kable(tb)
```

| match_rank | lng | lat | formatted_address | country | province | city | district | township | street | number | citycode | adcode | level | matchlevel | neighborhood | neighborhood_type | building | building_type | location | query | query_index |
|---:|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|---:|
| NA | 104.0765 | 30.6517 | 四川省 | 中国 | 四川省 | NA | NA | NA | NA | NA | NA | 510000 | 省 | NA | NA | NA | NA | NA | NA | NA | NA |

### Reverse Geocoding

get results of reverse geocoding, by `getLocation` function.

``` r
res <- getLocation(103.996, 30.6475)
knitr::kable(res)
```

| formatted_address | country | province | city | district | township | citycode | towncode | adcode | street | number | neighborhood | building |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 四川省成都市武侯区晋阳街道晋吉西一街66号龙湖金楠天街C馆 | 中国 | 四川省 | 成都市 | 武侯区 | 晋阳街道 | 028 | 510107011000 | 510107 | 晋吉西一街 | 66号 | NA | NA |

Request extended POI, road, and AOI details (requires
`extensions = "all"`):

``` r
getLocation(103.9960, 30.6475,
           extensions = "all",
           details = c("pois", "roads", "roadinters", "aois"))
```

`extractLocation` is created to get a result as a data.table.

### Get Subordinate Administrative Region

get results of reverse geocoding, by `getAdmin` function.

There is a difference between getAdmin and other function, no matter the
`output` argument is `data.table` or not, the result won’t be a jointed
table by different parent administrative region. For example, with the
`output = data.table`, all the lower level administrative region of
Province A and Province B will be bound as one data.table, respectively.
But the table of province A and table of province B won’t be bound
further.

Because this function supports different administrative region levels,
it is nonsense to bind their results.

``` r
res <- getAdmin(c("四川省", "成都市", "济宁市"))
knitr::kable(res)
```

| parent_name | parent_adcode | parent_level | name | level | citycode | adcode | lng | lat | depth | query |
|:---|:---|:---|:---|:---|:---|:---|---:|---:|---:|:---|
| 四川省 | 510000 | province | 乐山市 | city | 0833 | 511100 | 103.7661 | 29.55228 | 1 | 四川省 |
| 四川省 | 510000 | province | 内江市 | city | 1832 | 511000 | 105.0580 | 29.58021 | 1 | 四川省 |
| 四川省 | 510000 | province | 凉山彝族自治州 | city | 0834 | 513400 | 102.2677 | 27.88140 | 1 | 四川省 |
| 四川省 | 510000 | province | 南充市 | city | 0817 | 511300 | 106.1106 | 30.83723 | 1 | 四川省 |
| 四川省 | 510000 | province | 宜宾市 | city | 0831 | 511500 | 104.6428 | 28.75235 | 1 | 四川省 |
| 四川省 | 510000 | province | 巴中市 | city | 0827 | 511900 | 106.7475 | 31.86785 | 1 | 四川省 |
| 四川省 | 510000 | province | 广元市 | city | 0839 | 510800 | 105.8440 | 32.43577 | 1 | 四川省 |
| 四川省 | 510000 | province | 广安市 | city | 0826 | 511600 | 106.6326 | 30.45635 | 1 | 四川省 |
| 四川省 | 510000 | province | 德阳市 | city | 0838 | 510600 | 104.3978 | 31.12745 | 1 | 四川省 |
| 四川省 | 510000 | province | 成都市 | city | 028 | 510100 | 104.0663 | 30.57296 | 1 | 四川省 |
| 四川省 | 510000 | province | 攀枝花市 | city | 0812 | 510400 | 101.7291 | 26.55864 | 1 | 四川省 |
| 四川省 | 510000 | province | 泸州市 | city | 0830 | 510500 | 105.4419 | 28.87098 | 1 | 四川省 |
| 四川省 | 510000 | province | 甘孜藏族自治州 | city | 0836 | 513300 | 101.9623 | 30.04952 | 1 | 四川省 |
| 四川省 | 510000 | province | 眉山市 | city | 1833 | 511400 | 103.8484 | 30.07711 | 1 | 四川省 |
| 四川省 | 510000 | province | 绵阳市 | city | 0816 | 510700 | 104.6791 | 31.46767 | 1 | 四川省 |
| 四川省 | 510000 | province | 自贡市 | city | 0813 | 510300 | 104.7793 | 29.33924 | 1 | 四川省 |
| 四川省 | 510000 | province | 资阳市 | city | 0832 | 512000 | 104.6273 | 30.12924 | 1 | 四川省 |
| 四川省 | 510000 | province | 达州市 | city | 0818 | 511700 | 107.4678 | 31.20928 | 1 | 四川省 |
| 四川省 | 510000 | province | 遂宁市 | city | 0825 | 510900 | 105.5926 | 30.53268 | 1 | 四川省 |
| 四川省 | 510000 | province | 阿坝藏族羌族自治州 | city | 0837 | 513200 | 102.2245 | 31.89943 | 1 | 四川省 |
| 四川省 | 510000 | province | 雅安市 | city | 0835 | 511800 | 103.0415 | 30.01000 | 1 | 四川省 |
| 成都市 | 510100 | city | 双流区 | district | 028 | 510116 | 103.9234 | 30.57488 | 1 | 成都市 |
| 成都市 | 510100 | city | 大邑县 | district | 028 | 510129 | 103.5123 | 30.57300 | 1 | 成都市 |
| 成都市 | 510100 | city | 崇州市 | district | 028 | 510184 | 103.6730 | 30.63018 | 1 | 成都市 |
| 成都市 | 510100 | city | 彭州市 | district | 028 | 510182 | 103.9577 | 30.99046 | 1 | 成都市 |
| 成都市 | 510100 | city | 成华区 | district | 028 | 510108 | 104.1015 | 30.65997 | 1 | 成都市 |
| 成都市 | 510100 | city | 新津区 | district | 028 | 510118 | 103.8109 | 30.41040 | 1 | 成都市 |
| 成都市 | 510100 | city | 新都区 | district | 028 | 510114 | 104.1586 | 30.82357 | 1 | 成都市 |
| 成都市 | 510100 | city | 武侯区 | district | 028 | 510107 | 104.0432 | 30.64185 | 1 | 成都市 |
| 成都市 | 510100 | city | 温江区 | district | 028 | 510115 | 103.8564 | 30.68196 | 1 | 成都市 |
| 成都市 | 510100 | city | 简阳市 | district | 028 | 510185 | 104.5476 | 30.41094 | 1 | 成都市 |
| 成都市 | 510100 | city | 蒲江县 | district | 028 | 510131 | 103.5065 | 30.19756 | 1 | 成都市 |
| 成都市 | 510100 | city | 邛崃市 | district | 028 | 510183 | 103.4642 | 30.41029 | 1 | 成都市 |
| 成都市 | 510100 | city | 郫都区 | district | 028 | 510117 | 103.9005 | 30.79511 | 1 | 成都市 |
| 成都市 | 510100 | city | 都江堰市 | district | 028 | 510181 | 103.6472 | 30.98876 | 1 | 成都市 |
| 成都市 | 510100 | city | 金堂县 | district | 028 | 510121 | 104.4119 | 30.86203 | 1 | 成都市 |
| 成都市 | 510100 | city | 金牛区 | district | 028 | 510106 | 104.0522 | 30.69136 | 1 | 成都市 |
| 成都市 | 510100 | city | 锦江区 | district | 028 | 510104 | 104.1173 | 30.59873 | 1 | 成都市 |
| 成都市 | 510100 | city | 青白江区 | district | 028 | 510113 | 104.2513 | 30.87860 | 1 | 成都市 |
| 成都市 | 510100 | city | 青羊区 | district | 028 | 510105 | 104.0624 | 30.67458 | 1 | 成都市 |
| 成都市 | 510100 | city | 龙泉驿区 | district | 028 | 510112 | 104.2754 | 30.55681 | 1 | 成都市 |
| 济宁市 | 370800 | city | 任城区 | district | 0537 | 370811 | 116.6058 | 35.44423 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 兖州区 | district | 0537 | 370812 | 116.7836 | 35.55194 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 嘉祥县 | district | 0537 | 370829 | 116.3423 | 35.40794 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 微山县 | district | 0537 | 370826 | 117.1292 | 34.80666 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 曲阜市 | district | 0537 | 370881 | 116.9862 | 35.58193 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 梁山县 | district | 0537 | 370832 | 116.1318 | 35.76596 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 汶上县 | district | 0537 | 370830 | 116.4973 | 35.71189 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 泗水县 | district | 0537 | 370831 | 117.2508 | 35.66472 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 邹城市 | district | 0537 | 370883 | 117.0074 | 35.40254 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 金乡县 | district | 0537 | 370828 | 116.3373 | 35.07342 | 1 | 济宁市 |
| 济宁市 | 370800 | city | 鱼台县 | district | 0537 | 370827 | 116.6505 | 35.01271 | 1 | 济宁市 |

Include boundary polylines (requires `extensions = "all"`):

``` r
getAdmin("四川省", subdistrict = 0,
         extensions = "all", include_polyline = TRUE)
```

`extractAdmin` is created to get results as tibble.

### Convert coordinate point from other coordinate system to AutoNavi

get results of reverse geocoding, by `convertCoord` function, here is
how to convert coordinate from gps to AutoNavi.

**Please not, this is still a very experimental function because I have
no experience at converting coordinates. The implementation of this
input method is not as delicate as I expect. If you have any good idea,
please let me know or just fork repo and pull a reques.**

``` r
res <- convertCoord("103.9960,30.6475", coordsys = "gps")
knitr::kable(res)
```

|      lng |     lat |
|---------:|--------:|
| 103.9983 | 30.6449 |

`extractConvertCoord` is created to get result as data.table.

### Request signing

AutoNavi’s enterprise endpoints can be secured with a digital signature.
Instead of threading the signature through every call, enable signing
globally:

``` r
amap_config(secret = "YOUR-SECRET")
getCoord("四川省博物馆")
```

For temporary scopes, wrap the workflow with `with_amap_signature()`:

``` r
with_amap_signature("YOUR-SECRET", {
  getCoord("四川省博物馆", batch = TRUE)
})
```

## Bug report

It’s very common for API upgrades to make the downstream application,
like amapGeocode,which is unavailable. Feel free to [let me
know](mailto://chenhan28@gmail.com) once it’s broken or just open an
<a class="github-button" href="https://github.com/womeimingzi11/amapGeocode/issues" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" aria-label="Issue womeimingzi11/amapGeocode on GitHub">Issue</a>.

## Acknowledgements

The ongoing development and maintenance of this project are powered by
[Gemini 3](https://deepmind.google/technologies/gemini/).

Hex Sticker was created by [hexSticker
package](https://github.com/GuangchuangYu/hexSticker) with the world
data from
[rnaturalearth](https://CRAN.R-project.org/package=rnaturalearth).

## Code of Conduct

Please note that the amapGeocode project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
