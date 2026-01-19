# Launch the amapGeocode Graphical Interface

Launches a Shiny application that provides a graphical user interface
for accessing the functionality of \`amapGeocode\`. The app supports:

- Geocoding (Address to Coordinates) - Single and Batch (CSV)

- Reverse Geocoding (Coordinates to Location) - Single and Batch (CSV)

- Coordinate Conversion - Single and Batch

- Configuration of API Key and Rate Limits

## Usage

``` r
amap_gui()
```

## Value

No return value, called for side effects (launching the application).

## Details

The application requires the following suggested packages: \`shiny\`,
\`bslib\`, \`DT\`, and \`readr\`. If they are not installed, the
function will prompt the user to install them.

## Examples

``` r
if (FALSE) { # \dontrun{
if (interactive()) {
  amap_gui()
}
} # }
```
