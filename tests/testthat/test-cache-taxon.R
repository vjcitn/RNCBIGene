skip_if_offline <- function() skip_if_not(is_online(), "no internet connection")

# Redirect the package-level cache to a temp directory for the duration of a
# test, then restore it.  This ensures cache_by_taxon and open_ncbi_gene see
# the same cache without touching the user's real BiocFileCache.
with_tmp_cache <- function(code) {
  env <- RNCBIGene:::.rncbigene_env
  old <- if (exists("cache", envir = env)) env$cache else NULL
  env$cache <- BiocFileCache::BiocFileCache(tempfile())
  on.exit({
    if (is.null(old)) rm("cache", envir = env) else env$cache <- old
  }, add = TRUE)
  force(code)
}

test_that("cache_by_taxon writes a local parquet to BiocFileCache", {
  skip_if_offline()
  with_tmp_cache({
    paths <- cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    expect_true(file.exists(paths[["gene_orthologs"]]))
    expect_true(grepl("\\.parquet$", paths[["gene_orthologs"]]))
  })
})

test_that("taxon_cache_info reflects a cached entry", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    info <- taxon_cache_info(10090L)
    expect_s3_class(info, "data.frame")
    expect_true(nrow(info) >= 1L)
    expect_true("gene_orthologs_taxid10090.parquet" %in% info$rname)
    expect_true("create_time" %in% colnames(info))
  })
})

test_that("taxon_cache_info with NULL taxid lists all cached entries", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    info <- taxon_cache_info()
    expect_true(nrow(info) >= 1L)
  })
})

test_that("open_ncbi_gene routes to local cache — view is named v_local_*", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    open_ncbi_gene("gene_orthologs", taxid = 10090L)
    tables <- DBI::dbListTables(ncbi_gene_con())
    expect_true(any(grepl("^v_local_gene_orthologs_10090$", tables)))
  })
})

test_that("open_ncbi_gene with local cache returns correct row count", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    n <- open_ncbi_gene("gene_orthologs", taxid = 10090L) |>
      dplyr::tally() |> dplyr::collect() |> dplyr::pull(n)
    expect_gt(n, 0L)
  })
})

test_that("cache_by_taxon skips already-cached resources when force=FALSE", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    msgs <- character(0)
    withCallingHandlers(
      cache_by_taxon(10090L, resources = "gene_orthologs",
                     force = FALSE, verbose = TRUE),
      message = function(m) {
        msgs <<- c(msgs, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    )
    expect_true(any(grepl("already cached", msgs)))
  })
})

test_that("cache_by_taxon force=TRUE overwrites existing entry", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    cache_by_taxon(10090L, resources = "gene_orthologs",
                   force = TRUE, verbose = FALSE)
    info <- taxon_cache_info(10090L)
    expect_equal(nrow(info), 1L)
  })
})

test_that("clear_taxon_cache removes entries for a specific taxid", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    expect_equal(nrow(taxon_cache_info(10090L)), 1L)
    clear_taxon_cache(10090L)
    expect_equal(nrow(taxon_cache_info(10090L)), 0L)
  })
})

test_that("clear_taxon_cache with NULL removes all taxon entries", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    clear_taxon_cache()
    expect_equal(nrow(taxon_cache_info()), 0L)
  })
})

test_that("freeze_taxon_cache copies live entry under a new key", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs")
    info <- taxon_cache_info(10090L)
    expect_true(any(grepl("frozen_v1", info$rname)))
    expect_true(any(!grepl("frozen", info$rname)))  # live entry still present
  })
})

test_that("freeze_taxon_cache rejects a duplicate tag without force", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs")
    expect_error(
      freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs"),
      "already exists"
    )
  })
})

test_that("freeze_taxon_cache force=TRUE overwrites existing frozen entry", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs")
    expect_no_error(
      freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs",
                         force = TRUE)
    )
    info <- taxon_cache_info(10090L)
    expect_equal(sum(grepl("frozen_v1", info$rname)), 1L)
  })
})

test_that("open_ncbi_gene with freeze_tag uses frozen snapshot", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs")
    tbl <- open_ncbi_gene("gene_orthologs", taxid = 10090L, freeze_tag = "v1")
    n   <- dplyr::tally(tbl) |> dplyr::collect() |> dplyr::pull(n)
    expect_gt(n, 0L)
    tables <- DBI::dbListTables(ncbi_gene_con())
    expect_true(any(grepl("v_local_gene_orthologs_10090", tables)))
  })
})

test_that("open_ncbi_gene fails with clear message for unknown freeze_tag", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    expect_error(
      open_ncbi_gene("gene_orthologs", taxid = 10090L, freeze_tag = "nonexistent"),
      "No frozen snapshot"
    )
  })
})

test_that("frozen snapshot survives clear_taxon_cache of live entries", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    freeze_taxon_cache(10090L, tag = "v1", resources = "gene_orthologs")
    clear_taxon_cache(10090L)
    # live entry gone, frozen entry survives
    info <- taxon_cache_info(10090L)
    expect_true(any(grepl("frozen_v1", info$rname)))
    # can still query via freeze_tag
    n <- open_ncbi_gene("gene_orthologs", taxid = 10090L, freeze_tag = "v1") |>
      dplyr::tally() |> dplyr::collect() |> dplyr::pull(n)
    expect_gt(n, 0L)
  })
})

test_that("cached result has no #tax_id column", {
  skip_if_offline()
  with_tmp_cache({
    cache_by_taxon(10090L, resources = "gene_orthologs", verbose = FALSE)
    cols <- open_ncbi_gene("gene_orthologs", taxid = 10090L) |>
      head(1) |> dplyr::collect() |> colnames()
    expect_false("#tax_id" %in% cols)
  })
})
