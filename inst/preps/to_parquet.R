# Convert one NCBI Gene .gz (tab-delimited) file to parquet.
# Usage: Rscript to_parquet.R <input.gz> <output.parquet>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2)
  stop("Usage: Rscript to_parquet.R <input.gz> <output.parquet>")

gz_file     <- args[1]
parquet_file <- args[2]

library(DBI)
library(duckdb)

# Cache the httpfs extension permanently and ensure duckdb can create its
# temp workspace under tempdir() (it needs the parent dir to pre-exist).
ext_dir  <- tools::R_user_dir("RNCBIGene", "data")
duck_tmp <- file.path(tempdir(), "duckdb")
dir.create(ext_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(duck_tmp, recursive = TRUE, showWarnings = FALSE)
options(duckdb.extension_directory = ext_dir)

con <- dbConnect(duckdb())
on.exit(dbDisconnect(con, shutdown = TRUE))

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
