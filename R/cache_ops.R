# from https://stackoverflow.com/questions/5076593/how-to-determine-if-you-have-an-internet-connection-in-r

#' utility to check for internet access for testing
#' @param site character(1)
#' @return logical(1)
#' @export
is_online <- function(site="http://example.com/") {
  tryCatch({
    readLines(site,n=1)
    TRUE
  },
  warning = function(w) invokeRestart("muffleWarning"),
  error = function(e) FALSE)
}

.osn_bucket_to_cache <- function(
    entity, folder = "BiocParquetNCBI",
    prefix = "https://mghp.osn.xsede.org/bir190004-bucket01/",
    ca = BiocFileCache::BiocFileCache()) {
  pa <- bfcquery(ca, entity)
  if (nrow(pa) > 1) {
    stop(sprintf(
      "%s has multiple instances in cache, please inspect.",
      entity
    ))
  } else if (nrow(pa) == 1) {
    return(pa$rpath)
  }
  target <- paste0(prefix, folder, "/", entity)
  tf <- tempfile(entity) # for metadata
  download.file(target, tf)
  bfcrpath(ca, tf, action = "copy")
}

available_gene_parquet = c(
  "gene2go.parquet",
  "gene2pubmed.parquet",
  "gene_info.parquet",
  "gene2accession.parquet",
  "gene2refseq.parquet",
  "gene_orthologs.parquet",
  "gene_refseq_uniprotkb_collab.parquet"
)

#3002338275 2025-05-17 09:28:29.618223689 gene2accession.parquet
#680657744 2025-05-15 10:31:33.209868982 gene2go.parquet
# 89080561 2025-05-15 10:37:45.825464461 gene2pubmed.parquet
#1467468877 2025-05-17 09:28:38.701230380 gene2refseq.parquet
#965232147 2025-05-15 10:33:17.845775772 gene_info.parquet
# 43279811 2025-05-17 09:28:42.882232368 gene_orthologs.parquet
#1019413239 2025-05-17 09:28:47.416233993 gene_refseq_uniprotkb_collab.parquet

#' populate cache with available parquet files if needed, return
#' path to cached file
#' @import BiocFileCache
#' @importFrom utils download.file
#' @import arrow
#' @import dplyr
#' @param resource character(1) 
#' @param cache character(1) BiocFileCache-like object
#' @return path to local version of resource
#' @examples
#' oldop = options()
#' options(timeout=3600)
#' gi = geneFromCache("gene_info.parquet")
#' options(oldop)
#' arrow::open_dataset(gi) |> dplyr::filter(`#tax_id`==9606) |> head() |> dplyr::collect()
#' @export
geneFromCache = function(resource, cache=BiocFileCache::BiocFileCache()) {
 stopifnot(resource %in% available_gene_parquet)
 .osn_bucket_to_cache(entity=resource, ca=cache)
}
