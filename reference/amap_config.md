# Configure Amap settings

Configure Amap settings

## Usage

``` r
amap_config(
  signature = NULL,
  secret = NULL,
  key = NULL,
  enabled = TRUE,
  max_active = NULL,
  throttle = NULL
)
```

## Arguments

- signature:

  Optional. Signature configuration. Use \`FALSE\` to disable, a single
  string secret, or a list.

- secret:

  Optional. Secret key used for request signing.

- key:

  Optional. Optional API key override when signing is enabled.

- enabled:

  Optional. Logical flag to enable or disable signing.

- max_active:

  Optional. Maximum number of active concurrent HTTP requests when bulk
  operations are executed with \`httr2::req_perform_parallel()\`.
  Defaults to 3.

- throttle:

  Optional. Throttling configuration for outgoing HTTP requests. Use
  \`FALSE\` to disable throttling, \`TRUE\` to enable with defaults, or
  a list with any of the following fields: \`enabled\` (logical),
  \`rate\` (numeric), \`capacity\` (numeric), \`fill_time_s\` (numeric),
  and \`realm\` (character).

  Defaults are safe for AutoNavi's QPS limits: \`max_active = 3\` and
  \`throttle = list(rate = 3, fill_time_s = 1)\`.
