# Get subordinate administrative regions from keywords

Get subordinate administrative regions from keywords

## Usage

``` r
getAdmin(
  keywords,
  key = NULL,
  subdistrict = NULL,
  page = NULL,
  offset = NULL,
  extensions = NULL,
  filter = NULL,
  callback = NULL,
  output = "tibble",
  keep_bad_request = TRUE,
  include_polyline = FALSE,
  ...
)
```

## Arguments

- keywords:

  Required. Search keywords. Accepts a character vector; each element is
  queried in turn.

- key:

  Optional. AutoNavi API key. You can also set this globally via
  \`options(amap_key = "your-key")\`.

- subdistrict:

  Optional. Subordinate administrative depth (0-3). Defaults to the
  API's behaviour.

- page:

  Optional. Page number when multiple pages are available.

- offset:

  Optional. Maximum records per page (maximum 20).

- extensions:

  Optional. Either \`"base"\` or \`"all"\`. Required for polyline data.

- filter:

  Optional. Filter by designated administrative divisions (adcode).

- callback:

  Optional. JSONP callback. When supplied, the raw response string is
  returned.

- output:

  Optional. Output data structure. Supported values are \`"tibble"\`
  (default), \`"JSON"\`, and \`"XML"\`.

- keep_bad_request:

  Optional. When \`TRUE\` (default) API errors are converted into
  placeholder rows so that batched workflows continue. When \`FALSE\`
  errors are raised as \`amap_api_error\` conditions.

- include_polyline:

  Optional. When \`TRUE\`, and when the request is made with
  \`extensions = "all"\`, polyline strings are included in the parsed
  output.

- ...:

  Optional. Included for forward compatibility only.

## Value

When \`output = "tibble"\`, a \`tibble\` containing administrative
region details is returned. The table preserves the input order and
includes parent metadata (\`parent_name\`, \`parent_adcode\`,
\`parent_level\`) and a \`depth\` column describing the nesting level. A
\`rate_limit\` attribute is attached when rate limit headers are
present. When \`output\` is \`"JSON"\` or \`"XML"\`, the parsed body is
returned without further processing.

## See also

\[extractAdmin()\], \[with_amap_signature()\], \[amap_config()\]

## Examples

``` r
if (FALSE) { # \dontrun{
getAdmin("Sichuan Province", subdistrict = 1)

# Include polylines (requires extensions = "all")
getAdmin("Sichuan Province", subdistrict = 1,
         extensions = "all", include_polyline = TRUE)
} # }
```
