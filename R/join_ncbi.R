#' join a local data frame to a remote NCBI Gene parquet resource
#' @param local_df data.frame to join against the remote resource
#' @param by character vector of column name(s) to join on
#' @param resource character(1) parquet resource name, with or without .parquet suffix
#' @param taxid integer(1) or NULL; when non-NULL, pre-filters the remote resource to this taxonomy ID
#' @param type character(1) "left" (default) or "inner"
#' @return lazy dplyr::tbl -- pipe select/filter/collect as needed
#' @note local_df is written to the persistent duckdb session. The returned tbl is lazy;
#'   call collect() to retrieve results. Both sides of the join run entirely in duckdb.
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
  con <- ncbi_gene_con()
  tmp <- paste0("local_", gsub("[^A-Za-z0-9]", "_", basename(tempfile())))
  DBI::dbWriteTable(con, tmp, local_df, overwrite = TRUE)
  remote_tbl <- open_ncbi_gene(resource, taxid)
  local_tbl  <- dplyr::tbl(con, tmp)
  switch(type,
    left  = dplyr::left_join(local_tbl,  remote_tbl, by = by),
    inner = dplyr::inner_join(local_tbl, remote_tbl, by = by),
    stop("type must be 'left' or 'inner'")
  )
}
