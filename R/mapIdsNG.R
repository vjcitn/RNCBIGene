#' very preliminary analog of mapIds from AnnotationDbi, uses remote query to parquet
#' for NCBI gene_info; the NG connotes NCBI Gene
#' @param taxid integer(1) integer code for species, defaults to 9606L for Homo sapiens
#' @param keys a vector of keys to be translated
#' @param keytype character(1), at present, some column of the gene_info.parquet dataset
#' @param columns character(), a subset of columns of the gene_info.parquet dataset
#' @note At present this function only uses `remote_gene_query`
#' @examples
#' if (interactive()) {
#' mapIdsNG()
#' }
#' @export
mapIdsNG = function(taxid = 9606L, keys=c("ORMDL3", "TP53", "GSDMB", "XyZZY"), keytype="Symbol", 
   columns=c("GeneID", "type_of_gene", "description")) {
# try to improve the following, which will extract all records for the taxon
 dat = remote_gene_query("gene_info", qual=sprintf('where "#tax_id" == %s', taxid)) |> collect()
# "filter" doesn't work well for %in% in this application
 ok = which(dat[[keytype]] %in% keys)
# filter and select, classic way
 dat = dat[ok,c(keytype,columns)]
# now deal with order of the request.
 odf = data.frame(x=keys)
 names(odf) = keytype
 left_join(odf, dat, by=keytype)
}
