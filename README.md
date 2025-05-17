# RNCBIGene

Performant and standard representations of gene annotation for all organisms cataloged by NCBI

# Installation

`devtools::install_github("vjcitn/RNCBIGene")`

# Purpose

Text files from NCBI Gene were transformed to parquet and placed in
an NSF Open Storage Network bucket.  The `geneFromCache` function
retrieves and caches the parquet files.

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

# Available resources

Contents of `https://mghp.osn.xsede.org/bir190004-bucket01/BiocParquetNCBI`:

```
3002338275 2025-05-17 09:28:29.618223689 gene2accession.parquet
680657744 2025-05-15 10:31:33.209868982 gene2go.parquet
 89080561 2025-05-15 10:37:45.825464461 gene2pubmed.parquet
1467468877 2025-05-17 09:28:38.701230380 gene2refseq.parquet
965232147 2025-05-15 10:33:17.845775772 gene_info.parquet
 43279811 2025-05-17 09:28:42.882232368 gene_orthologs.parquet
1019413239 2025-05-17 09:28:47.416233993 gene_refseq_uniprotkb_collab.parquet
```
