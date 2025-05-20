#' very preliminary analog of mapIds from AnnotationDbi, uses remote query to parquet
#' for NCBI gene_info; the NG connotes NCBI Gene
#' @param taxid integer(1) integer code for species, defaults to 9606L for Homo sapiens
#' @param keys a vector of keys to be translated
#' @param keytype character(1), at present, some column of the gene_info.parquet dataset
#' @param column character(1), a name of a column of the gene_info.parquet dataset
#' @note At present this function only uses `remote_gene_query`.  A `left_join` is conducted
#' between the data.frame composed of keys, and the query result, with multiple parameter
#' set to "first".
#' @examples
#' if (interactive()) {
#' mapIdsNG()
#' if (requireNamespace("airway") && requireNamespace("tidySummarizedExperiment")) {
#'   data(airway, package="airway")
#'   tse = as(airway, "tidySummarizedExperiment")
#'   print(tse)
#'   tse = tse |> dplyr::mutate(map_location=mapIdsNG(keys=.feature, keytype="Ensembl", column="map_location"))
#'   tse = tse |> dplyr::mutate(MIM=mapIdsNG(keys=.feature, keytype="Ensembl", column="MIM"))
#'   print(tse)
#'   head(table(SummarizedExperiment::rowData(tse)$map_location))
#'  }
#' }
#' @export
mapIdsNG = function(taxid = 9606L, keys=c("ORMDL3", "TP53", "GSDMB", "XyZZY"), keytype="Symbol", 
   column=c("GeneID")) {
   stopifnot(length(column)==1 && is.atomic(column))
# verify keytype
   if (!(keytype %in% c("Symbol", "Ensembl", "MIM"))) stop(sprintf("%s keytype not supported, file issue", keytype))
# try to improve the following, which will extract all records for the taxon
 dat = remote_gene_query("gene_info", qual=sprintf('where "#tax_id" == %s', taxid)) |> collect()
 if (keytype %in% c("Ensembl", "MIM")) {
    tag = paste0(keytype, ":")
    nvec = dat |> select(dbXrefs) |> pull() |> processDbx(tag=tag)
    dat[[keytype]] = nvec
    }
# now work on column request, need to stuff it in dat
    if (column == "Ensembl") {
      nvec = dat |> select(dbXrefs) |> pull() |> processDbx(tag="Ensembl:")
      dat$Ensembl = nvec
      }
    else if (column == "MIM") {
      nvec = dat |> select(dbXrefs) |> pull() |> processDbx(tag="MIM:")
      dat$MIM = nvec
      }
    unk = setdiff(column, colnames(dat))
    if (length(unk)>0) {
       message("unknown column request ignored")
       cat(unk, sep="\n")
       }
# "filter" doesn't work well for %in% in this application
 ok = which(dat[[keytype]] %in% keys)
# filter and select, classic way
 dat = dat[ok,c(keytype,column)]
# now deal with order of the request.
 odf = data.frame(x=keys)
 names(odf) = keytype
 left_join(odf, dat, by=keytype, multiple="first") |> dplyr::pull()  # should be vector conformant to input
}
