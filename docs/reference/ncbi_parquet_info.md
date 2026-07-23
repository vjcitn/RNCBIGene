<div id="main" class="col-md-9" role="main">

# retrieve size, upload date, and NCBI source date for each bucket resource

<div class="ref-description section level2">

Reads the OSN bucket S3 listing for file sizes and upload timestamps.
When a `provenance.json` sidecar is present in the bucket (written by
`inst/preps/make_provenance.R`), the NCBI FTP `Last-Modified` date for
each source file is merged in.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ncbi_parquet_info()
```

</div>

</div>

<div class="section level2">

## Value

data.frame with columns `resource`, `size_bytes`, `bucket_modified`, and
`ncbi_last_modified` (NA if provenance not yet available)

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) ncbi_parquet_info()
#>                               resource size_bytes          bucket_modified
#> 1               gene2accession.parquet 3111866681 2026-07-22T19:00:09.796Z
#> 2                 gene2ensembl.parquet  201322528 2026-07-22T19:00:14.050Z
#> 3                      gene2go.parquet  550607120 2026-07-22T19:00:31.108Z
#> 4                  gene2pubmed.parquet  115550070 2026-07-22T19:00:33.657Z
#> 5                  gene2refseq.parquet 1460763355 2026-07-22T19:01:18.313Z
#> 6                    gene_info.parquet  951206411 2026-07-22T19:01:51.231Z
#> 7               gene_orthologs.parquet   62310042 2026-07-22T19:01:54.029Z
#> 8 gene_refseq_uniprotkb_collab.parquet  510820503 2026-07-22T19:02:15.685Z
#>              ncbi_last_modified
#> 1 Wed, 22 Jul 2026 06:04:29 GMT
#> 2 Wed, 22 Jul 2026 06:04:48 GMT
#> 3 Wed, 22 Jul 2026 06:06:46 GMT
#> 4 Wed, 22 Jul 2026 06:07:08 GMT
#> 5 Wed, 22 Jul 2026 06:10:14 GMT
#> 6 Wed, 22 Jul 2026 06:12:27 GMT
#> 7 Wed, 22 Jul 2026 06:14:51 GMT
#> 8 Tue, 21 Jul 2026 09:12:44 GMT
```

</div>

</div>

</div>
