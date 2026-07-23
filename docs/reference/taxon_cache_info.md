<div id="main" class="col-md-9" role="main">

# list taxon-specific parquets stored in BiocFileCache

<div class="ref-description section level2">

list taxon-specific parquets stored in BiocFileCache

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
taxon_cache_info(taxid = NULL, cache = .ncbi_cache())
```

</div>

</div>

<div class="section level2">

## Arguments

-   taxid:

    integer(1) or NULL; when NULL lists all cached taxon parquets

-   cache:

    a `BiocFileCache` object

</div>

<div class="section level2">

## Value

data.frame with columns `rname`, `rpath`, `create_time`

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
taxon_cache_info()
#>                                                             rname
#> 1                     gene_info_taxid9606_frozen_23julVJC.parquet
#> 2                gene_orthologs_taxid9606_frozen_23julVJC.parquet
#> 3  gene_refseq_uniprotkb_collab_taxid9606_frozen_23julVJC.parquet
#> 4                gene2accession_taxid9606_frozen_23julVJC.parquet
#> 5                  gene2ensembl_taxid9606_frozen_23julVJC.parquet
#> 6                       gene2go_taxid9606_frozen_23julVJC.parquet
#> 7                   gene2pubmed_taxid9606_frozen_23julVJC.parquet
#> 8                   gene2refseq_taxid9606_frozen_23julVJC.parquet
#> 9                               gene_orthologs_taxid10090.parquet
#> 10                    gene_orthologs_taxid10090_frozen_v1.parquet
#>                                                                                                         rpath
#> 1  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff4c8c6bd9_file16cff6d816eb9.parquet
#> 2  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff6d735ff4_file16cff22185cc8.parquet
#> 3  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff3563dc8b_file16cff31b837fd.parquet
#> 4  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff4987d819_file16cff7631f3f6.parquet
#> 5  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff2ac55ec6_file16cff3e6a2585.parquet
#> 6  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff7cd5c4d9_file16cff1a6b55eb.parquet
#> 7  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff66e81dc6_file16cff21a921c5.parquet
#> 8   /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff50e05fc_file16cff48502293.parquet
#> 9    /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/54287e0666d7_file54281f35b13a.parquet
#> 10    /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/5428237044b6_file5428fa13ffe.parquet
#>            create_time
#> 1  2026-07-23 12:17:55
#> 2  2026-07-23 12:17:55
#> 3  2026-07-23 12:17:55
#> 4  2026-07-23 12:17:55
#> 5  2026-07-23 12:17:55
#> 6  2026-07-23 12:17:55
#> 7  2026-07-23 12:17:55
#> 8  2026-07-23 12:17:55
#> 9  2026-07-23 13:27:39
#> 10 2026-07-23 13:27:39
```

</div>

</div>

</div>
