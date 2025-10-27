# AutoNavi Web Service API audit (2024-10)

**Context.** The last CRAN release of `amapGeocode` (0.7.0) predates October 2022. To keep the package healthy we reviewed the AutoNavi (Gaode) Web Service API documentation and public release notes published between 2022-10 and 2024-10, with a focus on the endpoints that this package wraps:

- Geocoding `GET https://restapi.amap.com/v3/geocode/geo`
- Reverse geocoding `GET https://restapi.amap.com/v3/geocode/regeo`
- Administrative district lookup `GET https://restapi.amap.com/v3/config/district`
- Coordinate conversion `GET https://restapi.amap.com/v3/assistant/coordinate/convert`

Primary sources: the official web service reference pages at <https://lbs.amap.com/api/webservice/guide/api/> plus AutoNavi "开放平台" announcement feed under the Web 服务/服务端 类别.

## Breaking change check

| Area | Documentation changes since 2022 | Breaking change risk | Notes for amapGeocode |
| --- | --- | --- | --- |
| Geocoding (`/v3/geocode/geo`) | Parameter list unchanged. Recent doc revisions emphasise using `batch=1` for up to 10 addresses and clarify that `extensions` is not supported. Response schema keeps returning `status`, `info`, `infocode`, `count` (string), `geocodes` list with `location`, `level`, `neighborhood`, `building`. | **Low** – no structural changes, legacy fields retained. | Package only parses one geocode per query and silently drops extra matches when `count > 1`. We should extend extractors to return multiple matches and expose batch mode to reduce request volume. |
| Reverse geocoding (`/v3/geocode/regeo`) | Recent documentation emphasises that the `extensions=all` payload is structured into `pois`, `roads`, `roadinters`, and `aois`, and reiterates the `radius` ≤ 3000 m rule along with a smaller default POI count. | **Low** – field names stable; optional blocks simply omitted when empty. | `extractLocation()` currently discards everything except `formatted_address` and high-level components. Consider exposing nested content via optional tibble columns (pois/roads/aois) so users can access the richer payload now highlighted in docs. |
| Administrative districts (`/v3/config/district`) | Recent documentation clarifies that `extensions=all` returns boundary `polyline` only for the requested node and that child nodes need additional calls. Pagination and `subdistrict` semantics remain the same. | **Low** – response layout still `districts[[i]]$districts`. | Our extractor still returns "Not support current extraction task" when the top-level query matches multiple records (e.g. searching for "Chengdu" without `filter`). We should harden the parser to iterate over `districts` regardless of `count`. |
| Coordinate conversion (`/v3/assistant/coordinate/convert`) | No structural change. Docs reiterate in 2024 that `coordsys` now officially only supports `gps`, `baidu`, `mapbar` and exact GCJ-02 strings; they warn about potential tightening of string validation. | **Low** – same payload (`locations` string). | Implementation already supports the documented systems but does not validate inputs or surface API warnings. Adding an upfront check and clearer error messages would help users prepare for stricter validation. |

### Platform-wide changes to track

- **Security hardening:** AutoNavi continues to promote the server-side "数字签名" (signature) flow (`sig` + `timestamp`). Recent announcements hint at stricter enforcement for high-frequency keys in upcoming cycles. Although optional today, we should provide helpers to compute `sig` from a configurable private key and attach it automatically when users opt in.
- **Quota reporting:** Recent dashboard updates expose per-key quota consumption by endpoint. There is no API contract change, but we may want to surface HTTP response headers (e.g. `X-RateLimit-Remaining` when present) to make rate-limit handling easier downstream.
- **Error codes:** The infocode catalogue has been expanded (e.g. `10034` for "服务权限受限"). Our current error handling simply calls `stop(info)` without preserving the numeric `infocode`; downstream clients could benefit from a structured error object.

## Recommended work for this package

1. **Parser robustness**
   - Update `extractCoord()` to handle `count > 1` by returning one row per `geocode` element, keeping coordinates plus available metadata (`level`, `neighborhood`, `building`).
   - Update `extractAdmin()` to iterate over all districts even when multiple parents are returned; optionally expose `polyline` when `extensions = "all"`.
   - Extend `extractLocation()` with optional columns (controlled by an argument) for POIs, AOIs, roads, and road intersections when users request `extensions = "all"`.

2. **Batching and rate-limit friendliness**
   - Add a `batch` argument to `getCoord()` so that up to 10 addresses can be resolved per HTTP call, matching the upstream recommendation and reducing per-key QPS.
   - Investigate equivalent batching support for reverse geocoding (`/v3/geocode/regeo?batch=1&locations=...`), which can shrink latency for large jobs.

3. **Security opt-ins**
   - Provide utilities (e.g. `with_amap_signature()` or an S3 class) that compute the `sig` parameter given `key`, `sk`, and request params, following the latest signing algorithm.
   - Document how to combine the helper with the existing `key` handling and encourage users with production keys to enable it.

4. **Error and diagnostics improvements**
   - Wrap API failures in custom condition classes carrying `status`, `info`, `infocode`, and the original request, making it easier to debug new upstream error codes.
   - Log or surface rate-limit related headers/infocodes so users can self-throttle.

5. **Documentation refresh**
   - Update Rd files, README, and vignettes to reflect the new optional arguments (`batch`, signature helpers) and to point readers to the 2023–2024 doc clarifications.
   - Add a pkgdown article summarising upstream requirements and recommended usage patterns (parallel limits, batching, security).

6. **QA**
   - Expand `testthat` coverage with recorded fixtures exercising multi-result geocodes, multi-parent district queries, and `extensions = "all"` payloads.
   - Consider adding contract tests guarded by VCR-style caching to detect upstream schema regressions early.

## Conclusion

No immediate breaking changes were detected in the AutoNavi Web Service APIs relied upon by `amapGeocode`, but the documentation refreshes highlight areas where downstream clients are expected to evolve. Implementing the tasks above will bring the package up to date with the 2024 guidance, improve resilience against future tightening (especially around signatures and stricter validation), and unlock functionality that users now expect from the upstream responses.
