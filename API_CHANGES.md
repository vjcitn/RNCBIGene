# API Changes

Changes to the public API of RNCBIGene.  When a function is added or its
signature changes, record it here and open a corresponding issue in
[pyNCBIGene](https://github.com/vjcitn/pyNCBIGene) to keep the Python
package in sync.

---

## 0.1.x (current)

### Added
- `open_ncbi_gene(resource, taxid, freeze_tag)` -- lazy duckdb tbl over any
  OSN bucket resource; `taxid` drops `#tax_id` column; `freeze_tag` opens a
  frozen snapshot
- `ncbi_gene_fields(resource)` -- column names and types via `DESCRIBE`
- `available_ncbi_parquet()` -- live S3 listing of bucket resources
- `ncbi_parquet_info()` -- sizes, upload dates, NCBI source dates
- `mapIdsNG(taxid, keys, keytype, column)` -- push-down identifier mapping;
  keytypes: Symbol, GeneID, Ensembl
- `join_ncbi_gene(local_df, by, resource, taxid, type)` -- lazy join of local
  data frame to remote resource; validates columns before SQL
- `cache_by_taxon(taxid, resources, force, verbose)` -- filter remote parquet
  to taxon and store in BiocFileCache; subsequent `open_ncbi_gene` calls route
  to local file transparently
- `taxon_cache_info(taxid)` -- list cached entries
- `clear_taxon_cache(taxid)` -- remove live cache entries (frozen entries
  are protected)
- `freeze_taxon_cache(taxid, tag, resources, force)` -- physical snapshot of
  live cache for reproducibility; duplicate tags rejected without `force=TRUE`
- `ncbi_parquet_info()` -- bucket metadata including provenance.json dates

### Behaviour notes
- `open_ncbi_gene()` with `taxid` always drops the taxid column (`#tax_id`
  or `NCBI_tax_id`) from the result
- `gene_refseq_uniprotkb_collab` uses `NCBI_tax_id` as its taxid column;
  all other resources use `#tax_id`
