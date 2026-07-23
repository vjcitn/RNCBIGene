<div id="main" class="col-md-9" role="main">

# remove taxon-specific parquets from BiocFileCache

<div class="ref-description section level2">

Deletes local parquet files cached by `cache_by_taxon()`. After calling
this function, `open_ncbi_gene()` will route back to the remote OSN
bucket for the affected taxon.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
clear_taxon_cache(taxid = NULL, cache = .ncbi_cache())
```

</div>

</div>

<div class="section level2">

## Arguments

-   taxid:

    integer(1) or NULL; when NULL removes cached parquets for all taxa

-   cache:

    a `BiocFileCache` object

</div>

<div class="section level2">

## Value

invisibly, the names of the removed cache entries

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
clear_taxon_cache(9606L)   # removes all human cached parquets
#> No live cached entries found.
clear_taxon_cache()        # removes everything cached by cache_by_taxon
#> Removed 1 live cached parquet(s).
```

</div>

</div>

</div>
