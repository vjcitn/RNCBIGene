<div id="main" class="col-md-9" role="main">

# freeze a snapshot of taxon-cached parquets for reproducibility

<div class="ref-description section level2">

Copies the current live cached parquets for a taxon into permanent
BiocFileCache entries labelled with an identifying tag. The frozen
copies are independent of the live cache: subsequent `cache_by_taxon()`
or `clear_taxon_cache()` calls do not affect them. Use
`open_ncbi_gene(resource, taxid, freeze_tag=tag)` to query a frozen
snapshot.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
freeze_taxon_cache(
  taxid,
  tag,
  resources = NULL,
  cache = .ncbi_cache(),
  force = FALSE
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   taxid:

    integer(1) NCBI taxonomy ID

-   tag:

    character(1) identifying label for this snapshot; must not already
    exist in the cache unless `force=TRUE`

-   resources:

    character vector of resource names to freeze; defaults to all
    resources currently cached for this taxon

-   cache:

    a `BiocFileCache` object

-   force:

    logical(1) if TRUE, overwrite an existing frozen snapshot with the
    same tag

</div>

<div class="section level2">

## Value

invisibly, a named character vector of frozen local parquet paths

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  cache_by_taxon(10090L, resources = "gene_orthologs")
  freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs",
                     force = TRUE)
  taxon_cache_info(10090L)
}
#>   gene_orthologs: filtering from OSN ...
#> adding rname '/Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/54287e0666d7_file54281f35b13a.parquet'
#>   gene_orthologs_taxid10090.parquet: done
#> adding rname '/Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/5428237044b6_file5428fa13ffe.parquet'
#>   frozen: gene_orthologs_taxid10090_frozen_v1.parquet
#>                                         rname
#> 1           gene_orthologs_taxid10090.parquet
#> 2 gene_orthologs_taxid10090_frozen_v1.parquet
#>                                                                                                      rpath
#> 1 /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/54287e0666d7_file54281f35b13a.parquet
#> 2  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/5428237044b6_file5428fa13ffe.parquet
#>           create_time
#> 1 2026-07-23 13:27:39
#> 2 2026-07-23 13:27:39
```

</div>

</div>

</div>
