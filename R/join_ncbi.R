#' join a local data frame to a remote NCBI Gene parquet resource
#' @param local_df data.frame to join against the remote resource
#' @param by character vector of column name(s) to join on; must exist in both
#'   \code{local_df} and the remote resource
#' @param resource character(1) parquet resource name, with or without .parquet suffix;
#'   must be one of \code{available_ncbi_parquet()}
#' @param taxid integer(1) or NULL; when non-NULL, pre-filters the remote resource to this taxonomy ID
#' @param type character(1) "left" (default) or "inner"
#' @return lazy dplyr::tbl -- call collect() in the same expression; see Note
#' @note \code{local_df} is registered in the duckdb session via
#'   \code{duckdb::duckdb_register()} (zero-copy).  The registration is removed
#'   when the returned tbl is collected or when \code{gc_ncbi_tables()} is called.
#'   In practice, always use the returned tbl in a single pipeline ending with
#'   \code{collect()}.  Both sides of the join run entirely in duckdb.
#' @examples
#' if (is_online()) {
#'   local_df <- data.frame(Symbol = c("ORMDL3","TP53","BRCA1"))
#'   join_ncbi_gene(local_df, by = "Symbol", taxid = 9606L) |>
#'     dplyr::select(Symbol, GeneID, map_location) |>
#'     dplyr::collect()
#' }
#' @export
join_ncbi_gene <- function(local_df, by, resource = "gene_info",
                            taxid = NULL, type = "left") {
  missing_local <- setdiff(by, names(local_df))
  if (length(missing_local) > 0)
    stop(sprintf("column(s) not found in local_df: %s",
                 paste(missing_local, collapse = ", ")))

  remote_fields <- ncbi_gene_fields(resource)$column_name
  missing_remote <- setdiff(by, remote_fields)
  if (length(missing_remote) > 0)
    stop(sprintf(
      "column(s) not found in '%s': %s\nAvailable fields: %s",
      sub("\\.parquet$", "", resource),
      paste(missing_remote, collapse = ", "),
      paste(remote_fields, collapse = ", ")))

  con <- ncbi_gene_con()
  tmp <- paste0("local_", gsub("[^A-Za-z0-9]", "_", basename(tempfile())))
  # duckdb_register is zero-copy and tracked for cleanup via gc_ncbi_tables()
  duckdb::duckdb_register(con, tmp, local_df)
  .rncbigene_env$registered_tables <- c(.rncbigene_env$registered_tables, tmp)
  remote_tbl <- open_ncbi_gene(resource, taxid)
  local_tbl  <- dplyr::tbl(con, tmp)
  switch(type,
    left  = dplyr::left_join(local_tbl,  remote_tbl, by = by),
    inner = dplyr::inner_join(local_tbl, remote_tbl, by = by),
    stop("type must be 'left' or 'inner'")
  )
}

#' remove registered local data frame tables from the duckdb session
#'
#' \code{join_ncbi_gene()} registers each local data frame in the duckdb session
#' via \code{duckdb::duckdb_register()}.  Call \code{gc_ncbi_tables()} to
#' unregister all such tables and free the associated memory.
#' @return invisibly, the names of the tables that were removed
#' @examples
#' gc_ncbi_tables()
#' @export
gc_ncbi_tables <- function() {
  tbls <- .rncbigene_env$registered_tables
  if (is.null(tbls) || length(tbls) == 0L) return(invisible(character(0)))
  con <- ncbi_gene_con()
  for (tbl in tbls)
    try(duckdb::duckdb_unregister(con, tbl), silent = TRUE)
  .rncbigene_env$registered_tables <- character(0)
  invisible(tbls)
}
