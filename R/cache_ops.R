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

OSN_PROVENANCE_URL <- paste0(
  "https://mghp.osn.xsede.org/bir190004-bucket01/",
  "BiocParquetNCBI/provenance.json")

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

#' retrieve size, upload date, and NCBI source date for each bucket resource
#'
#' Reads the OSN bucket S3 listing for file sizes and upload timestamps.
#' When a \code{provenance.json} sidecar is present in the bucket (written by
#' \code{inst/preps/make_provenance.R}), the NCBI FTP \code{Last-Modified} date
#' for each source file is merged in.
#' @return data.frame with columns \code{resource}, \code{size_bytes},
#'   \code{bucket_modified}, and \code{ncbi_last_modified} (NA if provenance
#'   not yet available)
#' @examples
#' if (is_online()) ncbi_parquet_info()
#' @export
ncbi_parquet_info <- function() {
  if (!is_online())
    stop("No internet connection -- please try again when online.")

  xml <- paste(readLines(OSN_LISTING_URL, warn = FALSE), collapse = "")
  blocks <- strsplit(xml, "<Contents>")[[1]][-1]

  extract <- function(block, tag) {
    m <- regmatches(block,
      regexpr(sprintf("(?<=<%s>)[^<]+(?=</%s>)", tag, tag), block, perl = TRUE))
    if (length(m)) m else NA_character_
  }

  info <- do.call(rbind, lapply(blocks, function(b) {
    key  <- extract(b, "Key")
    size <- extract(b, "Size")
    lm   <- extract(b, "LastModified")
    data.frame(resource = basename(key), size_bytes = as.numeric(size),
               bucket_modified = lm, stringsAsFactors = FALSE)
  }))
  info <- info[grepl("\\.parquet$", info$resource), ]

  prov <- tryCatch({
    json <- paste(readLines(OSN_PROVENANCE_URL, warn = FALSE), collapse = "")
    # parse minimal JSON: extract per-resource ncbi_last_modified values
    pat  <- '"([^"]+\\.parquet)"\\s*:\\s*\\{[^}]*"ncbi_last_modified"\\s*:\\s*"([^"]*)"'
    m    <- gregexpr(pat, json, perl = TRUE)
    hits <- regmatches(json, m)[[1]]
    keys <- sub(pat, "\\1", hits, perl = TRUE)
    vals <- sub(pat, "\\2", hits, perl = TRUE)
    data.frame(resource = keys, ncbi_last_modified = vals,
               stringsAsFactors = FALSE)
  }, error = function(e) NULL)

  if (!is.null(prov))
    info <- merge(info, prov, by = "resource", all.x = TRUE)
  else
    info$ncbi_last_modified <- NA_character_

  info[order(info$resource), ]
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
