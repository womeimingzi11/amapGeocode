# Execute code with temporary signature settings

Execute code with temporary signature settings

## Usage

``` r
with_amap_signature(secret, expr, key = NULL, enabled = TRUE)
```

## Arguments

- secret:

  Required. Secret key used for request signing.

- expr:

  Required. Expression to evaluate with signing enabled.

- key:

  Optional. Optional API key override when signing is enabled.

- enabled:

  Optional. Logical flag to enable or disable signing.
