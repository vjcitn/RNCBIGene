skip_if_offline <- function() skip_if_not(is_online(), "no internet connection")

# ── available_ncbi_parquet() ─────────────────────────────────────────────────

test_that("available_ncbi_parquet returns a character vector when online", {
  skip_if_offline()
  res <- available_ncbi_parquet()
  expect_type(res, "character")
  expect_true(length(res) > 0)
  expect_true(all(grepl("\\.parquet$", res)))
})

test_that("available_ncbi_parquet includes core resources", {
  skip_if_offline()
  res <- available_ncbi_parquet()
  expect_true("gene_info.parquet"    %in% res)
  expect_true("gene2go.parquet"      %in% res)
  expect_true("gene2ensembl.parquet" %in% res)
})

# ── open_ncbi_gene() resource validation ─────────────────────────────────────

test_that("open_ncbi_gene rejects an unknown resource", {
  skip_if_offline()
  expect_error(
    open_ncbi_gene("gene2banana"),
    "not an available resource"
  )
})

test_that("open_ncbi_gene accepts resource with or without .parquet suffix", {
  skip_if_offline()
  tbl1 <- open_ncbi_gene("gene_info")
  tbl2 <- open_ncbi_gene("gene_info.parquet")
  expect_s3_class(tbl1, "tbl")
  expect_s3_class(tbl2, "tbl")
})

test_that("open_ncbi_gene returns a lazy tbl (not a data.frame)", {
  skip_if_offline()
  tbl <- open_ncbi_gene("gene_info")
  expect_false(inherits(tbl, "data.frame"))
  expect_true(inherits(tbl, "tbl_lazy"))
})

test_that("open_ncbi_gene drops #tax_id when taxid is specified", {
  skip_if_offline()
  cols <- open_ncbi_gene("gene_info", taxid = 9606L) |>
    head(1) |> dplyr::collect() |> colnames()
  expect_false("#tax_id" %in% cols)
})

test_that("open_ncbi_gene retains #tax_id when taxid is NULL", {
  skip_if_offline()
  cols <- open_ncbi_gene("gene_info") |>
    head(1) |> dplyr::collect() |> colnames()
  expect_true("#tax_id" %in% cols)
})

test_that("joining two taxid-filtered resources produces no #tax_id.x / #tax_id.y", {
  skip_if_offline()
  local_ids <- data.frame(GeneID = c(94103L, 7157L))
  go_tbl <- join_ncbi_gene(local_ids, by = "GeneID",
                            resource = "gene2go", taxid = 9606L) |>
    dplyr::select(GeneID, GO_ID, GO_term) |>
    dplyr::collect()
  refseq_tbl <- join_ncbi_gene(local_ids, by = "GeneID",
                                resource = "gene2refseq", taxid = 9606L) |>
    dplyr::select(GeneID, RNA_nucleotide_accession.version) |>
    dplyr::filter(.data[["RNA_nucleotide_accession.version"]] != "-") |>
    dplyr::collect()
  combined <- dplyr::left_join(go_tbl, refseq_tbl, by = "GeneID",
                               relationship = "many-to-many")
  expect_false("#tax_id.x" %in% colnames(combined))
  expect_false("#tax_id.y" %in% colnames(combined))
})

test_that("open_ncbi_gene taxid filter reduces rows vs no filter", {
  skip_if_offline()
  n_human <- open_ncbi_gene("gene_info", taxid = 9606L) |>
    dplyr::tally() |> dplyr::collect() |> dplyr::pull(n)
  n_all <- open_ncbi_gene("gene_info") |>
    dplyr::tally() |> dplyr::collect() |> dplyr::pull(n)
  expect_lt(n_human, n_all)
})

# ── ncbi_gene_fields() ───────────────────────────────────────────────────────

test_that("ncbi_gene_fields returns a data.frame with expected columns", {
  skip_if_offline()
  fields <- ncbi_gene_fields("gene_info")
  expect_s3_class(fields, "data.frame")
  expect_named(fields, c("column_name", "column_type"))
  expect_true("Symbol"   %in% fields$column_name)
  expect_true("GeneID"   %in% fields$column_name)
  expect_true("#tax_id"  %in% fields$column_name)
})

test_that("ncbi_gene_fields rejects an unknown resource", {
  skip_if_offline()
  expect_error(ncbi_gene_fields("gene2banana"), "not an available resource")
})

test_that("ncbi_gene_fields returns different schemas for different resources", {
  skip_if_offline()
  gi  <- ncbi_gene_fields("gene_info")
  g2g <- ncbi_gene_fields("gene2go")
  expect_true("Symbol" %in% gi$column_name)
  expect_false("Symbol" %in% g2g$column_name)
  expect_true("GO_ID"  %in% g2g$column_name)
})

# ── join_ncbi_gene() validation ───────────────────────────────────────────────

test_that("join_ncbi_gene rejects an unknown resource", {
  skip_if_offline()
  local_df <- data.frame(GeneID = 94103L)
  expect_error(
    join_ncbi_gene(local_df, by = "GeneID", resource = "gene2banana"),
    "not an available resource"
  )
})

test_that("join_ncbi_gene rejects by-column absent from local_df", {
  skip_if_offline()
  local_df <- data.frame(Symbol = "TP53")
  expect_error(
    join_ncbi_gene(local_df, by = "GeneID", resource = "gene_info"),
    "not found in local_df"
  )
})

test_that("join_ncbi_gene rejects by-column absent from remote resource", {
  skip_if_offline()
  local_df <- data.frame(Banana = "TP53")
  expect_error(
    join_ncbi_gene(local_df, by = "Banana", resource = "gene_info"),
    "not found in 'gene_info'"
  )
})

test_that("join_ncbi_gene rejects invalid type argument", {
  skip_if_offline()
  local_df <- data.frame(GeneID = 94103L)
  expect_error(
    join_ncbi_gene(local_df, by = "GeneID", resource = "gene_info",
                   type = "outer") |> dplyr::collect(),
    "type must be"
  )
})

test_that("join_ncbi_gene returns a lazy tbl", {
  skip_if_offline()
  local_df <- data.frame(Symbol = c("TP53", "BRCA1"))
  result <- join_ncbi_gene(local_df, by = "Symbol",
                            resource = "gene_info", taxid = 9606L)
  expect_true(inherits(result, "tbl_lazy"))
})

# ── mapIdsNG() keytype validation ─────────────────────────────────────────────

test_that("mapIdsNG rejects an unsupported keytype", {
  skip_if_offline()
  expect_error(
    mapIdsNG(keys = "TP53", keytype = "MIM", column = "GeneID"),
    "keytype not supported"
  )
})

test_that("mapIdsNG returns NA for unrecognised keys", {
  skip_if_offline()
  result <- mapIdsNG(keys = c("TP53", "XyZZY"), keytype = "Symbol",
                     column = "GeneID")
  expect_true(is.na(result["XyZZY"]))
  expect_false(is.na(result["TP53"]))
})

test_that("mapIdsNG output is named and conformant to input", {
  skip_if_offline()
  keys   <- c("ORMDL3", "TP53", "XyZZY")
  result <- mapIdsNG(keys = keys, keytype = "Symbol", column = "GeneID")
  expect_named(result, keys)
  expect_length(result, length(keys))
})
