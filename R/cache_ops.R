
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
  "gene_info.parquet"
)

#' populate cache with available parquet files if needed, return
#' path to cached file
#' @import BiocFileCache
#' @import arrow
#' @param resource character(1) 
#' @param cache character(1) BiocFileCache-like object
#' @return path to local version of resource
#' @examples
#' gi = geneFromCache("gene_info.parquet")
#' arrow::open_dataset(gi) |> dplyr::filter(`#tax_id`==9606) |> head() |> dplyr::collect()
#' @export
geneFromCache = function(resource, cache=BiocFileCache::BiocFileCache()) {
 stopifnot(resource %in% available_gene_parquet)
 .osn_bucket_to_cache(entity=resource, ca=cache)
}
