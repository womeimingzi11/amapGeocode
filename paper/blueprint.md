# amapGeocode vNext paper blueprint (The R Journal)

Date: 2026-02-10  
Track: Method + software  
Working title: *Reproducible, explainable LBS accessibility analysis for China with amapGeocode*

## 1. Problem statement

Large-scale accessibility studies in China frequently start from messy, ambiguous Chinese addresses and require OD travel-time estimates that respect commercial API rate limits and quotas.

Common pain points:

- **Reproducibility**: repeated runs are expensive and difficult to audit without caching and structured logs.
- **Ambiguity**: geocoding APIs return multiple candidates; “take the top-1” can silently introduce bias.
- **Propagation**: upstream ambiguity can materially change OD matrices and downstream accessibility metrics.

## 2. Contributions (claims to support)

### C1. Reproducible LBS request infrastructure

- Request-level disk cache with TTL + version/query fingerprints.
- JSONL audit log with request IDs, timing, error codes, and cache hits (no plaintext secrets).
- Task-level APIs for tidy workflows with deduplication and stable joins.

### C2. Explainable Chinese address disambiguation

An explainable candidate ranking framework that produces:

- `best`: selected point + confidence + needs-review flag
- `candidates`: scored alternatives
- `diagnostics`: why the decision was made (top-1 vs top-2 gap, triggered rules)

### C3. Quota-aware OD matrix construction and accessibility pipeline

- OD travel-time/distance matrix builder with automatic chunking and cache friendliness.
- Adapter output compatible with `{accessibility}` workflows.

### C4. Uncertainty propagation to accessibility outputs

- Sensitivity/interval summaries showing the impact of top-2 geocode ambiguity on OD and metrics.

## 3. System overview (paper figure)

Figure 1: pipeline diagram

1) Addresses/points → 2) `geocodeData()`/`regeoData()` → 3) candidate resolution (`resolveGeocode()`)  
→ 4) OD matrix (`getOdMatrix()`) → 5) metrics (`{accessibility}` or custom)  
→ 6) uncertainty summaries (`propagateUncertainty()`)  
Cross-cutting: cache + audit logs.

## 4. Methods details (what to describe precisely)

### 4.1 Cache + audit

- Cache key = hash(base_url, endpoint, query fingerprint, pkg version, output/callback, optional key hash scope).
- TTL semantics and expiry handling.
- Audit schema (JSONL fields) and secret redaction.

### 4.2 Candidate resolution

Default “explainable” components (with weights):

- admin constraint score (province/city/district/adcode match or conflict)
- text similarity score (edit-distance similarity against formatted address)
- native rank prior (`1/match_rank`)
- spatial anchor proximity (optional)
- boundary inclusion (optional; `{sf}` suggested)

Confidence definition and `needs_review` threshold.

### 4.3 OD matrix construction

Distance API chunking strategy:

- outer loop: destinations
- inner chunk: up to `max_origins` origins per request

Output schema and error placeholder strategy (never abort whole batch).

### 4.4 Uncertainty propagation

Top-2 sensitivity analysis:

- scenario OD: compute OD for top-1 and top-2 origins
- interval: min/max across scenarios
- expected: softmax-weighted expectation (optional)

## 5. Evaluation plan (tables/figures)

### 5.1 Disambiguation accuracy

Dataset: ambiguous addresses with ground truth (manual labels for a subset).  
Baselines:

- naive: top-1 candidate from API
- constrained: admin-only constraints

Metrics:

- accuracy@1
- needs-review precision/recall (how well it flags uncertain cases)

### 5.2 Cost and performance

Compare with/without cache:

- number of HTTP requests
- wall time
- cache hit rate
- error rate distribution (infocode, HTTP status)

### 5.3 Accessibility sensitivity

Case study (medical accessibility):

- origins: grid/communities
- opportunities: hospitals
- metric: cumulative opportunities within 15 minutes (plus one additional metric if feasible)

Report:

- distribution of accessibility scores
- change in scores under ambiguity scenarios

## 6. Reproducibility package

Deliverables:

- Package vignette: `vignettes/accessibility_medical.Rmd`
- Companion scripts: `inst/scripts/medical_accessibility_case.R`
- Sample inputs: `inst/extdata/*`
- Audit report exporter to CSV/JSON.

## 7. Open decisions (need to lock)

1) Study area city/region (default: Chengdu or Beijing).
2) Origins generation (grid vs community centroids).
3) Hospital source (curated list vs OSM vs official open data).
4) Travel mode (driving/walking/transit) and time thresholds.

