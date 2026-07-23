skip_if_offline <- function() skip_if_not(is_online(), "no internet connection")

OSN_GOLDEN_URL <- paste0(
  "https://mghp.osn.xsede.org/bir190004-bucket01/",
  "BiocParquetNCBI/test_queries.json"
)

# Parse the bucket golden-query file and validate each query against this
# package.  Tests are skipped when offline.

test_that("golden queries pass against current bucket data", {
  skip_if_offline()

  json_text <- tryCatch(
    paste(readLines(OSN_GOLDEN_URL, warn = FALSE), collapse = ""),
    error = function(e) skip(paste("could not fetch golden query file:", e$message))
  )

  # minimal JSON parser: extract queries array entries
  query_blocks <- strsplit(json_text, '"id"\\s*:')[[1]][-1]

  for (block in query_blocks) {
    id      <- regmatches(block, regexpr('^\\s*"([^"]+)"', block, perl = TRUE))
    id      <- sub('^\\s*"([^"]+)".*', "\\1", id)
    fn_match <- regmatches(block, regexpr('"function"\\s*:\\s*"([^"]+)"', block, perl = TRUE))
    fn      <- sub('.*"function"\\s*:\\s*"([^"]+)".*', "\\1", fn_match)

    if (fn == "available_ncbi_parquet") {
      min_n <- as.integer(
        sub('.*"min_count"\\s*:\\s*(\\d+).*', "\\1", block))
      result <- tryCatch(available_ncbi_parquet(), error = function(e) NULL)
      expect_true(
        !is.null(result) && length(result) >= min_n,
        label = sprintf("golden[%s]: expected >= %d resources", id, min_n)
      )
      next
    }

    if (fn == "map_ids_ng") {
      keys_raw  <- regmatches(block, gregexpr('"[A-Z0-9a-z_-]+"', block, perl = TRUE))[[1]]
      # extract keys, keytype, column, taxid from the block
      args_block <- sub('.*"args"\\s*:\\s*\\{([^}]+)\\}.*', "\\1", block)
      keys   <- unlist(regmatches(args_block,
        gregexpr('(?<="keys"\\s*:\\s*\\[)[^\\]]+', args_block, perl = TRUE)))
      keys   <- trimws(unlist(strsplit(keys, ",")))
      keys   <- gsub('"', "", keys)
      keytype <- sub('.*"keytype"\\s*:\\s*"([^"]+)".*', "\\1", args_block)
      column  <- sub('.*"column"\\s*:\\s*"([^"]+)".*', "\\1", args_block)
      taxid   <- as.integer(sub('.*"taxid"\\s*:\\s*(\\d+).*', "\\1", args_block))

      result <- tryCatch(
        mapIdsNG(keys = keys, keytype = keytype, column = column, taxid = taxid),
        error = function(e) {
          fail(sprintf("golden[%s] mapIdsNG errored: %s", id, e$message))
          NULL
        }
      )
      if (is.null(result)) next

      # extract expected key:value pairs
      exp_block <- sub('.*"expected"\\s*:\\s*\\{([^}]*)\\}.*', "\\1", block)
      exp_pairs <- regmatches(exp_block,
        gregexpr('"([^"]+)"\\s*:\\s*([^,}]+)', exp_block, perl = TRUE))[[1]]

      for (pair in exp_pairs) {
        k <- sub('"([^"]+)".*', "\\1", pair)
        v <- trimws(sub('[^:]+:\\s*', "", pair))
        if (v == "null") {
          expect_true(is.na(result[[k]]),
            label = sprintf("golden[%s]: %s should be NA", id, k))
        } else {
          v_parsed <- tryCatch(as.integer(v), warning = function(w) v)
          expect_equal(result[[k]], v_parsed,
            label = sprintf("golden[%s]: %s", id, k))
        }
      }
    }
  }
})
