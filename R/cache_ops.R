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


OSN_LISTING_URL <- paste0(
  "https://mghp.osn.xsede.org/bir190004-bucket01",
  "?prefix=BiocParquetNCBI/")

#' list parquet resources available in the OSN bucket
#'
#' Queries the bucket's S3 listing endpoint and returns the current set of
#' parquet file names.  Requires an internet connection; stops with an
#' informative message if the request fails.
#' @return character vector of parquet file names (e.g. \code{"gene_info.parquet"})
#' @examples
#' if (is_online()) available_ncbi_parquet()
#' @export
available_ncbi_parquet <- function() {
  if (!is_online())
    stop("No internet connection -- please try again when online.")
  xml  <- paste(readLines(OSN_LISTING_URL, warn = FALSE), collapse = "")
  keys <- regmatches(xml,
    gregexpr("(?<=<Key>)[^<]+\\.parquet(?=</Key>)", xml, perl = TRUE))[[1]]
  if (length(keys) == 0L)
    stop("Bucket listing returned no parquet files -- check the OSN URL.")
  sort(basename(keys))
}

#' download a parquet file from the OSN bucket to local BiocFileCache
#' @import BiocFileCache
#' @importFrom utils download.file
#' @import arrow
#' @import dplyr
#' @param resource character(1)
#' @param cache BiocFileCache object
#' @return path to local cached file
geneFromCache = function(resource, cache=BiocFileCache::BiocFileCache()) {
 stopifnot(resource %in% available_ncbi_parquet())
 .osn_bucket_to_cache(entity=resource, ca=cache)
}
