<div id="main" class="col-md-9" role="main">

# obtain references to parquet serializations of slices of NCBI Gene annotation

<div class="ref-description section level2">

obtain references to parquet serializations of slices of NCBI Gene
annotation

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
NGparq()
```

</div>

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
ng = NGparq()
sapply(ng, nrow)
#>               lit.gene2accession.parquet 
#>                                     3265 
#>                      lit.gene2go.parquet 
#>                                      364 
#>                  lit.gene2pubmed.parquet 
#>                                    15253 
#>                  lit.gene2refseq.parquet 
#>                                      844 
#>                    lit.gene_info.parquet 
#>                                        4 
#>               lit.gene_orthologs.parquet 
#>                                     1546 
#> lit.gene_refseq_uniprotkb_collab.parquet 
#>                                      986 
```

</div>

</div>

</div>
