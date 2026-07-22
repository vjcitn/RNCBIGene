# Convert one NCBI Gene .gz (tab-delimited) file to parquet.
# Usage: Rscript to_parquet.R <input.gz> <output.parquet>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2)
  stop("Usage: Rscript to_parquet.R <input.gz> <output.parquet>")

gz_file     <- args[1]
parquet_file <- args[2]

library(DBI)
library(duckdb)

# Cache the httpfs extension permanently.
ext_dir <- tools::R_user_dir("RNCBIGene", "data")
dir.create(ext_dir, recursive = TRUE, showWarnings = FALSE)
options(duckdb.extension_directory = ext_dir)

# Use a temp dir in cwd (same disk as the output parquet, adequate space).
# Cleaned up on exit.
duck_tmp <- file.path(getwd(), ".duckdb_tmp")
dir.create(duck_tmp, recursive = TRUE, showWarnings = FALSE)

con <- dbConnect(duckdb())
on.exit({
  dbDisconnect(con, shutdown = TRUE)
  unlink(duck_tmp, recursive = TRUE)
})

dbExecute(con, sprintf("SET temp_directory='%s'", duck_tmp))
# Reduces memory pressure significantly on large files.
dbExecute(con, "SET preserve_insertion_order=false")

dbExecute(con, sprintf(
  "CREATE TABLE t AS
   SELECT * FROM read_csv_auto('%s',
     delim        = '\t',
     header       = true,
     compression  = 'gzip',
     ignore_errors = true)",
  gz_file))

dbExecute(con, sprintf(
  "COPY (FROM t) TO '%s'
   (FORMAT parquet, COMPRESSION zstd, COMPRESSION_LEVEL 15)",
  parquet_file))

message(sprintf("wrote %s", parquet_file))
