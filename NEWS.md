# amapGeocode 1.0.0

## Shiny App Enhancements
* **Modular Architecture**: The internal Shiny application has been refactored into modules for better maintainability and scalability.
* **Administrative Region Search**: Added a dedicated GUI panel for querying administrative regions (`getAdmin`).
* **Interactive Map**: Integrated `leaflet` to visualize geocoding, reverse geocoding, and admin search results on an interactive map.
* **Coordinate Conversion**: Improved the UI for converting coordinates between different systems.
* **Dependency Check**: `amap_gui()` now checks for the `leaflet` package in addition to other suggested dependencies.

## Major Changes
* `amapGeocode` now requires R >= 4.1.0.
* Dropped support for older R versions to leverage native pipe `|>` and other modern features.

# amapGeocode 0.9.0
* Added a Shiny Graphical User Interface (GUI) accessible via `amap_gui()`. This interface supports single and batch operations for geocoding, reverse geocoding, and coordinate conversion, along with API configuration.
* Switched default tabular outputs to `tibble` with tidyverse helpers.
* Refined documentation to align with new outputs and pkgdown Bootstrap 5.
* Improved error handling consistency and example stability.

# amapGeocode 0.8.0
* Migrated the HTTP stack to {httr2}, unifying retries, diagnostics, and rate-limit metadata via `amap_request()` and `amap_api_error`.
* Added request signing helpers (`amap_sign()`, `with_amap_signature()`, `amap_config()`) to simplify secure integrations.
* `getCoord()` now supports `mode = "all"` for multi-match results and `batch = TRUE` for 10-at-a-time requests, with `extractCoord()` returning stable columns.
* `getLocation()` gains batching plus optional POI/road/AOI list-columns through the new `details` argument in `extractLocation()`.
* `extractAdmin()` iterates over multiple parents and can emit boundary polylines when `include_polyline = TRUE`.
* Test suite migrated to offline {vcr}/{httptest2} fixtures covering multi-result, extensions, and error scenarios.

# amapGeocode 0.7.0
* Since 0.7.0, the Version of R under 4.1.0 will not support anymore.

# amapGeocode 0.6.0
* Improve the implement of parallel requests 
* Replace `parallel` with `future`

# amapGeocode 0.5.1
* Merge `to_tb` and `output` argument.

# amapGeocode 0.5.0
* Add parallel operation

# amapGeocode 0.4.0
* Return bad request as NA tibble
* Replace `data.table` by `tibble`

# amapGeocode 0.3.1
* Improve the examples of functions

# amapGeocode 0.3.0
* Added ability to batch process requests for `getAdmin()`, `getLocation()`, `getCoord()`, `convertCoord()` functions
* Tag `convertCoord()` as an Experimental function

# amapGeocode 0.2.0
* Add other three main functions: `getAdmin()`, `extractAdmin()` and `convertCoord()`

# amapGeocode 0.1.0

* First release with four functions: `getCoord()`,`extractCoord()`,`getLocation()` and `extractLocation()`
