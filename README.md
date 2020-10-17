
<!-- README.md is generated from README.Rmd. Please edit that file -->

# [amapGeocode](https://github.com/womeimingzi11/amapGeocode)

<!-- badges: start -->

[![Total downloads
badge](https://cranlogs.r-pkg.org/badges/grand-total/amapGeocode?color=blue)](https://CRAN.R-project.org/package=amapGeocode)
[![CRAN
status](https://www.r-pkg.org/badges/version/amapGeocode)](https://CRAN.R-project.org/package=amapGeocode)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/297431889.svg)](https://zenodo.org/badge/latestdoi/297431889)
<!-- badges: end -->

中文版介绍:
[博客](https://blog.washman.top/post/amapgeocode-%E4%BD%BF%E7%94%A8r%E8%BF%9B%E8%A1%8C%E9%AB%98%E5%BE%B7%E5%9C%B0%E5%9B%BE%E5%9C%B0%E7%90%86%E7%BC%96%E7%A0%81-%E9%80%86%E7%BC%96%E7%A0%81.zh-hans/)
or [知乎](https://zhuanlan.zhihu.com/p/264281505)

## Introduction <img src="man/figures/hexSticker-logo.png" align="right" width="100"/>

Geocoding and Reverse Geocoding Services are widely used to provide data
about coordinate and location information, including longitude,
latitude, formatted location name, administrative region with different
levels. There are some package can provide geocode service such as
[tidygeocoder](https://CRAN.R-project.org/package=tidygeocoder),
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). However, some of them
not always provide precise information in China, and some of them is
unavailable with upgrade backend API.

amapGeocode is built to provide high precise geocoding and reverse
geocoding service, and it provides an interface for the AutoNavi(高德)
Maps API geocoding services. API docs can be found
[here](https://lbs.amap.com/) and
[here](https://lbs.amap.com/api/webservice/summary/). Here are two main
functions to use are `getCoord()` which takes a character location name
as an input and `getLocation()` which takes two numeric longitude and
latitude values as inputs.

The `getCoord()` function extracts coordinate information from input
character location name and output the result as `data.table`, `XML` or
`JSON (as list)`. And the `getLocation()` function extracts location
information from input numeric longitude and latitude values and output
the result as `data.table`, `XML` or `JSON (as list)`. With the
`data.table` format as output, it’s highly readable and can be used as
an alternative of `data.frame`

amapGeocode is inspired by
[baidumap](https://github.com/badbye/baidumap) and
[baidugeo](https://github.com/ChrisMuir/baidugeo). If you want to choose
the Baidu Map API, these packages are good choice.

However, AutoNavi has significant high precise, in my case, the Results
from Baidu were unsatisfactory.

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

Then get result of geocoding, by `getCoord` function.

``` r
library(amapGeocode)
# An individual request
res <-
  getCoord('四川省中医院')
knitr::kable(res)
```

|      lng |     lat | formatted\_address | country | province | city | district | township | street | number | citycode | adcode |
| -------: | ------: | :----------------- | :------ | :------- | :--- | :------- | :------- | :----- | :----- | :------- | :----- |
| 104.0431 | 30.6678 | 四川省成都市金牛区四川省中医院    | 中国      | 四川省      | 成都市  | 金牛区      | NA       | NA     | NA     | 028      | 510106 |

``` r
# Batch requests
res <-
  getCoord(c('四川省中医院',
             '四川省人民医院',
             '成都中医药大学十二桥校区'))
knitr::kable(res)
```

|      lng |      lat | formatted\_address    | country | province | city | district | township | street | number | citycode | adcode |
| -------: | -------: | :-------------------- | :------ | :------- | :--- | :------- | :------- | :----- | :----- | :------- | :----- |
| 104.0431 | 30.66780 | 四川省成都市金牛区四川省中医院       | 中国      | 四川省      | 成都市  | 金牛区      | NA       | NA     | NA     | 028      | 510106 |
| 104.0390 | 30.66362 | 四川省成都市青羊区四川省人民医院      | 中国      | 四川省      | 成都市  | 青羊区      | NA       | NA     | NA     | 028      | 510105 |
| 104.0439 | 30.66629 | 四川省成都市金牛区成都中医药大学十二桥校区 | 中国      | 四川省      | 成都市  | 金牛区      | NA       | NA     | NA     | 028      | 510106 |

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to
[`data.table`](https://CRAN.R-project.org/package=data.table), by
setting `to_table` argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, just set
`to_table = FALSE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extractCoord`.

``` r
# An individual request
res <-
  getCoord('成都中医药大学', output = 'XML',to_table = FALSE)
res
#> {xml_document}
#> <response>
#> [1] <status>1</status>
#> [2] <info>OK</info>
#> [3] <infocode>10000</infocode>
#> [4] <count>1</count>
#> [5] <geocodes type="list">\n  <geocode>\n    <formatted_address>四川省成都市金牛区成都中医 ...
```

`extractCoord` is created to get a result as a data.table.

``` r
tb <- 
  extractCoord(res)
knitr::kable(tb)
```

|      lng |      lat | formatted\_address | country | province | city | district | township | street | number | citycode | adcode |
| -------: | -------: | :----------------- | :------ | :------- | :--- | :------- | :------- | :----- | :----- | :------- | :----- |
| 104.0433 | 30.66686 | 四川省成都市金牛区成都中医药大学   | 中国      | 四川省      | 成都市  | 金牛区      | NA       | NA     | NA     | 028      | 510106 |

### Reverse Geocoding

get result of reverse geocoding, by `getLocation` function.

``` r
res <- 
  getLocation(104.043284, 30.666864)
knitr::kable(res)
```

| formatted\_address                          | country | province | city | district | township | citycode | towncode     |
| :------------------------------------------ | :------ | :------- | :--- | :------- | :------- | :------- | :----------- |
| 四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二桥校区) | 中国      | 四川省      | 成都市  | 金牛区      | 西安路街道    | 028      | 510106024000 |

``` r
res <-
   getLocation(104.043284, 30.666864, output = 'XML',to_table = FALSE)
res
#> {xml_document}
#> <response>
#> [1] <status>1</status>
#> [2] <info>OK</info>
#> [3] <infocode>10000</infocode>
#> [4] <regeocode>\n  <formatted_address>四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二 ...
```

`extractLocation` is created to get a result as a data.table.

``` r
tb <- 
  extractLocation(res)
knitr::kable(tb)
```

| formatted\_address                          | country | province | city | district | township | citycode | towncode     |
| :------------------------------------------ | :------ | :------- | :--- | :------- | :------- | :------- | :----------- |
| 四川省成都市金牛区西安路街道成都中医药大学附属医院腹泻门诊成都中医药大学(十二桥校区) | 中国      | 四川省      | 成都市  | 金牛区      | 西安路街道    | 028      | 510106024000 |

### Get Subordinate Administrative Region

get result of reverse geocoding, by `getAdmin` function.

There is a difference between getAdmin and other function, no matter the
`to_table` argument is `TRUE` or `FALSE` the result won’t be a jointed
table by different parent administrative region. For example, with the
`to_table = TRUE`, all the lower level administrative region of Province
A and Province B will be binded as one data.table, respectively. But the
table of province A and table of province B won’t be binded further.

This is becasue, this function support different administrative region
levels, bind their result is nonsense.

``` r
res <-
  getAdmin(c('四川省','成都市','济宁市'))
knitr::kable(res)
```

<table class="kable_wrapper">

<tbody>

<tr>

<td>

|      lng |      lat | name      | level | citycode | adcode |
| -------: | -------: | :-------- | :---- | :------- | :----- |
| 106.7537 | 31.85881 | 巴中市       | city  | 0827     | 511900 |
| 104.0657 | 30.65946 | 成都市       | city  | 028      | 510100 |
| 104.3987 | 31.12799 | 德阳市       | city  | 0838     | 510600 |
| 105.8298 | 32.43367 | 广元市       | city  | 0839     | 510800 |
| 105.5713 | 30.51331 | 遂宁市       | city  | 0825     | 510900 |
| 104.6419 | 30.12221 | 资阳市       | city  | 0832     | 512000 |
| 104.7417 | 31.46402 | 绵阳市       | city  | 0816     | 510700 |
| 106.6334 | 30.45640 | 广安市       | city  | 0826     | 511600 |
| 107.5023 | 31.20948 | 达州市       | city  | 0818     | 511700 |
| 106.0830 | 30.79528 | 南充市       | city  | 0817     | 511300 |
| 105.0661 | 29.58708 | 内江市       | city  | 1832     | 511000 |
| 104.6308 | 28.76019 | 宜宾市       | city  | 0831     | 511500 |
| 105.4433 | 28.88914 | 泸州市       | city  | 0830     | 510500 |
| 102.2214 | 31.89979 | 阿坝藏族羌族自治州 | city  | 0837     | 513200 |
| 104.7734 | 29.35277 | 自贡市       | city  | 0813     | 510300 |
| 103.0010 | 29.98772 | 雅安市       | city  | 0835     | 511800 |
| 103.8318 | 30.04832 | 眉山市       | city  | 1833     | 511400 |
| 103.7613 | 29.58202 | 乐山市       | city  | 0833     | 511100 |
| 101.7160 | 26.58045 | 攀枝花市      | city  | 0812     | 510400 |
| 102.2587 | 27.88676 | 凉山彝族自治州   | city  | 0834     | 513400 |
| 101.9638 | 30.05066 | 甘孜藏族自治州   | city  | 0836     | 513300 |

</td>

<td>

|      lng |      lat | name | level    | citycode | adcode |
| -------: | -------: | :--- | :------- | :------- | :----- |
| 103.9412 | 30.98516 | 彭州市  | district | 028      | 510182 |
| 103.6279 | 30.99114 | 都江堰市 | district | 028      | 510181 |
| 103.5224 | 30.58660 | 大邑县  | district | 028      | 510129 |
| 103.5115 | 30.19436 | 蒲江县  | district | 028      | 510131 |
| 104.2549 | 30.88344 | 青白江区 | district | 028      | 510113 |
| 104.5503 | 30.39067 | 简阳市  | district | 028      | 510185 |
| 103.6710 | 30.63148 | 崇州市  | district | 028      | 510184 |
| 104.4156 | 30.85842 | 金堂县  | district | 028      | 510121 |
| 103.4614 | 30.41327 | 邛崃市  | district | 028      | 510183 |
| 103.8124 | 30.41428 | 新津区  | district | 028      | 510132 |
| 103.8368 | 30.69800 | 温江区  | district | 028      | 510115 |
| 103.8878 | 30.80875 | 郫都区  | district | 028      | 510117 |
| 103.9227 | 30.57324 | 双流区  | district | 028      | 510116 |
| 104.0517 | 30.63086 | 武侯区  | district | 028      | 510107 |
| 104.0435 | 30.69206 | 金牛区  | district | 028      | 510106 |
| 104.1602 | 30.82422 | 新都区  | district | 028      | 510114 |
| 104.2692 | 30.56065 | 龙泉驿区 | district | 028      | 510112 |
| 104.1031 | 30.66027 | 成华区  | district | 028      | 510108 |
| 104.0557 | 30.66765 | 青羊区  | district | 028      | 510105 |
| 104.0810 | 30.65769 | 锦江区  | district | 028      | 510104 |

</td>

<td>

|      lng |      lat | name | level    | citycode | adcode |
| -------: | -------: | :--- | :------- | :------- | :----- |
| 116.4871 | 35.72175 | 汶上县  | district | 0537     | 370830 |
| 116.9667 | 35.40526 | 邹城市  | district | 0537     | 370883 |
| 117.2736 | 35.65322 | 泗水县  | district | 0537     | 370831 |
| 116.9919 | 35.59279 | 曲阜市  | district | 0537     | 370881 |
| 116.5953 | 35.41483 | 任城区  | district | 0537     | 370811 |
| 116.3429 | 35.39810 | 嘉祥县  | district | 0537     | 370829 |
| 116.0896 | 35.80184 | 梁山县  | district | 0537     | 370832 |
| 116.6500 | 34.99771 | 鱼台县  | district | 0537     | 370827 |
| 116.3104 | 35.06977 | 金乡县  | district | 0537     | 370828 |
| 117.1286 | 34.80953 | 微山县  | district | 0537     | 370826 |
| 116.8290 | 35.55644 | 兖州区  | district | 0537     | 370812 |

</td>

</tr>

</tbody>

</table>

``` r
res <-
   getAdmin('四川省', output = 'XML', to_table = FALSE)
res
#> {xml_document}
#> <response>
#> [1] <status>1</status>
#> [2] <info>OK</info>
#> [3] <infocode>10000</infocode>
#> [4] <count>1</count>
#> [5] <suggestion>\n  <keywords type="list"/>\n  <cities type="list"/>\n</sugge ...
#> [6] <districts type="list">\n  <district>\n    <citycode/>\n    <adcode>51000 ...
```

`extractAdmin` is created to get result as tibble.

``` r
res
#> {xml_document}
#> <response>
#> [1] <status>1</status>
#> [2] <info>OK</info>
#> [3] <infocode>10000</infocode>
#> [4] <count>1</count>
#> [5] <suggestion>\n  <keywords type="list"/>\n  <cities type="list"/>\n</sugge ...
#> [6] <districts type="list">\n  <district>\n    <citycode/>\n    <adcode>51000 ...
tb <- 
  extractAdmin(res)
knitr::kable(tb)
```

|      lng |      lat | name      | level | citycode | adcode |
| -------: | -------: | :-------- | :---- | :------- | :----- |
| 106.7537 | 31.85881 | 巴中市       | city  | 0827     | 511900 |
| 104.0657 | 30.65946 | 成都市       | city  | 028      | 510100 |
| 104.3987 | 31.12799 | 德阳市       | city  | 0838     | 510600 |
| 105.8298 | 32.43367 | 广元市       | city  | 0839     | 510800 |
| 105.5713 | 30.51331 | 遂宁市       | city  | 0825     | 510900 |
| 104.6419 | 30.12221 | 资阳市       | city  | 0832     | 512000 |
| 104.7417 | 31.46402 | 绵阳市       | city  | 0816     | 510700 |
| 106.6334 | 30.45640 | 广安市       | city  | 0826     | 511600 |
| 107.5023 | 31.20948 | 达州市       | city  | 0818     | 511700 |
| 106.0830 | 30.79528 | 南充市       | city  | 0817     | 511300 |
| 105.0661 | 29.58708 | 内江市       | city  | 1832     | 511000 |
| 104.6308 | 28.76019 | 宜宾市       | city  | 0831     | 511500 |
| 105.4433 | 28.88914 | 泸州市       | city  | 0830     | 510500 |
| 102.2214 | 31.89979 | 阿坝藏族羌族自治州 | city  | 0837     | 513200 |
| 104.7734 | 29.35277 | 自贡市       | city  | 0813     | 510300 |
| 103.0010 | 29.98772 | 雅安市       | city  | 0835     | 511800 |
| 103.8318 | 30.04832 | 眉山市       | city  | 1833     | 511400 |
| 103.7613 | 29.58202 | 乐山市       | city  | 0833     | 511100 |
| 101.7160 | 26.58045 | 攀枝花市      | city  | 0812     | 510400 |
| 102.2587 | 27.88676 | 凉山彝族自治州   | city  | 0834     | 513400 |
| 101.9638 | 30.05066 | 甘孜藏族自治州   | city  | 0836     | 513300 |

### Convert coordinate point from other coordinate system to AutoNavi

get result of reverse geocoding, by `convertCoord` function, here is how
to convert coordinate from gps to AutoNavi.

**Please not, this is still a very experimental function because I have
no experience at converting coordinates. The implementation of this
input method is not as delicate as I expect. If you have any good idea,
please let me know or just fork repo and pull a reques.**

``` r
res <- 
  convertCoord('116.481499,39.990475',coordsys = 'gps')
knitr::kable(res)
```

|      lng |      lat |
| -------: | -------: |
| 116.4876 | 39.99175 |

``` r
res <-
  convertCoord('116.481499,39.990475',coordsys = 'gps', to_table = FALSE)
res
#> $status
#> [1] "1"
#> 
#> $info
#> [1] "ok"
#> 
#> $infocode
#> [1] "10000"
#> 
#> $locations
#> [1] "116.487585177952,39.991754014757"
```

`extractConvertCoord` is created to get result as data.table.

``` r
tb <- 
  extractConvertCoord(res)
knitr::kable(tb)
```

|      lng |      lat |
| -------: | -------: |
| 116.4876 | 39.99175 |

For more functions and improvements, Coming Soon\!

## FAQ

### Can I input a data.frame to have a batch request?

Yes\! Feel free to input a list, a vector and a column of a table as
what you do in other packages.

### What about parallel?

I have changed my mind\! It should come someday. ~~Unfortunately, there
is no plan to add internal parallel support to amapGeocode. Here are
some reasons:~~

~~1. The aim of amapGeocode is to create a package which is easy to use.
Indeed, the parallel operation can make many times performance
improvement, especially there are half million queries. However, the
parallel operation often platform limited, I don’t have enough time and
machine to test on different platforms. In fact even in macOS, the
system I’m relatively familiar with, I have already encountered a lot of
weird parallel issues and I don’t have the intention or the experience
to fix them.~~

~~2. The queries limitation. For most of free users or developers, the
daily query limitation and queries per second is absolutely enough:
30,000 queries per day and 200 queries per second. But for parallel
operation, the limitation is relatively easy to exceed. For purchase
developers, it may cause serious financial troubles.~~

~~So for anybody who wants to send millions of request by amapGeocode,
you are welcomed to make the parallel operations manually.~~

## Bug report

It’s very common for API upgrades to make the downstream application,
like amapGeocode, to be unavailable. Feel free to [let me
know](mailto://chenhan28@gmail.com) once it’s broken or just open an
issue.

## Acknowledgements

Hex Sticker was created by [hexSticker
package](https://github.com/GuangchuangYu/hexSticker) with the world
data from
[rnaturalearth](https://CRAN.R-project.org/package=rnaturalearth).
