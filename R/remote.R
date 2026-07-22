
.rncbigene_env <- new.env(parent = emptyenv())

ngurl <- function(gres = "gene2pubmed") {
  sprintf("https://mghp.osn.xsede.org/bir190004-bucket01/BiocParquetNCBI/%s.parquet", gres)
}

#' get or create a persistent duckdb connection with httpfs loaded
#' @return a DBI connection to an in-process duckdb instance
#' @export
ncbi_gene_con <- function() {
  if (!exists("con", envir = .rncbigene_env) ||
      !DBI::dbIsValid(.rncbigene_env$con)) {
    con <- DBI::dbConnect(duckdb::duckdb())
    DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
    .rncbigene_env$con <- con
  }
  .rncbigene_env$con
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
  con   <- ncbi_gene_con()
  gres  <- sub("\\.parquet$", "", resource)
  url   <- ngurl(gres)
  vname <- paste0("v_", gsub("[^A-Za-z0-9]", "_", gres))
  DBI::dbExecute(con, sprintf(
    "CREATE OR REPLACE VIEW %s AS SELECT * FROM read_parquet('%s')", vname, url))
  tbl <- dplyr::tbl(con, vname)
  if (!is.null(taxid))
    tbl <- dplyr::filter(tbl, .data[["#tax_id"]] == taxid)
  tbl
}

#' use duckdb to query NCBI Gene data in OSN bucket
#' @importFrom duckdb duckdb
#' @param gres name of a gene resource, no suffix, see available_gene_parquet vector (unexported)
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
