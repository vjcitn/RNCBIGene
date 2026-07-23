
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
.cached_parquet_path <- function(gres, taxid) {
  if (is.null(taxid)) return(NULL)
  key <- sprintf("%s_taxid%s.parquet", gres, taxid)
  pa  <- BiocFileCache::bfcquery(.ncbi_cache(), key, field = "rname")
  if (nrow(pa) == 1L) pa$rpath else NULL
}

#' get or create a persistent duckdb connection with httpfs loaded
#'
#' The duckdb httpfs extension is cached in a permanent user directory
#' (via \code{tools::R_user_dir}) so it is not re-downloaded each session.
#' The directory can be inspected with
#' \code{tools::R_user_dir("RNCBIGene", "data")}.
#' @return a DBI connection to an in-process duckdb instance
#' @export
ncbi_gene_con <- function() {
  if (!exists("con", envir = .rncbigene_env) ||
      !DBI::dbIsValid(.rncbigene_env$con)) {
    ext_dir <- tools::R_user_dir("RNCBIGene", "data")
    if (!dir.exists(ext_dir))
      dir.create(ext_dir, recursive = TRUE)
    options(duckdb.extension_directory = ext_dir)
    con <- DBI::dbConnect(duckdb::duckdb())
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
#' @return lazy dplyr::tbl backed by duckdb -- compose filter/select/collect before pulling data
#' @examples
#' if (is_online()) {
#'   open_ncbi_gene("gene_info", taxid = 9606L) |>
#'     dplyr::filter(Symbol %in% c("TP53","BRCA1")) |>
#'     dplyr::select(Symbol, GeneID, map_location) |>
#'     dplyr::collect()
#' }
#' @export
open_ncbi_gene <- function(resource = "gene_info", taxid = NULL) {
  gres  <- sub("\\.parquet$", "", resource)
  avail <- .ncbi_resource_names()
  if (!gres %in% avail)
    stop(sprintf(
      "'%s' is not an available resource.\nCall available_ncbi_parquet() to see options.",
      gres))
  con   <- ncbi_gene_con()
  local <- .cached_parquet_path(gres, taxid)

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

#' use duckdb to query NCBI Gene data in OSN bucket
#' @importFrom duckdb duckdb
#' @param gres name of a gene resource, no suffix
#' @param qual a SQL fragment used to qualify a select * clause
#' @param tname character(1) arbitrary name to use for internal sql table
#' @param collect logical(1) if TRUE returns a data.frame (legacy behavior); default FALSE returns lazy tbl
#' @note Uses a persistent duckdb connection via ncbi_gene_con(). For composable lazy queries prefer open_ncbi_gene().
#' @examples
#' if (is_online()) {
#'   remote_gene_query(qual = 'where "#tax_id" = 9606 limit 10') |> dplyr::collect()
#' }
#' @export
remote_gene_query <- function(gres = "gene2pubmed", qual = "limit 5",
                               tname = basename(tempfile()), collect = FALSE) {
  pmd <- ngurl(gres)
  con <- ncbi_gene_con()
  DBI::dbExecute(con, sprintf(
    'CREATE TABLE %s AS SELECT * FROM read_parquet(%s) %s;',
    tname, dQuote(pmd, q = FALSE), qual))
  tbl <- dplyr::tbl(con, tname)
  if (collect) dplyr::collect(tbl) else tbl
}
