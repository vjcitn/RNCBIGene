# Download NCBI Gene text files and convert to parquet.
#
# Run from inst/preps/ (or any working directory -- parquet lands where make runs).
#
# Targets:
#   make download              fetch all .gz files into a YYYYMMDD/ folder
#   make parquet SRCDIR=...    convert that folder's .gz files to .parquet here
#   make provenance SRCDIR=... HEAD-request NCBI FTP to record source dates
#   make all                   pull, download, convert, provenance (today's date)
#   make clean SRCDIR=...      remove the downloaded .gz folder (keeps .parquet)
#
# Upload provenance.json and the .parquet files to the OSN bucket manually
# after running all.

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

.PHONY: all download parquet provenance clean pull

all: pull download parquet provenance

pull:
	git -C $(SCRIPT_DIR) pull

# ── Download ─────────────────────────────────────────────────────────────────

download: $(SRCDIR) $(GZ_FILES)

$(SRCDIR):
	mkdir -p $@

# -C - resumes a partial download; -L follows redirects
$(SRCDIR)/%.gz: | $(SRCDIR)
	curl -C - -L -o $@ $(NCBI_BASE)/$*.gz

# ── Parquet conversion ────────────────────────────────────────────────────────

parquet: $(PARQUET_FILES)

%.parquet: $(SRCDIR)/%.gz $(SCRIPT_DIR)to_parquet.R
	$(RSCRIPT) $(SCRIPT_DIR)to_parquet.R $< $@

# ── Provenance ────────────────────────────────────────────────────────────────
# HEAD-request each NCBI FTP source to capture Last-Modified, write
# provenance.json in cwd alongside the .parquet files.

provenance: provenance.json

provenance.json: $(PARQUET_FILES)
	$(RSCRIPT) $(SCRIPT_DIR)make_provenance.R $@ $(NCBI_BASE) $(RESOURCES)

# ── Housekeeping ──────────────────────────────────────────────────────────────

clean:
	rm -rf $(SRCDIR)
