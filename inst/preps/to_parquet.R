# Convert one NCBI Gene .gz (tab-delimited) file to parquet.
# Usage: Rscript to_parquet.R <input.gz> <output.parquet>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2)
  stop("Usage: Rscript to_parquet.R <input.gz> <output.parquet>")

gz_file     <- args[1]
parquet_file <- args[2]

library(DBI)
library(duckdb)

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
