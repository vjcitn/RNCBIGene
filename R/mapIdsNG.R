#' analog of mapIds from AnnotationDbi using lazy duckdb queries on NCBI Gene parquet
#' @param taxid integer(1) taxonomy code, defaults to 9606L for Homo sapiens
#' @param keys character vector of keys to translate
#' @param keytype character(1) one of "Symbol", "GeneID", or "Ensembl"
#' @param column character(1) name of the output annotation column; use "Ensembl" to
#'   retrieve Ensembl gene identifiers via gene2ensembl.parquet
#' @note All filtering is pushed to duckdb before a single collect() retrieves only
#'   the matched rows and columns. Ensembl keytype or column requires gene2ensembl.parquet
#'   in the OSN bucket.
#' @examples
#' if (is_online()) {
#'   mapIdsNG()
#' }
#' @export
mapIdsNG <- function(taxid = 9606L, keys = c("ORMDL3","TP53","GSDMB","XyZZY"),
                     keytype = "Symbol", column = "GeneID") {
  stopifnot(length(column) == 1 && is.atomic(column))
  if (!keytype %in% c("Symbol", "GeneID", "Ensembl"))
    stop(sprintf("%s keytype not supported, file issue", keytype))

  eid_col <- "Ensembl_gene_identifier"

  if (keytype == "Ensembl") {
    g2e <- open_ncbi_gene("gene2ensembl", taxid) |>
             dplyr::filter(.data[[eid_col]] %in% keys) |>
             dplyr::select(dplyr::all_of(c("GeneID", eid_col)))
    if (column == "GeneID") {
      dat <- dplyr::collect(g2e)
    } else {
      info <- open_ncbi_gene("gene_info", taxid) |>
                dplyr::select(dplyr::all_of(c("GeneID", column)))
      dat <- dplyr::left_join(g2e, info, by = "GeneID") |> dplyr::collect()
    }
    names(dat)[names(dat) == eid_col] <- "Ensembl"
    key_col <- "Ensembl"

  } else if (column == "Ensembl") {
    info <- open_ncbi_gene("gene_info", taxid) |>
              dplyr::filter(.data[[keytype]] %in% keys) |>
              dplyr::select(dplyr::all_of(c("GeneID", keytype)))
    g2e  <- open_ncbi_gene("gene2ensembl", taxid) |>
              dplyr::select(dplyr::all_of(c("GeneID", eid_col)))
    dat  <- dplyr::left_join(info, g2e, by = "GeneID") |> dplyr::collect()
    names(dat)[names(dat) == eid_col] <- "Ensembl"
    key_col <- keytype

  } else {
    dat <- open_ncbi_gene("gene_info", taxid) |>
             dplyr::filter(.data[[keytype]] %in% keys) |>
             dplyr::select(dplyr::all_of(c(keytype, column))) |>
             dplyr::collect()
    key_col <- keytype
  }

  odf <- data.frame(x = keys, stringsAsFactors = FALSE)
  names(odf) <- key_col
  vals <- dplyr::left_join(odf, dat[, c(key_col, column), drop = FALSE],
                            by = key_col, multiple = "first") |>
            dplyr::pull()
  if (is.atomic(vals)) names(vals) <- keys
  vals
}
