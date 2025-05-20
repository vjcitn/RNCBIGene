#' obtain references to parquet serializations of slices
#' of NCBI Gene annotation
#' @examples
#' ng = NGparq()
#' sapply(ng, nrow)
#' @export
NGparq = function() {
 litp = dir(system.file("litparquet", package="RNCBIGene"), full.names=TRUE)
 litpop = lapply(litp,
     arrow::open_dataset)
 ns = basename(litp)
 names(litpop) = ns
 class(litpop) = c("NGparq", "list")
 litpop
}

#' print method for NGparq list
#' @param x instance of S3 class NGparq
#' @param \dots not used
#' @export
print.NGparq = function(x, ...) {
 cat("NGparq instance with components:\n ")
 cat(names(x), sep="\n ")
 cat("\n")
}
 
#' given an element of a bar-delimited string as produced for dbXrefs in gene_info,
#' extract the value associated with a given tag
#' @param x character(1)
#' @param tag substring to use to find desired value
processDbx1 = function (x, tag="Ensembl:") 
{
    ans = NA
    ind = grep(tag, x)
    if (length(ind) > 0) 
        ans = sub(tag, "", x[ind[1]])
    ans
}


#' given a bar-delimited string as produced for dbXrefs in gene_info,
#' extract the value associated with a given tag
#' @param x character(1)
#' @param tag substring to use to find desired value
#' @examples
#' dem = "MIM:611221|HGNC:HGNC:23690|Ensembl:ENSG00000073605|AllianceGenome:HGNC:23690"
#' processDbx(dem, tag="MIM:")
#' @export
processDbx = function (x, tag = "Ensembl:") 
{
    chk = strsplit(x, "\\|")
    sapply(chk, processDbx1, tag)
}


