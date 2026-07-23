<div id="main" class="col-md-9" role="main">

# analog of mapIds from AnnotationDbi using lazy duckdb queries on NCBI Gene parquet

<div class="ref-description section level2">

analog of mapIds from AnnotationDbi using lazy duckdb queries on NCBI
Gene parquet

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
mapIdsNG(
  taxid = 9606L,
  keys = c("ORMDL3", "TP53", "GSDMB", "XyZZY"),
  keytype = "Symbol",
  column = "GeneID"
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   taxid:

    integer(1) taxonomy code, defaults to 9606L for Homo sapiens

-   keys:

    character vector of keys to translate

-   keytype:

    character(1) one of "Symbol", "GeneID", or "Ensembl"

-   column:

    character(1) name of the output annotation column; use "Ensembl" to
    retrieve Ensembl gene identifiers via gene2ensembl.parquet

</div>

<div class="section level2">

## Note

All filtering is pushed to duckdb before a single collect() retrieves
only the matched rows and columns. Ensembl keytype or column requires
gene2ensembl.parquet in the OSN bucket.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) {
  mapIdsNG()
}
#> ORMDL3   TP53  GSDMB  XyZZY 
#>  94103   7157  55876     NA 
```

</div>

</div>

</div>
