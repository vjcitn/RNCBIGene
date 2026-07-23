<div id="main" class="col-md-9" role="main">

# filter and cache parquet resources for a single taxon in BiocFileCache

<div class="ref-description section level2">

Performs a one-time download-and-filter of remote NCBI Gene parquet
files to local parquet files stored in BiocFileCache. After calling this
function, `open_ncbi_gene(resource, taxid)` will automatically route to
the local cached file instead of querying the OSN bucket, with no change
to the API.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
cache_by_taxon(
  taxid,
  resources = sub("\\.parquet$", "", available_ncbi_parquet()),
  cache = .ncbi_cache(),
  force = FALSE,
  verbose = TRUE
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   taxid:

    integer(1) NCBI taxonomy ID (e.g. 9606L for human, 10090L for mouse)

-   resources:

    character vector of resource names (without .parquet suffix) to
    cache; defaults to all resources in the bucket

-   cache:

    a `BiocFileCache` object

-   force:

    logical(1) if TRUE, re-download and overwrite existing cache entries

-   verbose:

    logical(1) print progress messages

</div>

<div class="section level2">

## Value

invisibly, a named character vector of local parquet paths

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  # cache only the smallest resource for illustration
  cache_by_taxon(10090L, resources = "gene_orthologs")
  taxon_cache_info(10090L)
}
#>   gene_orthologs_taxid10090.parquet: already cached
#>                                         rname
#> 1           gene_orthologs_taxid10090.parquet
#> 2 gene_orthologs_taxid10090_frozen_v1.parquet
#>                                                                                                      rpath
#> 1 /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/4e1621d7f099_file4e16791e04f6.parquet
#> 2 /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/4e163ca34291_file4e167d25ccb7.parquet
#>           create_time
#> 1 2026-07-23 13:24:37
#> 2 2026-07-23 13:24:37
```

</div>

</div>

</div>
