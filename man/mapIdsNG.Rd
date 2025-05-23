% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mapIdsNG.R
\name{mapIdsNG}
\alias{mapIdsNG}
\title{very preliminary analog of mapIds from AnnotationDbi, uses remote query to parquet
for NCBI gene_info; the NG connotes NCBI Gene}
\usage{
mapIdsNG(
  taxid = 9606L,
  keys = c("ORMDL3", "TP53", "GSDMB", "XyZZY"),
  keytype = "Symbol",
  column = c("GeneID")
)
}
\arguments{
\item{taxid}{integer(1) integer code for species, defaults to 9606L for Homo sapiens}

\item{keys}{a vector of keys to be translated}

\item{keytype}{character(1), at present, some column of the gene_info.parquet dataset}

\item{column}{character(1), a name of a column of the gene_info.parquet dataset}
}
\description{
very preliminary analog of mapIds from AnnotationDbi, uses remote query to parquet
for NCBI gene_info; the NG connotes NCBI Gene
}
\note{
At present this function only uses `remote_gene_query`.  A `left_join` is conducted
between the data.frame composed of keys, and the query result, with multiple parameter
set to "first".
}
\examples{
if (is_online()) {
mapIdsNG()
if (requireNamespace("airway") && requireNamespace("tidySummarizedExperiment")) {
  data(airway, package="airway")
  tse = as(airway, "tidySummarizedExperiment")
  print(tse)
  tse = tse |> dplyr::mutate(map_location=mapIdsNG(keys=.feature, keytype="Ensembl", column="map_location"))
  tse = tse |> dplyr::mutate(MIM=mapIdsNG(keys=.feature, keytype="Ensembl", column="MIM"))
  print(tse)
  head(table(SummarizedExperiment::rowData(tse)$map_location))
 }
}
}
