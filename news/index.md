# Changelog

## amapGeocode 1.0.0

- This is the first major release of `amapGeocode`, marking API
  stability.
- Added a Shiny Graphical User Interface (GUI) accessible via
  [`amap_gui()`](https://womeimingzi11.github.io/amapGeocode/reference/amap_gui.md).
- Enhanced error handling and test coverage.
- Improved documentation with new vignettes and pkgdown site.

## amapGeocode 0.9.0

CRAN release: 2026-01-19

- Added a Shiny Graphical User Interface (GUI) accessible via
  [`amap_gui()`](https://womeimingzi11.github.io/amapGeocode/reference/amap_gui.md).
  This interface supports single and batch operations for geocoding,
  reverse geocoding, and coordinate conversion, along with API
  configuration.
- Switched default tabular outputs to `tibble` with tidyverse helpers.
- Refined documentation to align with new outputs and pkgdown Bootstrap
  5.
- Improved error handling consistency and example stability.

## amapGeocode 0.8.0

- Migrated the HTTP stack to {httr2}, unifying retries, diagnostics, and
  rate-limit metadata via `amap_request()` and `amap_api_error`.
- Added request signing helpers
  ([`amap_sign()`](https://womeimingzi11.github.io/amapGeocode/reference/amap_sign.md),
  [`with_amap_signature()`](https://womeimingzi11.github.io/amapGeocode/reference/with_amap_signature.md),
  [`amap_config()`](https://womeimingzi11.github.io/amapGeocode/reference/amap_config.md))
  to simplify secure integrations.
- [`getCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/getCoord.md)
  now supports `mode = "all"` for multi-match results and `batch = TRUE`
  for 10-at-a-time requests, with
  [`extractCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/extractCoord.md)
  returning stable columns.
- [`getLocation()`](https://womeimingzi11.github.io/amapGeocode/reference/getLocation.md)
  gains batching plus optional POI/road/AOI list-columns through the new
  `details` argument in
  [`extractLocation()`](https://womeimingzi11.github.io/amapGeocode/reference/extractLocation.md).
- [`extractAdmin()`](https://womeimingzi11.github.io/amapGeocode/reference/extractAdmin.md)
  iterates over multiple parents and can emit boundary polylines when
  `include_polyline = TRUE`.
- Test suite migrated to offline {vcr}/{httptest2} fixtures covering
  multi-result, extensions, and error scenarios.

## amapGeocode 0.7.0

- Since 0.7.0, the Version of R under 4.1.0 will not support anymore.

## amapGeocode 0.6.0

CRAN release: 2021-04-19

- Improve the implement of parallel requests
- Replace `parallel` with `future`

## amapGeocode 0.5.1

- Merge `to_tb` and `output` argument.

## amapGeocode 0.5.0

CRAN release: 2020-11-20

- Add parallel operation

## amapGeocode 0.4.0

CRAN release: 2020-10-17

- Return bad request as NA tibble
- Replace `data.table` by `tibble`

## amapGeocode 0.3.1

CRAN release: 2020-10-01

- Improve the examples of functions

## amapGeocode 0.3.0

- Added ability to batch process requests for
  [`getAdmin()`](https://womeimingzi11.github.io/amapGeocode/reference/getAdmin.md),
  [`getLocation()`](https://womeimingzi11.github.io/amapGeocode/reference/getLocation.md),
  [`getCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/getCoord.md),
  [`convertCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/convertCoord.md)
  functions
- Tag
  [`convertCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/convertCoord.md)
  as an Experimental function

## amapGeocode 0.2.0

- Add other three main functions:
  [`getAdmin()`](https://womeimingzi11.github.io/amapGeocode/reference/getAdmin.md),
  [`extractAdmin()`](https://womeimingzi11.github.io/amapGeocode/reference/extractAdmin.md)
  and
  [`convertCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/convertCoord.md)

## amapGeocode 0.1.0

- First release with four functions:
  [`getCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/getCoord.md),[`extractCoord()`](https://womeimingzi11.github.io/amapGeocode/reference/extractCoord.md),[`getLocation()`](https://womeimingzi11.github.io/amapGeocode/reference/getLocation.md)
  and
  [`extractLocation()`](https://womeimingzi11.github.io/amapGeocode/reference/extractLocation.md)
