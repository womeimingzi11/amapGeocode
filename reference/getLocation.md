# Get location from coordinate

Get location from coordinate

## Usage

``` r
getLocation(
  lng,
  lat,
  key = NULL,
  poitype = NULL,
  radius = NULL,
  extensions = NULL,
  roadlevel = NULL,
  sig = NULL,
  output = "tibble",
  callback = NULL,
  homeorcorp = 0,
  keep_bad_request = TRUE,
  batch = FALSE,
  details = NULL,
  ...
)
```

## Arguments

- lng:

  Required. Longitude in decimal degrees. Can be a numeric vector.

- lat:

  Required. Latitude in decimal degrees. Must be the same length as
  \`lng\`.

- key:

  Optional. AutoNavi API key. You can also set this globally via
  \`options(amap_key = "your-key")\`.

- poitype:

  Optional. Return nearby POI types. Only meaningful when \`extensions =
  "all"\`.

- radius:

  Optional. Search radius in metres (0-3000).

- extensions:

  Optional. Either \`"base"\` (default) or \`"all"\` to request extended
  detail payloads.

- roadlevel:

  Optional. Road level filter. Only applies when \`extensions = "all"\`.

- sig:

  Optional. Manual digital signature. Most workflows can enable
  automatic signing via \[with_amap_signature()\] or \[amap_config()\].

- output:

  Optional. Output format. Supported values are \`"tibble"\` (default),
  \`"JSON"\`, and \`"XML"\`.

- callback:

  Optional. JSONP callback. When supplied the raw response string is
  returned.

- homeorcorp:

  Optional. Optimise POI ordering: \`0\` (default) for none, \`1\` for
  home-centric, \`2\` for corporate-centric ordering.

- keep_bad_request:

  Optional. When \`TRUE\` (default) API errors are converted into
  placeholder rows so that batched workflows continue. When \`FALSE\`
  errors are raised as \`amap_api_error\` conditions.

- batch:

  Optional. When \`TRUE\`, requests are chunked into groups of ten
  coordinates using the API's batch mode.

  Bulk requests are executed with \`httr2::req_perform_parallel()\`
  (curl multi; no additional R sessions) and are protected by throttling
  configured via \[amap_config()\].

- details:

  Optional. Character vector describing which extended list-columns to
  include in the parsed output. Supported values are \`"pois"\`,
  \`"roads"\`, \`"roadinters"\`, and \`"aois"\`. Use \`"all"\` to
  include every detail payload. Defaults to \`NULL\`, which omits nested
  payloads.

- ...:

  Optional. Included for forward compatibility only.

## Value

When \`output = "tibble"\`, a \`tibble\` with one row per coordinate is
returned. The table preserves the input order and gains a \`rate_limit\`
attribute containing any rate limit headers returned by the API. When
\`details\` are requested, corresponding list-columns (\`pois\`,
\`roads\`, \`roadinters\`, \`aois\`) contain nested \`tibble\` objects.
When \`output\` is \`"JSON"\` or \`"XML"\`, the parsed body is returned
without further processing.

## See also

\[extractLocation()\], \[with_amap_signature()\], \[amap_config()\]

## Examples

``` r
if (FALSE) { # \dontrun{
getLocation(104.043284, 30.666864)

# Request extended POI details
getLocation(104.043284, 30.666864,
            extensions = "all", details = "pois")

# Batch reverse-geocode ten points at a time
lngs <- rep(104.043284, 12)
lats <- rep(30.666864, 12)
getLocation(lngs, lats, batch = TRUE)
} # }
```
