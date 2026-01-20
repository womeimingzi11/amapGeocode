## Test environments
* local Windows 11 install, R 4.5.2
* ubuntu-latest (on GitHub Actions), R release
* windows-latest (on GitHub Actions), R release
* macOS-latest (on GitHub Actions), R release

## R CMD check results
There were no ERRORs or WARNINGs.

There was 1 NOTE:
*   checking R code for possible problems ... NOTE
    convertCoord: no visible binding for global variable 'query'
    Undefined global functions or variables:
      query

    This NOTE refers to a non-standard evaluation issue in `dplyr` verbs.
    The variable `query` is dynamically created during the function execution.
    This does not affect the functionality of the package.

## Release Summary
This is a major release (1.0.0) marking API stability and introducing a Shiny GUI.

## Changes
* Added a Shiny Graphical User Interface (GUI) accessible via `amap_gui()`.
* Enhanced error handling and test coverage.
* Improved documentation with new vignettes and pkgdown site.
* Switched default tabular outputs to `tibble` with tidyverse helpers.
* Migrated HTTP stack to `httr2`.
