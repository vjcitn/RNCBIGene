#' retrieve a vector of taxonomy names indexed by taxonomy codes
#' @note retrieved from https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/taxdump_readme.txt
#' Feb 22 2025
#' @examples
#' tmap = taxonomyMap()
#' tmap['9606']
#' @export
taxonomyMap = function() {
 readRDS(system.file("extdata", "taxonomyMap.rds", package="RNCBIGene"))
}
