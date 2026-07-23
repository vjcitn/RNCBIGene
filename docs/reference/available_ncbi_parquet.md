<div id="main" class="col-md-9" role="main">

# list parquet resources available in the OSN bucket

<div class="ref-description section level2">

Queries the bucket's S3 listing endpoint and returns the current set of
parquet file names. Requires an internet connection; stops with an
informative message if the request fails.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
available_ncbi_parquet()
```

</div>

</div>

<div class="section level2">

## Value

character vector of parquet file names (e.g. `"gene_info.parquet"`)

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (is_online()) available_ncbi_parquet()
#> [1] "gene2accession.parquet"              
#> [2] "gene2ensembl.parquet"                
#> [3] "gene2go.parquet"                     
#> [4] "gene2pubmed.parquet"                 
#> [5] "gene2refseq.parquet"                 
#> [6] "gene_info.parquet"                   
#> [7] "gene_orthologs.parquet"              
#> [8] "gene_refseq_uniprotkb_collab.parquet"
```

</div>

</div>

</div>
