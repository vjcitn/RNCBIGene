<div id="main" class="col-md-9" role="main">

# get or create a persistent duckdb connection with httpfs loaded

<div class="ref-description section level2">

The duckdb httpfs extension is cached in a permanent user directory (via
`tools::R_user_dir`) so it is not re-downloaded each session. The
directory can be inspected with
`tools::R_user_dir("RNCBIGene", "data")`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ncbi_gene_con()
```

</div>

</div>

<div class="section level2">

## Value

a DBI connection to an in-process duckdb instance

</div>

</div>
