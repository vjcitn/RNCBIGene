<div id="main" class="col-md-9" role="main">

# list the fields available for a remote NCBI Gene parquet resource

<div class="ref-description section level2">

Returns the column names and duckdb types for any resource in the OSN
bucket. Useful for discovering what fields can be passed to `select` or
used as `by` keys in `join_ncbi_gene()`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ncbi_gene_fields(resource = "gene_info")
```

</div>

</div>

<div class="section level2">

## Arguments

-   resource:

    character(1) resource name, with or without .parquet suffix

</div>

<div class="section level2">

## Value

data.frame with columns `column_name` and `column_type`

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  ncbi_gene_fields("gene_info")
  ncbi_gene_fields("gene2go")
}
#>   column_name column_type
#> 1     #tax_id      BIGINT
#> 2      GeneID      BIGINT
#> 3       GO_ID     VARCHAR
#> 4    Evidence     VARCHAR
#> 5   Qualifier     VARCHAR
#> 6     GO_term     VARCHAR
#> 7      PubMed     VARCHAR
#> 8    Category     VARCHAR
```

</div>

</div>

</div>
