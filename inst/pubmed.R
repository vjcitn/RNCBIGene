# after gene2pubmed.gz is retrieved from https://ftp.ncbi.nih.gov/gene/DATA/
# note that gene2accession requires significant RAM (>100GB) with this approach

library(DBI)
library(duckdb)

con = dbConnect(duckdb())

dbExecute(con, "
  CREATE TABLE gene2pubmed AS 
  SELECT * 
  FROM read_csv_auto(
    'gene2pubmed.gz',
    delim = '\t',
    header = true,
    compression = 'gzip',
    ignore_errors=TRUE
  )
")

dbExecute(con, "COPY (FROM gene2pubmed) TO 'gene2pubmed.parquet' (FORMAT parquet, COMPRESSION zstd)")

