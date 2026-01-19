# Extract subordinate administrative regions from a district response

Extract subordinate administrative regions from a district response

## Usage

``` r
extractAdmin(res, include_polyline = FALSE)
```

## Arguments

- res:

  Required. Response object returned by \[getAdmin()\] with \`output =
  "JSON"\` or by the AutoNavi district API.

- include_polyline:

  Logical indicating whether to include the polyline column (requires
  \`extensions = "all"\`). Defaults to \`FALSE\`.

## Value

A \`tibble\` describing each administrative region present in the
response. The table includes parent metadata (\`parent_name\`,
\`parent_adcode\`, \`parent_level\`), centre coordinates (\`lng\`,
\`lat\`), and a \`depth\` column describing the nesting level (0 for the
matched region, 1+ for subregions). When no results are present a single
placeholder row filled with \`NA\` values is returned.

## See also

\[getAdmin()\]

## Examples

``` r
if (FALSE) { # \dontrun{
raw <- getAdmin("Sichuan Province", output = "JSON")
extractAdmin(raw)
} # }
```
