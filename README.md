# RNCBIGene

Performant and standard representations of gene annotation for all organisms cataloged by NCBI

# Installation

`devtools::install_github("vjcitn/RNCBIGene")`

# Purposes

## Simplified, unified annotation for all organisms addressed by NCBI

The `org.*.*.db` packages are powerful and reliable but have
a complex stack of schemata and scripts for generating organism-specific
packages.

This package works the basis of a one-line transformation to parquet of compressed
text from NCBI.  The parquet files were placed in an NSF Open Storage Network bucket.  

The `geneFromCache` function retrieves and caches the parquet files.

```
> example(geneFromCache)

gnFrmC> gi = geneFromCache("gene_info.parquet")

gnFrmC> arrow::open_dataset(gi) |> dplyr::filter(`#tax_id`==9606) |> head() |> dplyr::collect()
# A tibble: 6 × 16
  `#tax_id` GeneID Symbol LocusTag Synonyms      dbXrefs chromosome map_location
      <int>  <int> <chr>  <chr>    <chr>         <chr>   <chr>      <chr>       
1      9606      1 A1BG   -        A1B|ABG|GAB|… MIM:13… 19         19q13.43    
2      9606      2 A2M    -        A2MD|CPAMD5|… MIM:10… 12         12p13.31    
3      9606      3 A2MP1  -        A2MP          HGNC:H… 12         12p13.31    
4      9606      9 NAT1   -        AAC1|MNAT|NA… MIM:10… 8          8p22        
5      9606     10 NAT2   -        AAC2|NAT-2|P… MIM:61… 8          8p22        
6      9606     11 NATP   -        AACP|NATP1    HGNC:H… 8          8p22        
# ℹ 8 more variables: description <chr>, type_of_gene <chr>,
#   Symbol_from_nomenclature_authority <chr>,
#   Full_name_from_nomenclature_authority <chr>, Nomenclature_status <chr>,
#   Other_designations <chr>, Modification_date <int>, Feature_type <chr>
```

Caching the resources involves transfers of 6GB of parquet; if this is
too laborious, remote queries can be executed for specific needs:

```
> x = remote_gene_query(gres="gene_info", qual='where "#tax_id" = 9606 limit 10')
> x
# A tibble: 10 × 16
   `#tax_id` GeneID Symbol   LocusTag Synonyms   dbXrefs chromosome map_location
       <dbl>  <dbl> <chr>    <chr>    <chr>      <chr>   <chr>      <chr>       
 1      9606      1 A1BG     -        A1B|ABG|G… MIM:13… 19         19q13.43    
 2      9606      2 A2M      -        A2MD|CPAM… MIM:10… 12         12p13.31    
 3      9606      3 A2MP1    -        A2MP       HGNC:H… 12         12p13.31    
 4      9606      9 NAT1     -        AAC1|MNAT… MIM:10… 8          8p22        
 5      9606     10 NAT2     -        AAC2|NAT-… MIM:61… 8          8p22        
 6      9606     11 NATP     -        AACP|NATP1 HGNC:H… 8          8p22        
 7      9606     12 SERPINA3 -        AACT|ACT|… MIM:10… 14         14q32.13    
 8      9606     13 AADAC    -        CES5A1|DAC MIM:60… 3          3q25.1      
 9      9606     14 AAMP     -        -          MIM:60… 2          2q35        
10      9606     15 AANAT    -        DSPS|SNAT  MIM:60… 17         17q25.1     
# ℹ 8 more variables: description <chr>, type_of_gene <chr>,
#   Symbol_from_nomenclature_authority <chr>,
#   Full_name_from_nomenclature_authority <chr>, Nomenclature_status <chr>,
#   Other_designations <chr>, Modification_date <dbl>, Feature_type <chr>
```

## Annotation in a tidyverse style

By retaining the "flat file" model of the original all-organism
annotation content at NCBI, we may more straightforwardly
have access to annotation mappings in tidyverse-style programming.
As an example, given TCGA expression data annotated with gene symbols,
we can add the Gene (Entrez) Ids as follows.

```
> suppressMessages({
+ gbt = curatedTCGAData(diseaseCode="GBM", 
+   assays="RNASeq2GeneNorm", version="2.0.1", dry.run=FALSE,
+   verbose=FALSE)
+ })
> gbtr = experiments(gbt)[[1]]
> library(tidyomics)
> library(RNCBIGene)
> gbtr[1:10,]
# A SummarizedExperiment-tibble abstraction: 1,660 × 2
# Features=10 | Samples=166 | Assays=
   .feature .sample                     
   <chr>    <chr>                       
 1 A1BG     TCGA-02-0047-01A-01R-1849-01
 2 A1CF     TCGA-02-0047-01A-01R-1849-01
 3 A2BP1    TCGA-02-0047-01A-01R-1849-01
 4 A2LD1    TCGA-02-0047-01A-01R-1849-01
 5 A2ML1    TCGA-02-0047-01A-01R-1849-01
 6 A2M      TCGA-02-0047-01A-01R-1849-01
 7 A4GALT   TCGA-02-0047-01A-01R-1849-01
 8 A4GNT    TCGA-02-0047-01A-01R-1849-01
 9 AAA1     TCGA-02-0047-01A-01R-1849-01
10 AAAS     TCGA-02-0047-01A-01R-1849-01
# ℹ 190 more rows
# ℹ Use `print(n = ...)` to see more rows

> gbtr2 = gbtr[1:1000,] |> 
+    mutate(entrez = mapIdsNG(keys=.feature)$GeneID) 
> gbtr2[1:10,]
# A SummarizedExperiment-tibble abstraction: 1,660 × 3
# Features=10 | Samples=166 | Assays=
   .feature .sample                         entrez
   <chr>    <chr>                            <dbl>
 1 A1BG     TCGA-02-0047-01A-01R-1849-01         1
 2 A1CF     TCGA-02-0047-01A-01R-1849-01     29974
 3 A2BP1    TCGA-02-0047-01A-01R-1849-01        NA
 4 A2LD1    TCGA-02-0047-01A-01R-1849-01        NA
 5 A2ML1    TCGA-02-0047-01A-01R-1849-01    144568
 6 A2M      TCGA-02-0047-01A-01R-1849-01         2
 7 A4GALT   TCGA-02-0047-01A-01R-1849-01     53947
 8 A4GNT    TCGA-02-0047-01A-01R-1849-01     51146
 9 AAA1     TCGA-02-0047-01A-01R-1849-01 100329167
10 AAAS     TCGA-02-0047-01A-01R-1849-01      8086
# ℹ 190 more rows
# ℹ Use `print(n = ...)` to see more rows
```

The restriction to the first 1000 features in the example above
arises because an unrestricted attempt fails for a reason
that is currently obscure.

# Available resources

Contents of `https://mghp.osn.xsede.org/bir190004-bucket01/BiocParquetNCBI`,
as retrieved on 22 Feb 2025 and then transformed to parquet (see inst/scripts
for demonstration code):

```
3002338275 2025-05-17 09:28:29.618223689 gene2accession.parquet
680657744 2025-05-15 10:31:33.209868982 gene2go.parquet
 89080561 2025-05-15 10:37:45.825464461 gene2pubmed.parquet
1467468877 2025-05-17 09:28:38.701230380 gene2refseq.parquet
965232147 2025-05-15 10:33:17.845775772 gene_info.parquet
 43279811 2025-05-17 09:28:42.882232368 gene_orthologs.parquet
1019413239 2025-05-17 09:28:47.416233993 gene_refseq_uniprotkb_collab.parquet
```
