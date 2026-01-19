# Extract converted coordinates from a conversion response

Extract converted coordinates from a conversion response

## Usage

``` r
extractConvertCoord(res)
```

## Arguments

- res:

  Required. Response object returned by \[convertCoord()\] with \`output
  = "JSON"\` or by the AutoNavi coordinate conversion API.

## Value

A \`tibble\` with columns \`lng\` and \`lat\`. When no data is present a
single placeholder row filled with \`NA\` values is returned.

## See also

\[convertCoord()\]

## Examples

``` r
if (FALSE) { # \dontrun{
raw <- convertCoord("116.481499,39.990475", coordsys = "gps", output = "JSON")
extractConvertCoord(raw)
} # }
```
