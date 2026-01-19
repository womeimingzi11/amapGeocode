# Extract coordinate from a geocoding response

Extract coordinate from a geocoding response

## Usage

``` r
extractCoord(res)
```

## Arguments

- res:

  Required. Response object returned by \[getCoord()\] with \`output =
  "JSON"\` or by the AutoNavi geocoding API.

## Value

A \`tibble\` with one row per geocode candidate. The table contains the
original columns provided by the API alongside a \`match_rank\` column
that indicates the ordering reported by AutoNavi. When the response does
not contain any matches a single placeholder row filled with \`NA\`
values is returned.

## See also

\[getCoord()\]

## Examples

``` r
if (FALSE) { # \dontrun{
raw <- getCoord("IFS Chengdu", output = "JSON")
extractCoord(raw)
} # }
```
