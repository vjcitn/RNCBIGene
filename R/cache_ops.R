# from https://stackoverflow.com/questions/5076593/how-to-determine-if-you-have-an-internet-connection-in-r

#' utility to check for internet access for testing
#' @param site character(1)
#' @return logical(1)
#' @export
is_online <- function(site="http://example.com/") {
  tryCatch({
    readLines(site, n=1)
    TRUE
  },
  warning = function(w) TRUE,   # swallow "incomplete final line" etc.
  error   = function(e) FALSE)
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

#' filter and cache parquet resources for a single taxon in BiocFileCache
#'
#' Performs a one-time download-and-filter of remote NCBI Gene parquet files to
#' local parquet files stored in BiocFileCache.  After calling this function,
#' \code{open_ncbi_gene(resource, taxid)} will automatically route to the local
#' cached file instead of querying the OSN bucket, with no change to the API.
#'
#' @param taxid integer(1) NCBI taxonomy ID (e.g. 9606L for human, 10090L for mouse)
#' @param resources character vector of resource names (without .parquet suffix)
#'   to cache; defaults to all resources in the bucket
#' @param cache a \code{BiocFileCache} object
#' @param force logical(1) if TRUE, re-download and overwrite existing cache entries
#' @param verbose logical(1) print progress messages
#' @return invisibly, a named character vector of local parquet paths
#' @examples
#' if (is_online()) {
#'   # cache only the smallest resource for illustration
#'   cache_by_taxon(10090L, resources = "gene_orthologs")
#'   taxon_cache_info(10090L)
#' }
#' @export
cache_by_taxon <- function(
    taxid,
    resources = sub("\\.parquet$", "", available_ncbi_parquet()),
    cache     = .ncbi_cache(),
    force     = FALSE,
    verbose   = TRUE) {

  paths <- character(length(resources))
  names(paths) <- resources

  for (gres in resources) {
    key      <- sprintf("%s_taxid%s.parquet", gres, taxid)
    existing <- BiocFileCache::bfcquery(cache, key, field = "rname")

    if (nrow(existing) == 1L && !force) {
      if (verbose) message(sprintf("  %s: already cached", key))
      paths[[gres]] <- existing$rpath
      next
    }

    if (verbose) message(sprintf("  %s: filtering from OSN ...", gres))

    open_ncbi_gene(gres)  # validates resource name and creates VIEW
    vname  <- paste0("v_", gsub("[^A-Za-z0-9]", "_", gres))
    taxcol <- .taxid_column(gres)
    tmp    <- tempfile(fileext = ".parquet")

    DBI::dbExecute(ncbi_gene_con(), sprintf(
      "COPY (SELECT * FROM %s WHERE \"%s\" = %s)
       TO '%s' (FORMAT parquet, COMPRESSION zstd, COMPRESSION_LEVEL 15)",
      vname, taxcol, taxid, tmp))

    if (nrow(existing) == 1L && force)
      BiocFileCache::bfcremove(cache, existing$rid)

    rid           <- BiocFileCache::bfcadd(cache, rname = key,
                                            fpath = tmp, action = "move")
    paths[[gres]] <- BiocFileCache::bfcrpath(cache, rid)
    if (verbose) message(sprintf("  %s: done", key))
  }
  invisible(paths)
}

#' list taxon-specific parquets stored in BiocFileCache
#'
#' @param taxid integer(1) or NULL; when NULL lists all cached taxon parquets
#' @param cache a \code{BiocFileCache} object
#' @return data.frame with columns \code{rname}, \code{rpath}, \code{create_time}
#' @examples
#' taxon_cache_info()
#' @export
taxon_cache_info <- function(taxid = NULL,
                              cache = .ncbi_cache()) {
  pattern <- if (is.null(taxid)) "_taxid" else sprintf("_taxid%s", taxid)
  pa <- BiocFileCache::bfcquery(cache, pattern, field = "rname")
  as.data.frame(pa[, c("rname", "rpath", "create_time")])
}

#' remove taxon-specific parquets from BiocFileCache
#'
#' Deletes local parquet files cached by \code{cache_by_taxon()}.  After
#' calling this function, \code{open_ncbi_gene()} will route back to the remote
#' OSN bucket for the affected taxon.
#'
#' @param taxid integer(1) or NULL; when NULL removes cached parquets for all
#'   taxa
#' @param cache a \code{BiocFileCache} object
#' @return invisibly, the names of the removed cache entries
#' @examples
#' clear_taxon_cache(9606L)   # removes all human cached parquets
#' clear_taxon_cache()        # removes everything cached by cache_by_taxon
#' @export
clear_taxon_cache <- function(taxid = NULL, cache = .ncbi_cache()) {
  pattern <- if (is.null(taxid)) "_taxid" else sprintf("_taxid%s", taxid)
  pa <- BiocFileCache::bfcquery(cache, pattern, field = "rname")
  pa <- pa[!grepl("_frozen_", pa$rname), ]   # never remove frozen snapshots
  if (nrow(pa) == 0L) {
    message("No live cached entries found.")
    return(invisible(character(0)))
  }
  BiocFileCache::bfcremove(cache, pa$rid)
  message(sprintf("Removed %d live cached parquet(s).", nrow(pa)))
  invisible(pa$rname)
}

#' freeze a snapshot of taxon-cached parquets for reproducibility
#'
#' Copies the current live cached parquets for a taxon into permanent
#' BiocFileCache entries labelled with an identifying tag.  The frozen copies
#' are independent of the live cache: subsequent \code{cache_by_taxon()} or
#' \code{clear_taxon_cache()} calls do not affect them.  Use
#' \code{open_ncbi_gene(resource, taxid, freeze_tag=tag)} to query a frozen
#' snapshot.
#'
#' @param taxid integer(1) NCBI taxonomy ID
#' @param tag character(1) identifying label for this snapshot; must not already
#'   exist in the cache unless \code{force=TRUE}
#' @param resources character vector of resource names to freeze; defaults to
#'   all resources currently cached for this taxon
#' @param cache a \code{BiocFileCache} object
#' @param force logical(1) if TRUE, overwrite an existing frozen snapshot with
#'   the same tag
#' @return invisibly, a named character vector of frozen local parquet paths
#' @examples
#' if (is_online()) {
#'   cache_by_taxon(10090L, resources = "gene_orthologs")
#'   freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs",
#'                      force = TRUE)
#'   taxon_cache_info(10090L)
#' }
#' @export
freeze_taxon_cache <- function(taxid, tag,
                                resources = NULL,
                                cache     = .ncbi_cache(),
                                force     = FALSE) {
  stopifnot(is.character(tag), length(tag) == 1L, nchar(tag) > 0L)

  # reject tag if already present (unless force)
  existing_tag <- BiocFileCache::bfcquery(cache,
    sprintf("_frozen_%s\\.parquet", tag), field = "rname")
  if (nrow(existing_tag) > 0L && !force)
    stop(sprintf(
      "Tag '%s' already exists in cache. Use force=TRUE to overwrite.", tag))

  # default resources: whatever is live-cached for this taxon
  if (is.null(resources)) {
    live_all <- BiocFileCache::bfcquery(cache,
      sprintf("_taxid%s\\.parquet", taxid), field = "rname")
    live_all  <- live_all[!grepl("_frozen_", live_all$rname), ]
    if (nrow(live_all) == 0L)
      stop(sprintf("No live cache found for taxid %s. Run cache_by_taxon(%s) first.", taxid, taxid))
    resources <- sub(sprintf("_taxid%s\\.parquet", taxid), "", live_all$rname)
  }

  paths <- character(length(resources))
  names(paths) <- resources

  for (gres in resources) {
    live_key <- sprintf("%s_taxid%s.parquet", gres, taxid)
    live     <- BiocFileCache::bfcquery(cache, live_key, field = "rname")
    live     <- live[!grepl("_frozen_", live$rname), ]
    if (nrow(live) == 0L)
      stop(sprintf(
        "No live cache for '%s' taxid %s. Run cache_by_taxon(%s) first.",
        gres, taxid, taxid))

    frozen_key <- sprintf("%s_taxid%s_frozen_%s.parquet", gres, taxid, tag)
    old_frozen <- BiocFileCache::bfcquery(cache, frozen_key, field = "rname")
    if (nrow(old_frozen) == 1L && force)
      BiocFileCache::bfcremove(cache, old_frozen$rid)

    tmp <- tempfile(fileext = ".parquet")
    file.copy(live$rpath, tmp)
    rid          <- BiocFileCache::bfcadd(cache, rname = frozen_key,
                                           fpath = tmp, action = "move")
    paths[[gres]] <- BiocFileCache::bfcrpath(cache, rid)
    message(sprintf("  frozen: %s", frozen_key))
  }
  invisible(paths)
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
 .osn_bucket_to_cache(entity=resource, ca=cache)
}
