# Download NCBI Gene text files and convert to parquet.
#
# Run from inst/preps/ (or any working directory -- parquet lands where make runs).
#
# Targets:
#   make download            fetch all .gz files into a YYYYMMDD/ folder
#   make parquet SRCDIR=...  convert that folder's .gz files to .parquet here
#   make all                 download then convert (uses today's date for both)
#   make clean SRCDIR=...    remove the downloaded .gz folder (keeps .parquet)
#
# The SRCDIR variable names the folder holding the .gz files.
# It defaults to today's date (YYYYMMDD) so successive runs are self-labelling.

NCBI_BASE := https://ftp.ncbi.nlm.nih.gov/gene/DATA

RESOURCES := \
  gene2accession       \
  gene2ensembl         \
  gene2go              \
  gene2pubmed          \
  gene2refseq          \
  gene_info            \
  gene_orthologs       \
  gene_refseq_uniprotkb_collab

TIMESTAMP := $(shell date +%Y%m%d)
SRCDIR    ?= $(TIMESTAMP)

GZ_FILES      := $(addprefix $(SRCDIR)/, $(addsuffix .gz,      $(RESOURCES)))
PARQUET_FILES := $(addsuffix .parquet, $(RESOURCES))

RSCRIPT    := Rscript
SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: all download parquet clean

all: download parquet

# ── Download ────────────────────────────────────────────────────────────────

download: $(SRCDIR) $(GZ_FILES)

$(SRCDIR):
	mkdir -p $@

# -C - resumes a partial download; -L follows redirects
$(SRCDIR)/%.gz: | $(SRCDIR)
	curl -C - -L -o $@ $(NCBI_BASE)/$*.gz

# ── Parquet conversion ───────────────────────────────────────────────────────

parquet: $(PARQUET_FILES)

%.parquet: $(SRCDIR)/%.gz $(SCRIPT_DIR)to_parquet.R
	$(RSCRIPT) $(SCRIPT_DIR)to_parquet.R $< $@

# ── Housekeeping ─────────────────────────────────────────────────────────────

clean:
	rm -rf $(SRCDIR)
