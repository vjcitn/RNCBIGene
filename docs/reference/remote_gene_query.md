<div id="main" class="col-md-9" role="main">

# use duckdb to query NCBI Gene data in OSN bucket

<div class="ref-description section level2">

use duckdb to query NCBI Gene data in OSN bucket

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
remote_gene_query(
  gres = "gene2pubmed",
  qual = "limit 5",
  tname = basename(tempfile()),
  collect = FALSE
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   gres:

    name of a gene resource, no suffix

-   qual:

    a SQL fragment used to qualify a select \* clause

-   tname:

    character(1) arbitrary name to use for internal sql table

-   collect:

    logical(1) if TRUE returns a data.frame (legacy behavior); default
    FALSE returns lazy tbl

</div>

<div class="section level2">

## Note

Uses a persistent duckdb connection via ncbi\_gene\_con(). For
composable lazy queries prefer open\_ncbi\_gene().

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  remote_gene_query(qual = 'where "#tax_id" = 9606 limit 10') |> dplyr::collect()
}
#> # A tibble: 10 × 3
#>    `#tax_id` GeneID PubMed_ID
#>        <dbl>  <dbl>     <dbl>
#>  1      9606  23306  25946333
#>  2      9606  23306  26186194
#>  3      9606  23306  26496610
#>  4      9606  23306  27375898
#>  5      9606  23306  28514442
#>  6      9606  23306  28712289
#>  7      9606  23306  29568061
#>  8      9606  23306  29599191
#>  9      9606  23306  29676528
#> 10      9606  23306  30804502
```

</div>

</div>

</div>
