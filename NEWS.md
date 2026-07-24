# RNCBIGene 0.2.0

* `open_ncbi_gene()` now checks BiocFileCache before any network call.
  Users with a cached taxon can work fully offline -- `available_ncbi_parquet()`
  is only called when the remote bucket is actually needed.
* `cached_ncbi_resources()`: new offline-safe function that reads BiocFileCache
  directly and returns a tidy data frame of available resources with columns
  `resource`, `taxid`, `frozen`, `tag`, and `rpath`.
* `_pkgdown.yml` gains an explicit `reference:` block grouping functions by
  purpose (Remote queries, Bucket metadata, Local caching, Session management).
* `NEWS.md` added (Bioconductor requirement).
* `inst/preps/make_provenance.R`: `system("curl -sI ...")` replaced with base R
  `curlGetHeaders()` for cross-platform portability.
* `.gitignore` extended with standard R development detritus.

# RNCBIGene 0.1.9

* Golden-query validation: `tests/testthat/test-golden.R` fetches
  `test_queries.json` from the OSN bucket and validates `mapIdsNG()` and
  `available_ncbi_parquet()` against known-stable results.
* GitHub Actions CI workflow added (`.github/workflows/ci.yml`); responds to
  `repository_dispatch: bucket-updated` events from the upload pipeline.
* `API_CHANGES.md` added to track public API evolution alongside the Python
  companion package pyNCBIGene.
* `_pkgdown.yml` gains an explicit `reference:` block grouping functions by
  purpose.

# RNCBIGene 0.1.8

* Removed `NGparq()`, `processDbx()`, `processDbx1()` and the bundled
  `inst/litparquet/` files -- superseded by the lazy remote query layer.
* Vignette UniProt example rewritten to use `open_ncbi_gene()` against the
  live bucket.

# RNCBIGene 0.1.7

* `inst/preps/test_queries.json`: shared golden-query file, uploaded to the
  bucket by `doall.sh` on each release.
* `inst/preps/GNUmakefile`: new `dispatch` target posts `repository_dispatch`
  to both RNCBIGene and pyNCBIGene GitHub repos after a bucket upload.

# RNCBIGene 0.1.6

* `taxonomyMap()` removed -- unused function and data.
* `org.Hs.eg.db` added to `Suggests`.

# RNCBIGene 0.1.5

* `freeze_taxon_cache(taxid, tag)` and `freeze_tag` parameter on
  `open_ncbi_gene()` for reproducibility snapshots. Frozen entries survive
  `clear_taxon_cache()`.
* Vignette and README sections on caching and reproducibility.

# RNCBIGene 0.1.4

* `clear_taxon_cache(taxid)` removes live cached parquets; frozen snapshots
  are protected.

# RNCBIGene 0.1.3

* `cache_by_taxon(taxid)`: one-time filter of remote parquets to a single
  taxon stored in BiocFileCache. `open_ncbi_gene()` routes transparently to
  local files when a cache entry exists.
* `taxon_cache_info(taxid)`: list cached entries.
* `gene_refseq_uniprotkb_collab` correctly uses `NCBI_tax_id` as its taxid
  column (fix for `cache_by_taxon` crash on that resource).

# RNCBIGene 0.1.2

* `ncbi_gene_fields(resource)`: column names and duckdb types via `DESCRIBE`.
* `open_ncbi_gene()` and `join_ncbi_gene()` validate resource names and join
  columns before SQL construction.
* Session-cached resource name list avoids repeated network calls.

# RNCBIGene 0.1.1

* `#tax_id` column dropped automatically from `open_ncbi_gene()` result when
  `taxid` is specified, preventing `#tax_id.x` / `#tax_id.y` collisions in
  multi-resource joins.
* `freeze_taxon_cache` example uses `force = TRUE` for re-runnability.

# RNCBIGene 0.1.0

* `open_ncbi_gene(resource, taxid, freeze_tag)`: lazy duckdb tbl over any OSN
  bucket resource.
* `mapIdsNG()`: push-down identifier mapping; keytypes Symbol, GeneID, Ensembl.
* `join_ncbi_gene()`: join a local data frame to any remote resource.
* `ncbi_parquet_info()`: bucket metadata with provenance.json support.
* `available_ncbi_parquet()`: live S3 listing of bucket resources.
* Persistent duckdb connection with httpfs cached in
  `tools::R_user_dir("RNCBIGene", "data")`.
* `inst/preps/GNUmakefile`, `to_parquet.R`, `make_provenance.R`,
  `putNCBI.sh`, `doall.sh`: full pipeline from NCBI FTP to OSN bucket.
