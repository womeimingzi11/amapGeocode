
<!-- README.md is generated from README.Rmd. Please edit that file -->

# [amapGeocode](https://github.com/womeimingzi11/amapGeocode)

<img src="man/figures/hexSticker-logo.png" width="150"/>
<!-- badges: start --> <!-- badges: end -->

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
gecoding service, and it provides an interface for the AutoNavi(高德) Maps
API geocoding services. API docs can be found
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

However, AutoNavi has significant high precise, in my case, the Results
from Baidu were unsatisfactory.

## Installation

amapGeocode may be published to [CRAN](https://CRAN.R-project.org) once
the first available version been finished.

For now, please install amapGeocode from GitHub following this command:

``` r
remotes::install_github('womeimingzi11/amapGeocode')
```

<!-- You can install the released version of amapGeocode from [CRAN](https://CRAN.R-project.org) with: -->

<!-- ``` r -->

<!-- install.packages("amapGeocode") -->

<!-- ``` -->

## Usage

### Geocoding

Before start geocoding and reverse geocoding, please apply a [AutoNavi
Map API Key](https://lbs.amap.com/dev/). Set `amap_key` globally by
following command:

Then get result of geocoding, by `getCoord` function.

``` r
library(amapGeocode)
res <-
  getCoord('成都中医药大学')
knitr::kable(res)
```

|      lng |      lat | formatted\_address | country | province | city | district | township | street | number | citycode | adcode |
| -------: | -------: | :----------------- | :------ | :------- | :--- | :------- | :------- | :----- | :----- | :------- | :----- |
| 104.0433 | 30.66686 | 四川省成都市金牛区成都中医药大学   | 中国      | 四川省      | 成都市  | 金牛区      | NA       | NA     | NA     | 028      | 510106 |

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to `tibble`, [a modern reimagining of
the data.frame](https://tibble.tidyverse.org/), by setting `to_table`
argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, please set
`to_table = TRUE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extractCoord`.

``` r
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

`extractCoord` is created to get result as tibble.

``` r
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

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to `tibble`, [a modern reimagining of
the data.frame](https://tibble.tidyverse.org/), by setting `to_table`
argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, please set
`to_table = TRUE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extractLocation`.

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

`extractLocation` is created to get result as tibble.

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

``` r
res <- 
  getAdmin('四川省')
knitr::kable(res)
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

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to `tibble`, [a modern reimagining of
the data.frame](https://tibble.tidyverse.org/), by setting `to_table`
argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, please set
`to_table = TRUE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extractLocation`.

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
to convert coordinate from gps to AutoNavi

``` r
res <- 
  convertCoord('116.481499,39.990475',coordsys = 'gps')
knitr::kable(res)
```

|      lng |      lat |
| -------: | -------: |
| 116.4876 | 39.99175 |

The response we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to `tibble`, [a modern reimagining of
the data.frame](https://tibble.tidyverse.org/), by setting `to_table`
argument as `TRUE` by default.

If anyone want to get response as **JSON** or **XML**, please set
`to_table = TRUE`. If anyone want to extract information from **JSON**
or **XML**. The result can further be parsed by `extract`.

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

`extractConvertCood` is created to get result as tibble.

``` r
tb <- 
  extractConvertCood(res)
knitr::kable(tb)
```

|      lng |      lat |
| -------: | -------: |
| 116.4876 | 39.99175 |

For more functions and improvements, Coming Soon\!

## FAQ

### Can I input a data.frame to have a batch request?

For this moment, it only can be code by yourself manually. However, I
know this is one of the most important feature. So. I am working on it.

### What about parallel?

Unfortunately, there is no plan to add internal parallel support to
amapGeocode. Here are some reasons:

1.  The aim of amapGeocode is to create a package which is easy to use.
    Indeed, the parallel operation can make many times performance
    improvement, especially there are half million queries. However, the
    parallel operation often platform limited, I don’t have enough time
    and machine to test on different platforms. In fact even in macOS,
    the system I’m relatively familiar with, I have already encountered
    a lot of weird parallel issues and I don’t have the intention or the
    experience to fix them.

2.  The queries limitation. For most of free users or developers, the
    daily query limitation and queries per second is absolutely enough:
    30,000 queries per day and 200 queries per second. But for parallel
    operation, the limitation is relatively easy to exceed. For purchase
    developers, it may cause serious financial troubles.

So for anybody who wants to send millions of request by amapGeocode, you
are welcomed to make the parallel operations manually.

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
