<div id="main" class="col-md-9" role="main">

# join a local data frame to a remote NCBI Gene parquet resource

<div class="ref-description section level2">

join a local data frame to a remote NCBI Gene parquet resource

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
join_ncbi_gene(
  local_df,
  by,
  resource = "gene_info",
  taxid = NULL,
  type = "left"
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   local\_df:

    data.frame to join against the remote resource

-   by:

    character vector of column name(s) to join on; must exist in both
    `local_df` and the remote resource

-   resource:

    character(1) parquet resource name, with or without .parquet suffix;
    must be one of `available_ncbi_parquet()`

-   taxid:

    integer(1) or NULL; when non-NULL, pre-filters the remote resource
    to this taxonomy ID

-   type:

    character(1) "left" (default) or "inner"

</div>

<div class="section level2">

## Value

lazy dplyr::tbl – pipe select/filter/collect as needed

</div>

<div class="section level2">

## Note

local\_df is written to the persistent duckdb session. The returned tbl
is lazy; call collect() to retrieve results. Both sides of the join run
entirely in duckdb.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  local_df <- data.frame(Symbol = c("ORMDL3","TP53","BRCA1"))
  join_ncbi_gene(local_df, by = "Symbol", taxid = 9606L) |>
    dplyr::select(Symbol, GeneID, map_location) |>
    dplyr::collect()
}
#> # A tibble: 3 × 3
#>   Symbol GeneID map_location
#>   <chr>   <dbl> <chr>       
#> 1 TP53     7157 17p13.1     
#> 2 ORMDL3  94103 17q21.1     
#> 3 BRCA1     672 17q21.31    
```

</div>

</div>

</div>
