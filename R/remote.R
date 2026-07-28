
.rncbigene_env <- new.env(parent = emptyenv())

ngurl <- function(gres = "gene2pubmed") {
  sprintf("https://mghp.osn.xsede.org/bir190004-bucket01/BiocParquetNCBI/%s.parquet", gres)
}

# Taxid column name differs across resources; all use "#tax_id" except these.
.TAXID_COL <- c(gene_refseq_uniprotkb_collab = "NCBI_tax_id")

.taxid_column <- function(gres) {
  if (gres %in% names(.TAXID_COL)) .TAXID_COL[[gres]] else "#tax_id"
}

# Session-cached resource names (without .parquet suffix) to avoid a network
# round-trip on every open_ncbi_gene() / join_ncbi_gene() call.
.ncbi_resource_names <- function() {
  if (!exists("resources", envir = .rncbigene_env))
    .rncbigene_env$resources <- sub("\\.parquet$", "", available_ncbi_parquet())
  .rncbigene_env$resources
}

# Return the package-level BiocFileCache, creating it once per session.
.ncbi_cache <- function() {
  if (!exists("cache", envir = .rncbigene_env))
    .rncbigene_env$cache <- BiocFileCache::BiocFileCache()
  .rncbigene_env$cache
}

# Return the local BiocFileCache path for (gres, taxid) if it exists, else NULL.
# Prefers a live cache entry; falls back to any frozen snapshot with a message.
# Query uses the prefix WITHOUT .parquet so it matches both
#   "gene_info_taxid9606.parquet"           (live)
#   "gene_info_taxid9606_frozen_TAG.parquet" (frozen)
.cached_parquet_path <- function(gres, taxid) {
  if (is.null(taxid)) return(NULL)
  prefix <- sprintf("%s_taxid%s", gres, taxid)
  pa     <- BiocFileCache::bfcquery(.ncbi_cache(), prefix, field = "rname")

  live <- pa[!grepl("_frozen_", pa$rname), ]
  if (nrow(live) >= 1L) return(live$rpath[1L])

  frozen <- pa[grepl("_frozen_", pa$rname), ]
  if (nrow(frozen) >= 1L) {
    tag <- sub(sprintf(".*_taxid%s_frozen_([^.]+)\\.parquet$", taxid),
               "\\1", frozen$rname[1L])
    message(sprintf(
      "No live cache for '%s' taxid %s; using frozen snapshot '%s'. Run cache_by_taxon(%s) to refresh.",
      gres, taxid, tag, taxid))
    return(frozen$rpath[1L])
  }

  NULL
}

# Return the path of a frozen snapshot, or stop() if not found.
.frozen_parquet_path <- function(gres, taxid, tag) {
  key <- sprintf("%s_taxid%s_frozen_%s.parquet", gres, taxid, tag)
  pa  <- BiocFileCache::bfcquery(.ncbi_cache(), key, field = "rname")
  if (nrow(pa) == 1L) return(pa$rpath)
  stop(sprintf(
    "No frozen snapshot '%s' found for resource '%s' taxid %s.\nCall freeze_taxon_cache(%s, tag='%s') first.",
    tag, gres, taxid, taxid, tag))
}

#' get or create a persistent duckdb connection with httpfs loaded
#'
#' The duckdb httpfs extension is cached in a permanent user directory
#' (via \code{tools::R_user_dir}) so it is not re-downloaded each session.
#' The directory can be inspected with
#' \code{tools::R_user_dir("RNCBIGene", "data")}.
#'
#' @section Connection invalidation:
#' If the connection becomes invalid (e.g. duckdb encounters an internal
#' error) a new connection is created automatically.  However, all duckdb
#' VIEWs created by previous \code{open_ncbi_gene()} calls are lost and any
#' lazy \code{tbl} objects that reference them will fail when collected.
#' Re-call \code{open_ncbi_gene()} to recreate the required VIEWs.
#'
#' @return a DBI connection to an in-process duckdb instance
#' @export
ncbi_gene_con <- function() {
  if (!exists("con", envir = .rncbigene_env) ||
      !DBI::dbIsValid(.rncbigene_env$con)) {
    .gc_ncbi_tables()   # clear any registered tables from the old connection
    ext_dir <- tools::R_user_dir("RNCBIGene", "data")
    if (!dir.exists(ext_dir))
      dir.create(ext_dir, recursive = TRUE)
    # Pass extension_directory via the driver config rather than options() to
    # avoid mutating the caller's global R options.
    con <- DBI::dbConnect(
      duckdb::duckdb(config = list(extension_directory = as.character(ext_dir)))
    )
    DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
    .rncbigene_env$con <- con
  }
  .rncbigene_env$con
}

#' list the fields available for a remote NCBI Gene parquet resource
#'
#' Returns the column names and duckdb types for any resource in the OSN bucket.
#' Useful for discovering what fields can be passed to \code{select} or used as
#' \code{by} keys in \code{join_ncbi_gene()}.
#' @param resource character(1) resource name, with or without .parquet suffix
#' @return data.frame with columns \code{column_name} and \code{column_type}
#' @examples
#' if (is_online()) {
#'   ncbi_gene_fields("gene_info")
#'   ncbi_gene_fields("gene2go")
#' }
#' @export
ncbi_gene_fields <- function(resource = "gene_info") {
  gres  <- sub("\\.parquet$", "", resource)
  open_ncbi_gene(gres)           # validates resource name, creates VIEW
  vname <- paste0("v_", gsub("[^A-Za-z0-9]", "_", gres))
  res   <- DBI::dbGetQuery(ncbi_gene_con(), sprintf("DESCRIBE %s", vname))
  res[, c("column_name", "column_type")]
}

#' open a lazy dplyr tbl over a remote NCBI Gene parquet resource
#' @param resource character(1) parquet resource name, with or without .parquet suffix
#' @param taxid integer(1) or NULL; when non-NULL, pre-filters to this taxonomy ID in SQL
#' @param freeze_tag character(1) or NULL; when set, opens a frozen snapshot created by
#'   \code{freeze_taxon_cache(taxid, tag=freeze_tag)} and fails if the tag is not found
#' @return lazy dplyr::tbl backed by duckdb -- compose filter/select/collect before pulling data
#' @examples
#' if (is_online()) {
#'   open_ncbi_gene("gene_info", taxid = 9606L) |>
#'     dplyr::filter(Symbol %in% c("TP53","BRCA1")) |>
#'     dplyr::select(Symbol, GeneID, map_location) |>
#'     dplyr::collect()
#' }
#' @export
open_ncbi_gene <- function(resource = "gene_info", taxid = NULL, freeze_tag = NULL) {
  gres  <- sub("\\.parquet$", "", resource)
  con   <- ncbi_gene_con()

  # Check local cache FIRST -- works offline.
  # Network validation is only needed when we must hit the remote bucket.
  local <- if (!is.null(freeze_tag))
    .frozen_parquet_path(gres, taxid, freeze_tag)   # stops if not found
  else
    .cached_parquet_path(gres, taxid)

  if (is.null(local)) {
    # Going remote: validate resource name against the live bucket listing.
    avail <- tryCatch(
      .ncbi_resource_names(),
      error = function(e) {
        if (is.null(taxid))
          stop(paste0(
            "The OSN bucket is unreachable and no taxid was specified.\n",
            "Specify taxid= to serve from a local cache (e.g. taxid=9606L for human).\n",
            "Use cached_ncbi_resources() to see what is available locally."),
            call. = FALSE)
        stop(sprintf(paste0(
          "No local cache for '%s' taxid %s and the OSN bucket is unreachable.\n",
          "Call cache_by_taxon(%s) when online to enable offline access.\n",
          "Use cached_ncbi_resources() to see what is available locally."),
          gres, as.character(taxid), as.character(taxid)), call. = FALSE)
      }
    )
    if (!gres %in% avail)
      stop(sprintf(
        "'%s' is not an available resource.\nCall available_ncbi_parquet() to see options.",
        gres))
  }

  if (!is.null(local)) {
    vname  <- paste0("v_local_", gsub("[^A-Za-z0-9]", "_", gres), "_", taxid)
    taxcol <- .taxid_column(gres)
    DBI::dbExecute(con, sprintf(
      "CREATE OR REPLACE VIEW %s AS SELECT * FROM read_parquet('%s')", vname, local))
    tbl <- dplyr::tbl(con, vname)
    return(dplyr::select(tbl, -dplyr::all_of(taxcol)))
  }

  url   <- ngurl(gres)
  vname <- paste0("v_", gsub("[^A-Za-z0-9]", "_", gres))
  DBI::dbExecute(con, sprintf(
    "CREATE OR REPLACE VIEW %s AS SELECT * FROM read_parquet('%s')", vname, url))
  taxcol <- .taxid_column(gres)
  tbl <- dplyr::tbl(con, vname)
  if (!is.null(taxid))
    tbl <- dplyr::filter(tbl, .data[[taxcol]] == taxid) |>
           dplyr::select(-dplyr::all_of(taxcol))
  tbl
}
