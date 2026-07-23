<div id="main" class="col-md-9" role="main">

# open a lazy dplyr tbl over a remote NCBI Gene parquet resource

<div class="ref-description section level2">

open a lazy dplyr tbl over a remote NCBI Gene parquet resource

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
open_ncbi_gene(resource = "gene_info", taxid = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   resource:

    character(1) parquet resource name, with or without .parquet suffix

-   taxid:

    integer(1) or NULL; when non-NULL, pre-filters to this taxonomy ID
    in SQL

</div>

<div class="section level2">

## Value

lazy dplyr::tbl backed by duckdb – compose filter/select/collect before
pulling data

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  open_ncbi_gene("gene_info", taxid = 9606L) |>
    dplyr::filter(Symbol %in% c("TP53","BRCA1")) |>
    dplyr::select(Symbol, GeneID, map_location) |>
    dplyr::collect()
}
#> # A tibble: 2 × 3
#>   Symbol GeneID map_location
#>   <chr>   <dbl> <chr>       
#> 1 TP53     7157 17p13.1     
#> 2 BRCA1     672 17q21.31    
```

</div>

</div>

</div>
