# Extract location from coordinate request

Extract location from coordinate request

## Usage

``` r
extractLocation(res, details = NULL)
```

## Arguments

- res:

  Required. Response object returned by \[getLocation()\] with \`output
  = "JSON"\` or by the AutoNavi reverse-geocoding API.

- details:

  Optional. Character vector describing which extended detail payloads
  to parse into list-columns. Valid values are \`"pois"\`, \`"roads"\`,
  \`"roadinters"\`, and \`"aois"\`. Use \`"all"\` to include every
  detail payload.

## Value

A \`tibble\` describing the parsed reverse-geocode results. Each row
corresponds to an element in the API response. When no data is present a
single placeholder row filled with \`NA\` values is returned.

## See also

\[getLocation()\]

## Examples

``` r
if (FALSE) { # \dontrun{
raw <- getLocation(104.043284, 30.666864, output = "JSON")
extractLocation(raw, details = c("pois", "roads"))
} # }
```
