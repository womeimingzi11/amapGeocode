
<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- Place this tag in your head or just before your close body tag. -->

<!--<script async defer src="https://buttons.github.io/buttons.js"></script>-->

# [amapGeocode](https://github.com/womeimingzi11/amapGeocode)

<!-- badges: start -->

[![Total downloads
badge](https://cranlogs.r-pkg.org/badges/grand-total/amapGeocode?color=blue)](https://CRAN.R-project.org/package=amapGeocode)
[![CRAN
status](https://www.r-pkg.org/badges/version/amapGeocode)](https://CRAN.R-project.org/package=amapGeocode)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Codecov test
coverage](https://codecov.io/gh/womeimingzi11/amapGeocode/branch/master/graph/badge.svg)](https://codecov.io/gh/womeimingzi11/amapGeocode?branch=master)
[![R-CMD-check](https://github.com/womeimingzi11/amapGeocode/workflows/R-CMD-check/badge.svg)](https://github.com/womeimingzi11/amapGeocode/actions)
<!-- badges: end -->

## Introduction <img src="man/figures/hexSticker-logo.png" align="right" width="100" alt="amapGeocode hex sticker"/>

Geocoding and Reverse Geocoding Services are widely used to provide data
about coordinate and location information, including longitude,
latitude, formatted location name, administrative region with different
levels. There are some packages can provide geocode service such as
[tidygeocoder](https://CRAN.R-project.org/package=tidygeocoder),
baidumap, and baidugeo. However, some of them do not always provide
precise information in China, and some of them are unavailable with the
upgrade backend API.

amapGeocode is built to provide high precise geocoding and reverse
geocoding service, and it provides an interface for the AutoNavi(高德)
Maps API geocoding services. API docs can be found
[here](https://lbs.amap.com/) and
[here](https://lbs.amap.com/api/webservice/summary/). Here are two main
functions to use, one is `getCoord()` which needs a character location
name as an input, while the other one is `getLocation()` which needs two
numeric longitude and latitude values as inputs.

The `getCoord()` function extracts coordinate information from input
character location name and outputs the results as `tibble`, `XML` or
`JSON (as list)`. And the `getLocation()` function extracts location
information from input numeric longitude and latitude values and outputs
the results as `tibble`, `XML` or `JSON (as list)`. With the `tibble`
format as output, it’s highly readable and can be used as an alternative
of `data.frame`

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
- `getCoord()` supports `mode = "all"` for multi-match lookups and
  `batch = TRUE` for native AutoNavi 10-at-a-time batching.
- `getLocation()` supports native batching plus rich POI, road,
  intersection, and AOI list-columns via the `details` argument when
  `extensions = "all"`.
- Bulk requests are executed with `httr2::req_perform_parallel()` (curl
  multi; no new R sessions) and protected by default throttling (3
  requests/second). Tune with `amap_config()`.
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

# Respect AutoNavi's documented QPS limit (defaults are already safe).  -
# throttling: 3 req/s - max_active: 3 concurrent requests
amap_config(throttle = TRUE, max_active = 3)

# An individual request
res <- getCoord("四川省博物馆")
knitr::kable(res)

# Batch requests - batch=TRUE uses AutoNavi's native batch mode (up to 10
# addresses per HTTP request) - the package may still issue multiple HTTP
# requests when you have >10 inputs; those requests are executed via curl-multi
# parallelism (no new R sessions)
res <- getCoord(c("四川省博物馆", "成都市博物馆", "四川省成都市武侯区金楠天街"),
    batch = TRUE)
knitr::kable(res)

# Optional tuning (only increase if your key allows it) amap_config(throttle =
# list(rate = 6, fill_time_s = 1), max_active = 6)
```

Retrieve every candidate for a single query:

``` r
getCoord("四川省博物馆", mode = "all")
```

The responses we get from **AutoNavi Map API** is **JSON** or **XML**.
For readability, we transform them to
[`tibble`](https://CRAN.R-project.org/package=tibble), by setting
`output` argument as `tibble` by default.

If you want to extract information from **JSON** or **XML**. The results
can further be parsed by `extractCoord`.

``` r
# An individual request
res <- getCoord("四川省博物馆", output = "JSON")
res
```

`extractCoord` is created to get a result as a tibble.

``` r
tb <- extractCoord(res)
knitr::kable(tb)
```

### Reverse Geocoding

get results of reverse geocoding, by `getLocation` function.

``` r
res <- getLocation(103.996, 30.6475)
knitr::kable(res)
```

Request extended POI, road, and AOI details (requires
`extensions = "all"`):

``` r
getLocation(103.9960, 30.6475,
           extensions = "all",
           details = c("pois", "roads", "roadinters", "aois"))
```

`extractLocation` is created to get a result as a tibble.

### Get Subordinate Administrative Region

get results of reverse geocoding, by `getAdmin` function.

There is a difference between getAdmin and other function, no matter the
`output` argument is `tibble` or not, the result won’t be a jointed
table by different parent administrative region. For example, with the
`output = tibble`, all the lower level administrative region of Province
A and Province B will be bound as one tibble, respectively. But the
table of province A and table of province B won’t be bound further.

Because this function supports different administrative region levels,
it is nonsense to bind their results.

``` r
res <- getAdmin(c("四川省", "成都市", "济宁市"))
knitr::kable(res)
```

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

`extractConvertCoord` is created to get result as tibble.

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
  amap_config(throttle = TRUE, max_active = 3)
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
