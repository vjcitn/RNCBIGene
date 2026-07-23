<div id="main" class="col-md-9" role="main">

# RNCBIGene: NCBI Gene annotation in parquet

<div class="section level2">

## Introduction

Bioconductor’s annotation system has functioned for well over a decade
as a pivotal resource for analysis and tool development. See the
[AnnotationDbi](https://bioconductor.org/packages/AnnotationDbi)
documentation for details. AnnotationDbi and packages based on it use
SQLite to manage organism-specific vocabularies and to resolve queries
about mappings between identifier sets. For example, learn the Gene
Ontology annotations for gene ORMDL3 in *Homo sapiens*:

<div id="cb1" class="sourceCode">

``` r
library(org.Hs.eg.db)
go_orm = AnnotationDbi::select(org.Hs.eg.db, key="ORMDL3", keytype="SYMBOL",
    columns=c("GO", "ENTREZID"))
head(go_orm)
```

</div>

    ##   SYMBOL         GO EVIDENCE ONTOLOGY ENTREZID
    ## 1 ORMDL3 GO:0002903      IMP       BP    94103
    ## 2 ORMDL3 GO:0005515      IPI       MF    94103
    ## 3 ORMDL3 GO:0005783      IDA       CC    94103
    ## 4 ORMDL3 GO:0005789      IEA       CC    94103
    ## 5 ORMDL3 GO:0005886      TAS       CC    94103
    ## 6 ORMDL3 GO:0006665      IEA       BP    94103

RNCBIGene takes a different approach: instead of organism-specific
SQLite databases, all NCBI Gene annotation for all organisms lives in a
set of Apache Parquet files on an NSF Open Storage Network bucket.
Queries run through a persistent duckdb connection that reads remote
parquet directly, pushing filters and column selections to the network
layer before any data lands in R. The `open_ncbi_gene()` function
returns a lazy `dplyr::tbl`; the user composes `filter()`, `select()`,
and `collect()` calls as they would with any remote dplyr backend.

The duckdb `httpfs` extension required for remote parquet access is
cached permanently in `tools::R_user_dir("RNCBIGene", "data")` rather
than a temporary directory, so it is downloaded only once per machine.
The cache location can be overridden by setting the
`DUCKDB_EXTENSION_DIRECTORY` environment variable before loading the
package.

<div id="cb3" class="sourceCode">

``` r
library(RNCBIGene)
library(dplyr)
lkor = open_ncbi_gene("gene2go", taxid=9606L) |>
  filter(GeneID==94103) |> collect() |> as.data.frame()
DT::datatable(lkor)
```

</div>

<div id="htmlwidget-ac96cb3ee4656e2e9ec3"
class="datatables html-widget html-fill-item"
style="width:100%;height:auto;">

</div>

It is not the purpose of this package to provide pin-compatible
replacements for the AnnotationDbi packages. This package explores the
opportunities for simplification and performance enhancement arising
from the adoption of Parquet and Arrow for annotation representation and
interrogation.

</div>

<div class="section level2">

## Scope

There are eight parquet files representing NCBI Gene content. Seven were
built from May 2025 NCBI snapshots; `gene2ensembl` was added to support
clean Ensembl identifier lookups.

<div id="cb4" class="sourceCode">

``` r
tryCatch(
  available_ncbi_parquet(),
  error = function(e) message(conditionMessage(e))
)
```

</div>

    ## [1] "gene_info.parquet"                   
    ## [2] "gene_orthologs.parquet"              
    ## [3] "gene_refseq_uniprotkb_collab.parquet"
    ## [4] "gene2accession.parquet"              
    ## [5] "gene2ensembl.parquet"                
    ## [6] "gene2go.parquet"                     
    ## [7] "gene2pubmed.parquet"                 
    ## [8] "gene2refseq.parquet"

All resources can be queried simultaneously through the persistent
duckdb connection. Record counts are retrieved by pushing `COUNT(*)` to
duckdb, which reads row-group metadata from parquet without fetching the
data itself.

<div id="cb6" class="sourceCode">

``` r
tryCatch({
  resources <- available_ncbi_parquet()
  counts <- vapply(
    sub("\\.parquet$", "", resources),
    function(r) open_ncbi_gene(r) |> dplyr::tally() |> dplyr::collect() |> dplyr::pull(n),
    numeric(1))
  setNames(counts, resources)
}, error = function(e) message(conditionMessage(e)))
```

</div>

    ##                    gene_info.parquet               gene_orthologs.parquet 
    ##                             70797156                             18590068 
    ## gene_refseq_uniprotkb_collab.parquet               gene2accession.parquet 
    ##                            124490938                            282519101 
    ##                 gene2ensembl.parquet                      gene2go.parquet 
    ##                             18069267                            122971050 
    ##                  gene2pubmed.parquet                  gene2refseq.parquet 
    ##                             79863715                            106157713

For illustration, a small subset covering four human genes on chromosome
17 is bundled with the package.

<div id="cb8" class="sourceCode">

``` r
litp = dir(system.file("litparquet", package="RNCBIGene"), full.names=TRUE)
litpop = lapply(litp, arrow::open_dataset)
ns = basename(litp)
names(litpop) = ns
sapply(litpop, nrow)
```

</div>

    ##                    lit.gene_info.parquet 
    ##                                        4 
    ##               lit.gene_orthologs.parquet 
    ##                                     1546 
    ## lit.gene_refseq_uniprotkb_collab.parquet 
    ##                                      986 
    ##               lit.gene2accession.parquet 
    ##                                     3265 
    ##                      lit.gene2go.parquet 
    ##                                      364 
    ##                  lit.gene2pubmed.parquet 
    ##                                    15253 
    ##                  lit.gene2refseq.parquet 
    ##                                      844

Find the UniProt identifiers associated with ORMDL3:

<div id="cb10" class="sourceCode">

``` r
pro = litpop[["lit.gene2accession.parquet"]] |>
   filter(`#tax_id` == 9606, Symbol == "ORMDL3") |>
   select(protein_accession.version) |> collect() |> pull() |> setdiff("-")
litpop[["lit.gene_refseq_uniprotkb_collab.parquet"]] |>
   filter(NCBI_tax_id == 9606) |>
   filter(`#NCBI_protein_accession` %in% pro) |> collect()
```

</div>

    ## # A tibble: 36 × 5
    ##    `#NCBI_protein_accession` UniProtKB_protein_ac…¹ NCBI_tax_id UniProtKB_tax_id
    ##    <chr>                     <chr>                        <int>            <int>
    ##  1 NP_001307730.1            B3KS83                        9606             9606
    ##  2 NP_001307730.1            J3QRM9                        9606             9606
    ##  3 NP_001307730.1            Q6UY83                        9606             9606
    ##  4 NP_001307730.1            Q8N138                        9606             9606
    ##  5 NP_001307731.1            B3KS83                        9606             9606
    ##  6 NP_001307731.1            J3QRM9                        9606             9606
    ##  7 NP_001307731.1            Q6UY83                        9606             9606
    ##  8 NP_001307731.1            Q8N138                        9606             9606
    ##  9 NP_001307732.1            B3KS83                        9606             9606
    ## 10 NP_001307732.1            J3QRM9                        9606             9606
    ## # ℹ 26 more rows
    ## # ℹ abbreviated name: ¹​UniProtKB_protein_accession
    ## # ℹ 1 more variable: method <chr>

</div>

<div class="section level2">

## Lazy remote queries with `open_ncbi_gene()`

`open_ncbi_gene()` returns a lazy `dplyr::tbl` backed by a duckdb VIEW
over the remote parquet file. No data is fetched until `collect()` is
called. Predicates passed to `filter()` and column lists in `select()`
are translated to SQL and pushed down to the parquet read, so only the
requested rows and columns travel the wire.

<div id="cb12" class="sourceCode">

``` r
tbl <- open_ncbi_gene("gene_info", taxid = 9606L)
class(tbl)
```

</div>

    ## [1] "tbl_duckdb_connection" "tbl_dbi"               "tbl_sql"              
    ## [4] "tbl_lazy"              "tbl"

The object is a lazy SQL-backed tbl – inspecting it triggers a small
preview fetch but does not load the full dataset.

Compose a multi-step query before collecting:

<div id="cb14" class="sourceCode">

``` r
open_ncbi_gene("gene_info", taxid = 9606L) |>
  filter(Symbol %in% c("TP53", "ORMDL3", "BRCA1", "GSDMB")) |>
  select(Symbol, GeneID, map_location, type_of_gene) |>
  collect()
```

</div>

    ## # A tibble: 4 × 4
    ##   Symbol GeneID map_location type_of_gene  
    ##   <chr>   <dbl> <chr>        <chr>         
    ## 1 TP53     7157 17p13.1      protein-coding
    ## 2 GSDMB   55876 17q21.1      protein-coding
    ## 3 ORMDL3  94103 17q21.1      protein-coding
    ## 4 BRCA1     672 17q21.31     protein-coding

The same interface works for any of the eight resources. Omitting
`taxid` returns a tbl spanning all organisms:

<div id="cb16" class="sourceCode">

``` r
open_ncbi_gene("gene_orthologs") |>
  filter(GeneID == 7157L) |>   # TP53 orthologs across all taxa
  collect()
```

</div>

</div>

<div class="section level2">

## Discovering available fields with `ncbi_gene_fields()`

Before composing a query it is useful to know what columns a resource
provides. `ncbi_gene_fields()` queries the duckdb schema for any
resource and returns a data frame of column names and their duckdb types
– no data rows are fetched.

<div id="cb17" class="sourceCode">

``` r
ncbi_gene_fields("gene_info")
```

</div>

    ##                              column_name column_type
    ## 1                                #tax_id      BIGINT
    ## 2                                 GeneID      BIGINT
    ## 3                                 Symbol     VARCHAR
    ## 4                               LocusTag     VARCHAR
    ## 5                               Synonyms     VARCHAR
    ## 6                                dbXrefs     VARCHAR
    ## 7                             chromosome     VARCHAR
    ## 8                           map_location     VARCHAR
    ## 9                            description     VARCHAR
    ## 10                          type_of_gene     VARCHAR
    ## 11    Symbol_from_nomenclature_authority     VARCHAR
    ## 12 Full_name_from_nomenclature_authority     VARCHAR
    ## 13                   Nomenclature_status     VARCHAR
    ## 14                    Other_designations     VARCHAR
    ## 15                     Modification_date      BIGINT
    ## 16                          Feature_type     VARCHAR

The function accepts any name returned by `available_ncbi_parquet()`,
with or without the `.parquet` suffix:

<div id="cb19" class="sourceCode">

``` r
ncbi_gene_fields("gene2go")
```

</div>

    ##   column_name column_type
    ## 1     #tax_id      BIGINT
    ## 2      GeneID      BIGINT
    ## 3       GO_ID     VARCHAR
    ## 4    Evidence     VARCHAR
    ## 5   Qualifier     VARCHAR
    ## 6     GO_term     VARCHAR
    ## 7      PubMed     VARCHAR
    ## 8    Category     VARCHAR

Column names can also be used to validate a `select()` or `by` argument
before running a potentially expensive query:

<div id="cb21" class="sourceCode">

``` r
"map_location" %in% ncbi_gene_fields("gene_info")$column_name
```

</div>

    ## [1] TRUE

<div id="cb23" class="sourceCode">

``` r
"map_location" %in% ncbi_gene_fields("gene2go")$column_name
```

</div>

    ## [1] FALSE

</div>

<div class="section level2">

## Identifier mapping with `mapIdsNG()`

`mapIdsNG()` is a `mapIds`-style function that pushes all filtering to
duckdb. For Symbol or GeneID keytypes the filter is a SQL `IN (...)`
predicate on `gene_info`; for the Ensembl keytype a JOIN between
`gene2ensembl` and `gene_info` is performed entirely in duckdb. Exactly
one `collect()` call retrieves only the matched rows and the requested
columns.

<div class="section level3">

### Symbol to GeneID

<div id="cb25" class="sourceCode">

``` r
mapIdsNG(
  keys    = c("ORMDL3", "TP53", "GSDMB", "XyZZY"),
  keytype = "Symbol",
  column  = "GeneID"
)
```

</div>

    ## ORMDL3   TP53  GSDMB  XyZZY 
    ##  94103   7157  55876     NA

The result is a named vector conformant to the input `keys`, with `NA`
for unrecognised identifiers.

</div>

<div class="section level3">

### Symbol to chromosomal map location

<div id="cb27" class="sourceCode">

``` r
mapIdsNG(
  keys    = c("ORMDL3", "TP53", "GSDMB", "BRCA1"),
  keytype = "Symbol",
  column  = "map_location"
)
```

</div>

    ##     ORMDL3       TP53      GSDMB      BRCA1 
    ##  "17q21.1"  "17p13.1"  "17q21.1" "17q21.31"

</div>

<div class="section level3">

### Ensembl to Symbol

Ensembl lookups join `gene2ensembl.parquet` with `gene_info.parquet` on
`GeneID`; the join runs entirely in duckdb before a single `collect()`.

<div id="cb29" class="sourceCode">

``` r
mapIdsNG(
  keys    = c("ENSG00000073605", "ENSG00000141510", "ENSG00000012048"),
  keytype = "Ensembl",
  column  = "Symbol"
)
```

</div>

    ## ENSG00000073605 ENSG00000141510 ENSG00000012048 
    ##         "GSDMB"          "TP53"         "BRCA1"

</div>

</div>

<div class="section level2">

## Querying non-human organisms

Because all NCBI Gene annotation for all organisms lives in the same
parquet files, switching species is simply a matter of changing `taxid`.
Here we look up Ensembl gene and transcript identifiers for the mouse
(*Mus musculus*, taxid 10090) gene *Lilrb4a*.

A quick symbol-to-Ensembl-gene lookup:

<div id="cb31" class="sourceCode">

``` r
mapIdsNG(keys = "Lilrb4a", keytype = "Symbol", column = "Ensembl",
         taxid = 10090L)
```

</div>

    ##              Lilrb4a 
    ## "ENSMUSG00000112148"

For the full transcript-level picture we join `gene_info` (filtered to
the symbol) against `gene2ensembl` entirely within duckdb – both lazy
tbls share the same connection, so the join is pushed down before any
data is collected:

<div id="cb33" class="sourceCode">

``` r
gene_info_mouse <- open_ncbi_gene("gene_info", taxid = 10090L) |>
  dplyr::filter(.data[["Symbol"]] == "Lilrb4a") |>
  dplyr::select(GeneID, Symbol)

open_ncbi_gene("gene2ensembl", taxid = 10090L) |>
  dplyr::inner_join(gene_info_mouse, by = "GeneID") |>
  dplyr::select(Symbol, Ensembl_gene_identifier,
                Ensembl_rna_identifier, Ensembl_protein_identifier) |>
  dplyr::collect()
```

</div>

    ## # A tibble: 3 × 4
    ##   Symbol  Ensembl_gene_identifier Ensembl_rna_identifier Ensembl_protein_ident…¹
    ##   <chr>   <chr>                   <chr>                  <chr>                  
    ## 1 Lilrb4a ENSMUSG00000112148      ENSMUST00000218617.2   -                      
    ## 2 Lilrb4a ENSMUSG00000112148      ENSMUST00000078778.5   ENSMUSP00000077833.4   
    ## 3 Lilrb4a ENSMUSG00000062593      ENSMUST00000218123.2   ENSMUSP00000151827.2   
    ## # ℹ abbreviated name: ¹​Ensembl_protein_identifier

The result reveals two distinct Ensembl gene models for *Lilrb4a* –
something that a two-step approach (Symbol -&gt; one gene ID -&gt;
transcripts) would have missed. Joining directly on `GeneID` returns all
Ensembl records for the gene in a single query.

</div>

<div class="section level2">

## Joining local data to remote annotation with `join_ncbi_gene()`

`join_ncbi_gene()` uploads a local data frame to the duckdb session as a
temporary table and returns a lazy join against any remote NCBI Gene
resource. Both sides of the join run in duckdb; the caller decides what
to `select()` and when to `collect()`.

<div id="cb35" class="sourceCode">

``` r
local_df <- data.frame(Symbol = c("ORMDL3", "TP53", "BRCA1", "GSDMB", "XyZZY"))

join_ncbi_gene(local_df, by = "Symbol", taxid = 9606L) |>
  select(Symbol, GeneID, map_location, type_of_gene) |>
  collect()
```

</div>

    ## # A tibble: 5 × 4
    ##   Symbol GeneID map_location type_of_gene  
    ##   <chr>   <dbl> <chr>        <chr>         
    ## 1 TP53     7157 17p13.1      protein-coding
    ## 2 GSDMB   55876 17q21.1      protein-coding
    ## 3 ORMDL3  94103 17q21.1      protein-coding
    ## 4 BRCA1     672 17q21.31     protein-coding
    ## 5 XyZZY      NA NA           NA

Unmatched keys (here `XyZZY`) appear with `NA` in the annotation columns
because the default join type is `"left"`. Switch to `type = "inner"` to
drop them.

<div class="section level3">

### Enriching a GeneID table with GO terms and RefSeq identifiers

When multiple annotation resources are needed, each requires a
**separate** join back to the original data frame. GO terms and RefSeq
identifiers are both one-to-many relationships with GeneID: three genes
yield hundreds of GO annotations and hundreds of transcript/protein
pairs. Joining both resources in a single query would produce a
Cartesian product; the correct pattern is two independent joins.

Start with a local data frame of Entrez IDs:

<div id="cb37" class="sourceCode">

``` r
local_ids <- data.frame(GeneID = c(94103L, 7157L, 672L))
```

</div>

**GO terms** – one row per gene-GO pair:

<div id="cb38" class="sourceCode">

``` r
go_tbl <- join_ncbi_gene(local_ids, by = "GeneID",
                          resource = "gene2go", taxid = 9606L) |>
  select(GeneID, GO_ID, GO_term, Evidence, Category) |>
  collect()
nrow(go_tbl)
```

</div>

    ## [1] 343

<div id="cb40" class="sourceCode">

``` r
head(go_tbl)
```

</div>

    ## # A tibble: 6 × 5
    ##   GeneID GO_ID      GO_term                                    Evidence Category
    ##    <int> <chr>      <chr>                                      <chr>    <chr>   
    ## 1  94103 GO:0002903 negative regulation of B cell apoptotic p… IMP      Process 
    ## 2  94103 GO:0005515 protein binding                            IPI      Function
    ## 3  94103 GO:0005783 endoplasmic reticulum                      IDA      Compone…
    ## 4  94103 GO:0005789 endoplasmic reticulum membrane             EXP      Compone…
    ## 5  94103 GO:0005789 endoplasmic reticulum membrane             IEA      Compone…
    ## 6  94103 GO:0005886 plasma membrane                            TAS      Compone…

**RefSeq identifiers** – one row per gene-transcript pair (excluding
entries with no RNA accession):

<div id="cb42" class="sourceCode">

``` r
refseq_tbl <- join_ncbi_gene(local_ids, by = "GeneID",
                              resource = "gene2refseq", taxid = 9606L) |>
  select(GeneID,
         RNA   = RNA_nucleotide_accession.version,
         protein = protein_accession.version) |>
  filter(RNA != "-") |>
  collect()
nrow(refseq_tbl)
```

</div>

    ## [1] 810

<div id="cb44" class="sourceCode">

``` r
head(refseq_tbl)
```

</div>

    ## # A tibble: 6 × 3
    ##   GeneID RNA            protein       
    ##    <int> <chr>          <chr>         
    ## 1   7157 NM_000546.6    NP_000537.3   
    ## 2   7157 NM_000546.6    NP_000537.3   
    ## 3   7157 NM_000546.6    NP_000537.3   
    ## 4   7157 NM_001126112.3 NP_001119584.1
    ## 5   7157 NM_001126112.3 NP_001119584.1
    ## 6   7157 NM_001126112.3 NP_001119584.1

Each result shares the `GeneID` key with the original `local_ids` data
frame and can be used independently or merged with `dplyr::left_join()`
after collecting, depending on the downstream analysis.

</div>

</div>

<div class="section level2">

## Caching for offline or high-performance use

All queries above route to the OSN bucket on every call. For a species
you work with repeatedly, `cache_by_taxon()` performs a one-time filter
of each remote parquet down to that taxon and stores the result in
`BiocFileCache`. After that, `open_ncbi_gene()` – and every function
that calls it (`join_ncbi_gene()`, `mapIdsNG()`, `ncbi_gene_fields()`) –
silently routes to the local file instead of the bucket, with no change
to the API.

The filtering uses duckdb’s `COPY ... TO` statement, so data streams
directly to disk without passing through R memory.

<div id="cb46" class="sourceCode">

``` r
# one-time setup -- slow for large resources, fast thereafter
cache_by_taxon(9606L)   # human: all eight resources
```

</div>

Check what is cached:

<div id="cb47" class="sourceCode">

``` r
taxon_cache_info()   # all cached taxons; taxon_cache_info(9606L) for one taxon
```

</div>

    ##                                                             rname
    ## 1                     gene_info_taxid9606_frozen_23julVJC.parquet
    ## 2                gene_orthologs_taxid9606_frozen_23julVJC.parquet
    ## 3  gene_refseq_uniprotkb_collab_taxid9606_frozen_23julVJC.parquet
    ## 4                gene2accession_taxid9606_frozen_23julVJC.parquet
    ## 5                  gene2ensembl_taxid9606_frozen_23julVJC.parquet
    ## 6                       gene2go_taxid9606_frozen_23julVJC.parquet
    ## 7                   gene2pubmed_taxid9606_frozen_23julVJC.parquet
    ## 8                   gene2refseq_taxid9606_frozen_23julVJC.parquet
    ## 9                               gene_orthologs_taxid10090.parquet
    ## 10                    gene_orthologs_taxid10090_frozen_v1.parquet
    ##                                                                                                         rpath
    ## 1  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff4c8c6bd9_file16cff6d816eb9.parquet
    ## 2  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff6d735ff4_file16cff22185cc8.parquet
    ## 3  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff3563dc8b_file16cff31b837fd.parquet
    ## 4  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff4987d819_file16cff7631f3f6.parquet
    ## 5  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff2ac55ec6_file16cff3e6a2585.parquet
    ## 6  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff7cd5c4d9_file16cff1a6b55eb.parquet
    ## 7  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff66e81dc6_file16cff21a921c5.parquet
    ## 8   /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff50e05fc_file16cff48502293.parquet
    ## 9    /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/54287e0666d7_file54281f35b13a.parquet
    ## 10    /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/5428237044b6_file5428fa13ffe.parquet
    ##            create_time
    ## 1  2026-07-23 12:17:55
    ## 2  2026-07-23 12:17:55
    ## 3  2026-07-23 12:17:55
    ## 4  2026-07-23 12:17:55
    ## 5  2026-07-23 12:17:55
    ## 6  2026-07-23 12:17:55
    ## 7  2026-07-23 12:17:55
    ## 8  2026-07-23 12:17:55
    ## 9  2026-07-23 13:27:39
    ## 10 2026-07-23 13:27:39

After caching, the same code runs from local disk:

<div id="cb49" class="sourceCode">

``` r
# identical call -- routed to BiocFileCache automatically
open_ncbi_gene("gene_info", taxid = 9606L) |>
  dplyr::filter(Symbol %in% c("TP53", "BRCA1")) |>
  dplyr::select(Symbol, GeneID, map_location) |>
  dplyr::collect()
```

</div>

To refresh a cached resource (e.g. after uploading a new parquet to the
bucket):

<div id="cb50" class="sourceCode">

``` r
cache_by_taxon(9606L, resources = "gene_info", force = TRUE)
```

</div>

<div class="section level3">

### Freezing a snapshot for reproducibility

A live cache entry can be overwritten at any time by a `force=TRUE` call
to `cache_by_taxon()`. To preserve a specific version of the data for
reproducibility – e.g. when publishing an analysis – use
`freeze_taxon_cache()`. It makes a physical copy of each live cached
parquet under an identifying tag. Frozen entries are never removed by
`clear_taxon_cache()`.

<div id="cb51" class="sourceCode">

``` r
# after cache_by_taxon(9606L) has been called:
freeze_taxon_cache(9606L, tag = "paper_2026_07")
```

</div>

Frozen snapshots appear in `taxon_cache_info()` alongside live entries:

<div id="cb52" class="sourceCode">

``` r
taxon_cache_info()
```

</div>

    ##                                                             rname
    ## 1                     gene_info_taxid9606_frozen_23julVJC.parquet
    ## 2                gene_orthologs_taxid9606_frozen_23julVJC.parquet
    ## 3  gene_refseq_uniprotkb_collab_taxid9606_frozen_23julVJC.parquet
    ## 4                gene2accession_taxid9606_frozen_23julVJC.parquet
    ## 5                  gene2ensembl_taxid9606_frozen_23julVJC.parquet
    ## 6                       gene2go_taxid9606_frozen_23julVJC.parquet
    ## 7                   gene2pubmed_taxid9606_frozen_23julVJC.parquet
    ## 8                   gene2refseq_taxid9606_frozen_23julVJC.parquet
    ## 9                               gene_orthologs_taxid10090.parquet
    ## 10                    gene_orthologs_taxid10090_frozen_v1.parquet
    ##                                                                                                         rpath
    ## 1  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff4c8c6bd9_file16cff6d816eb9.parquet
    ## 2  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff6d735ff4_file16cff22185cc8.parquet
    ## 3  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff3563dc8b_file16cff31b837fd.parquet
    ## 4  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff4987d819_file16cff7631f3f6.parquet
    ## 5  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff2ac55ec6_file16cff3e6a2585.parquet
    ## 6  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff7cd5c4d9_file16cff1a6b55eb.parquet
    ## 7  /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff66e81dc6_file16cff21a921c5.parquet
    ## 8   /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/16cff50e05fc_file16cff48502293.parquet
    ## 9    /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/54287e0666d7_file54281f35b13a.parquet
    ## 10    /Users/vincentcarey/Library/Caches/org.R-project.R/R/BiocFileCache/5428237044b6_file5428fa13ffe.parquet
    ##            create_time
    ## 1  2026-07-23 12:17:55
    ## 2  2026-07-23 12:17:55
    ## 3  2026-07-23 12:17:55
    ## 4  2026-07-23 12:17:55
    ## 5  2026-07-23 12:17:55
    ## 6  2026-07-23 12:17:55
    ## 7  2026-07-23 12:17:55
    ## 8  2026-07-23 12:17:55
    ## 9  2026-07-23 13:27:39
    ## 10 2026-07-23 13:27:39

To query a frozen snapshot, pass `freeze_tag` to `open_ncbi_gene()` – or
to any function that calls it. The function stops with an informative
message if the tag does not exist:

<div id="cb54" class="sourceCode">

``` r
open_ncbi_gene("gene_info", taxid = 9606L, freeze_tag = "paper_2026_07") |>
  dplyr::filter(Symbol %in% c("TP53", "BRCA1")) |>
  dplyr::select(Symbol, GeneID, map_location) |>
  dplyr::collect()

# propagates through join_ncbi_gene and mapIdsNG too:
mapIdsNG(keys = c("TP53", "BRCA1"), keytype = "Symbol", column = "GeneID",
         taxid = 9606L)   # uses live cache or remote, not the frozen snapshot
```

</div>

Duplicate tags are rejected unless `force=TRUE`:

<div id="cb55" class="sourceCode">

``` r
freeze_taxon_cache(9606L, tag = "paper_2026_07")          # error: tag exists
freeze_taxon_cache(9606L, tag = "paper_2026_07", force = TRUE)  # OK
```

</div>

</div>

</div>

<div class="section level2">

## Session information

<div id="cb56" class="sourceCode">

``` r
sessionInfo()
```

</div>

    ## R version 4.6.1 (2026-06-24)
    ## Platform: aarch64-apple-darwin23
    ## Running under: macOS Sequoia 15.7.7
    ## 
    ## Matrix products: default
    ## BLAS:   /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRblas.0.dylib 
    ## LAPACK: /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1
    ## 
    ## locale:
    ## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    ## 
    ## time zone: America/New_York
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats4    stats     graphics  grDevices utils     datasets  methods  
    ## [8] base     
    ## 
    ## other attached packages:
    ##  [1] dplyr_1.2.1          RNCBIGene_0.1.6      org.Hs.eg.db_3.23.1 
    ##  [4] AnnotationDbi_1.75.0 IRanges_2.47.2       S4Vectors_0.51.5    
    ##  [7] Biobase_2.73.1       BiocGenerics_0.59.10 generics_0.1.4      
    ## [10] BiocStyle_2.41.0    
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] KEGGREST_1.53.5     xfun_0.60           bslib_0.11.0       
    ##  [4] httr2_1.3.0         htmlwidgets_1.6.4   crosstalk_1.2.2    
    ##  [7] vctrs_0.7.3         tools_4.6.1         curl_7.1.0         
    ## [10] tibble_3.3.1        RSQLite_3.53.3      blob_1.3.0         
    ## [13] pkgconfig_2.0.3     dbplyr_2.6.0        desc_1.4.3         
    ## [16] assertthat_0.2.1    lifecycle_1.0.5     compiler_4.6.1     
    ## [19] textshaping_1.0.5   Biostrings_2.81.5   Seqinfo_1.3.0      
    ## [22] htmltools_0.5.9     sass_0.4.10         yaml_2.3.12        
    ## [25] pkgdown_2.2.1       pillar_1.11.1       crayon_1.5.3       
    ## [28] jquerylib_0.1.4     DT_0.34.0           cachem_1.1.0       
    ## [31] tidyselect_1.2.1    digest_0.6.39       duckdb_1.5.4.3     
    ## [34] purrr_1.2.2         bookdown_0.47       arrow_25.0.0       
    ## [37] fastmap_1.2.0       cli_3.6.6           magrittr_2.0.5     
    ## [40] utf8_1.2.6          withr_3.0.3         filelock_1.0.3     
    ## [43] bit64_4.8.2         rmarkdown_2.31      XVector_0.53.0     
    ## [46] httr_1.4.8          bit_4.6.0           otel_0.2.0         
    ## [49] ragg_1.5.2          png_0.1-9           memoise_2.0.1      
    ## [52] evaluate_1.0.5      knitr_1.51          BiocFileCache_3.3.0
    ## [55] rlang_1.3.0         glue_1.8.1          DBI_1.3.0          
    ## [58] BiocManager_1.30.27 jsonlite_2.0.0      R6_2.6.1           
    ## [61] systemfonts_1.3.2   fs_2.1.0

</div>

</div>
