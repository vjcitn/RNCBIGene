<div id="main" class="col-md-9" role="main">

# Package index

<div class="section level2">

## All functions

</div>

<div class="section level2">

-   `NGparq()` : obtain references to parquet serializations of slices
    of NCBI Gene annotation
-   `available_ncbi_parquet()` : list parquet resources available in the
    OSN bucket
-   `geneFromCache()` : download a parquet file from the OSN bucket to
    local BiocFileCache
-   `is_online()` : utility to check for internet access for testing
-   `join_ncbi_gene()` : join a local data frame to a remote NCBI Gene
    parquet resource
-   `mapIdsNG()` : analog of mapIds from AnnotationDbi using lazy duckdb
    queries on NCBI Gene parquet
-   `ncbi_gene_con()` : get or create a persistent duckdb connection
    with httpfs loaded
-   `ncbi_gene_fields()` : list the fields available for a remote NCBI
    Gene parquet resource
-   `ncbi_parquet_info()` : retrieve size, upload date, and NCBI source
    date for each bucket resource
-   `open_ncbi_gene()` : open a lazy dplyr tbl over a remote NCBI Gene
    parquet resource
-   `print(<NGparq>)` : print method for NGparq list
-   `processDbx()` : given a bar-delimited string as produced for
    dbXrefs in gene\_info, extract the value associated with a given tag
-   `processDbx1()` : given an element of a bar-delimited string as
    produced for dbXrefs in gene\_info, extract the value associated
    with a given tag
-   `remote_gene_query()` : use duckdb to query NCBI Gene data in OSN
    bucket
-   `taxonomyMap()` : retrieve a vector of taxonomy names indexed by
    taxonomy codes

</div>

</div>
