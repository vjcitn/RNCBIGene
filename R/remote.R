
ngurl = function(gres="gene2pubmed") {
  pmd = sprintf("https://mghp.osn.xsede.org/bir190004-bucket01/BiocParquetNCBI/%s.parquet", gres)
}

#' use duckdb to query NCBI Gene data in OSN bucket
#' @importFrom duckdb duckdb
#' @param gres name of a gene resource, no suffix, see available_gene_parquet vector (unexported)
#' @param qual a SQL fragment used to qualify a select * clause
#' @param tname character(1) arbitrary name to use for internal sql table
#' @note The httpfs extension for duckdb is installed when the function is called.
#' @examples
#' if (interactive()) {
#' remote_gene_query(qual = 'where "#tax_id" = 9606 limit 10;')
#' }
#' @export
remote_gene_query = function(gres = "gene2pubmed", qual = "limit 5", tname=basename(tempfile())) {
  pmd = ngurl(gres)
  con = DBI::dbConnect(duckdb::duckdb())
  DBI::dbExecute(con, "INSTALL httpfs;")
  DBI::dbExecute(con, sprintf('create table %s as select * from read_parquet(%s) %s;', tname, dQuote(pmd, q=FALSE),
      qual))
  
  on.exit(DBI::dbDisconnect(con))
  dplyr::tbl(con, tname) |> dplyr::collect()
  
}
