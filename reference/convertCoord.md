# Convert coordinates to the AutoNavi system

Convert coordinates to the AutoNavi system

## Usage

``` r
convertCoord(
  locations,
  key = NULL,
  coordsys = NULL,
  sig = NULL,
  output = "tibble",
  keep_bad_request = TRUE,
  ...
)
```

## Arguments

- locations:

  Required. Coordinate string(s) to convert. Accepts a character vector.

- key:

  Optional. AutoNavi API key. You can also set this globally via
  \`options(amap_key = "your-key")\`.

- coordsys:

  Optional. Source coordinate system (\`gps\`, \`mapbar\`, \`baidu\`,
  \`autonavi\`).

- sig:

  Optional. Manual digital signature. Most workflows can enable
  automatic signing via \[with_amap_signature()\] or \[amap_config()\].

- output:

  Optional. Output data structure. Supported values are \`"tibble"\`
  (default), \`"JSON"\`, and \`"XML"\`.

- keep_bad_request:

  Optional. When \`TRUE\` (default) API errors are converted into
  placeholder rows so that batched workflows continue. When \`FALSE\`
  errors are raised as \`amap_api_error\` conditions.

- ...:

  Optional. Included for forward compatibility only.

## Value

When \`output = "tibble"\`, a \`tibble\` with columns \`lng\` and
\`lat\` is returned. The table preserves the input order and gains a
\`rate_limit\` attribute containing any rate limit headers returned by
the API. When \`output\` is \`"JSON"\` or \`"XML"\`, the parsed body is
returned without further processing.

## See also

\[extractConvertCoord()\], \[with_amap_signature()\], \[amap_config()\]

## Examples

``` r
if (FALSE) { # \dontrun{
convertCoord("116.481499,39.990475", coordsys = "gps")
} # }
```
