# Write provenance.json recording the NCBI FTP Last-Modified date for each
# resource.  Called by the GNUmakefile provenance target.
#
# Usage: Rscript make_provenance.R <output.json> <ncbi_base_url> <resource> ...

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3)
  stop("Usage: Rscript make_provenance.R <output.json> <ncbi_base_url> <resource> ...")

out_file  <- args[1]
ncbi_base <- args[2]
resources <- args[-(1:2)]

converted <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

get_last_modified <- function(resource, base) {
  url <- sprintf("%s/%s.gz", base, resource)
  headers <- tryCatch(
    system(sprintf("curl -sI '%s'", url), intern = TRUE),
    error = function(e) character(0))
  lm <- grep("^Last-Modified:", headers, value = TRUE, ignore.case = TRUE)[1]
  if (is.na(lm)) return(NA_character_)
  trimws(sub("^Last-Modified:\\s*", "", lm, ignore.case = TRUE))
}

message("Fetching Last-Modified headers from NCBI FTP ...")
entries <- vapply(resources, get_last_modified, character(1), base = ncbi_base)

# Write JSON without depending on jsonlite
lines <- "{"
rows <- mapply(function(r, lm) {
  sprintf('  "%s.parquet": {"ncbi_last_modified": "%s", "converted": "%s"}',
          r, if (is.na(lm)) "" else lm, converted)
}, resources, entries)
lines <- c(lines, paste(rows, collapse = ",\n"), "}")
writeLines(lines, out_file)
message("wrote ", out_file)
