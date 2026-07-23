skip_if_offline <- function() skip_if_not(is_online(), "no internet connection")

OSN_GOLDEN_URL <- paste0(
  "https://mghp.osn.xsede.org/bir190004-bucket01/",
  "BiocParquetNCBI/test_queries.json"
)

test_that("golden queries pass against current bucket data", {
  skip_if_offline()
  if (!requireNamespace("jsonlite", quietly = TRUE))
    skip("jsonlite required to parse golden query file")

  json_text <- tryCatch(
    paste(readLines(OSN_GOLDEN_URL, warn = FALSE), collapse = ""),
    error = function(e) skip(paste("could not fetch golden query file:", e$message))
  )
  queries <- jsonlite::fromJSON(json_text, simplifyDataFrame = FALSE)$queries

  for (q in queries) {
    id       <- q$id
    fn       <- q$`function`
    args     <- q$args
    expected <- q$expected

    if (fn == "available_ncbi_parquet") {
      result <- tryCatch(available_ncbi_parquet(),
                         error = function(e) { fail(sprintf("golden[%s]: %s", id, e$message)); NULL })
      if (!is.null(result))
        expect_gte(length(result), expected$min_count,
                   label = sprintf("golden[%s]: resource count", id))

    } else if (fn == "map_ids_ng") {
      result <- tryCatch(
        mapIdsNG(keys    = args$keys,
                 keytype = args$keytype,
                 column  = args$column,
                 taxid   = args$taxid),
        error = function(e) { fail(sprintf("golden[%s] error: %s", id, e$message)); NULL }
      )
      if (is.null(result)) next
      for (key in names(expected)) {
        exp_val <- expected[[key]]
        got     <- result[[key]]
        if (is.null(exp_val)) {
          expect_true(is.na(got),
                      label = sprintf("golden[%s] key=%s: expected NA", id, key))
        } else {
          expect_equal(got, exp_val,
                       label = sprintf("golden[%s] key=%s", id, key))
        }
      }
    } else {
      message(sprintf("golden[%s]: skipping unknown function '%s'", id, fn))
    }
  }
})
