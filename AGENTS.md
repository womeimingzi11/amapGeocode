# amapGeocode Development Guide

## Project Overview

`amapGeocode` is an R package that provides an interface to the AutoNavi
Maps (Amap) API for geocoding and reverse geocoding. It prioritizes
performance and reliability using `httr2` for robust HTTP requests and
`tibble` for tidy data manipulation.

## Development Tools

- **Language**: R (\>= 4.1.0)
- **Documentation**: `roxygen2`
- **Testing**: `testthat`
- **CI**: GitHub Actions (R-CMD-check)

## Operational Commands

### Testing & Quality Assurance

- **Run all tests**:

  ``` r
  devtools::test()
  ```

- **Run a specific test file**:

  ``` r
  testthat::test_file("tests/testthat/test-getCoord.R")
  ```

- **Run a specific test case (by filter)**:

  ``` r
  devtools::test(filter = "pattern")
  ```

- **Run full package check (CRAN standard)**:

  ``` r
  devtools::check()
  # or strict check used in CI
  rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"))
  ```

- **Check code coverage**:

  ``` r
  covr::report() 
  ```

### Build & Documentation

- **Load package state (Simulate install)**:

  ``` r
  devtools::load_all() # Cmd+Shift+L / Ctrl+Shift+L
  ```

- **Regenerate documentation (man/ files)**:

  ``` r
  devtools::document() # Cmd+Shift+D / Ctrl+Shift+D
  ```

- **Install dependencies**:

  ``` r
  remotes::install_deps(dependencies = TRUE)
  ```

## Code Style & Conventions

### General Formatting

- **Indentation**: 2 spaces. Never use tabs.

- **Assignment**: Always use `<-` for assignment, not `=`.

- **Braces**: Opening brace on same line. `else` on same line as closing
  brace.

  ``` r
  if (condition) {
    # code
  } else {
    # code
  }
  ```

### Naming Conventions

- **Public Functions**: Mixed `camelCase` (historical reasons, e.g.,
  `getCoord`, `getLocation`, `extractAdmin`). New public functions
  should generally follow this to maintain consistency.
- **Internal Functions**: `snake_case` (e.g.,
  `normalize_geocode_response`, `perform_request`).
- **Arguments**: `snake_case` (e.g., `keep_bad_request`, `chunk_size`,
  `output`).
- **Variables**: `snake_case`.

### Data Handling

- **tibble**: This is the primary data structure.
  - Use
    [`dplyr::bind_rows`](https://dplyr.tidyverse.org/reference/bind_rows.html)
    for combining results.
  - Use
    [`dplyr::arrange`](https://dplyr.tidyverse.org/reference/arrange.html)/[`dplyr::select`](https://dplyr.tidyverse.org/reference/select.html)
    for ordering and column selection.
  - Ensure `output = "tibble"` is the default behavior.

### Imports & Namespaces

- **Explicit Calls**: Use `package::function()` for imported
  dependencies (e.g.,
  [`rlang::inform`](https://rlang.r-lib.org/reference/abort.html),
  [`jsonlite::fromJSON`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)).
- **Exceptions**: If you add many tidyverse helpers, consider adding
  explicit imports in `NAMESPACE` to reduce `::` noise.

### Error Handling & Logging

- **API Errors**: Use `tryCatch` to handle API failures gracefully.
- **Batch Processing**:
  - Do NOT stop the entire batch on a single failure.
  - Return `NA` or placeholder rows for failed items so input/output
    lengths match.
  - Use
    [`rlang::inform()`](https://rlang.r-lib.org/reference/abort.html)
    for warnings/messages.
- **Conditions**: Use `amap_api_error` class for structured error
  reporting.

## Workflow Rules

1.  **Documentation**: If you change a function signature, run
    `devtools::document()` immediately to update `man/`.
2.  **Tests**: Add tests for new features in `tests/testthat/`.
3.  **News**: Update `NEWS.md` for user-facing changes.

## CI/CD

- GitHub Actions run `R-CMD-check` on Windows, macOS, and Ubuntu.
- Ensure your changes pass `devtools::check()` locally before pushing.
