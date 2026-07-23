# Download NCBI Gene text files and convert to parquet.
#
# Run from any working directory.  Downloaded .gz files go into a YYYYMMDD/
# subfolder of cwd; converted .parquet files and provenance.json go into
# PARQUET_DIR, which is also the source directory for the upload step.
#
# Required environment variables (for parquet, provenance, upload targets):
#   PARQUET_DIR         destination for .parquet files and provenance.json,
#                       and source for rclone upload
#   RCLONE_CONFIG_DIR   path to directory containing rclone.conf (upload only)
#
# Targets:
#   make download              fetch all .gz files into a YYYYMMDD/ folder
#   make parquet SRCDIR=...    convert that folder's .gz files to PARQUET_DIR
#   make provenance SRCDIR=... HEAD-request NCBI FTP to record source dates
#   make upload                push PARQUET_DIR contents to OSN bucket
#   make all                   pull, download, parquet, provenance
#   make clean SRCDIR=...      remove the downloaded .gz folder

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

GZ_FILES      := $(addprefix $(SRCDIR)/, $(addsuffix .gz, $(RESOURCES)))
PARQUET_FILES := $(addprefix $(PARQUET_DIR)/, $(addsuffix .parquet, $(RESOURCES)))
PROVENANCE    := $(PARQUET_DIR)/provenance.json

RSCRIPT    := Rscript
SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PARQUET_DIR_GUARD = $(if $(PARQUET_DIR),,$(error PARQUET_DIR is not set -- export it before running this target))

.PHONY: all download parquet provenance upload dispatch clean pull

all: pull download parquet provenance

pull:
	git -C $(SCRIPT_DIR) pull

# ── Download ──────────────────────────────────────────────────────────────────

download: $(SRCDIR) $(GZ_FILES)

$(SRCDIR):
	mkdir -p $@

# -C - resumes a partial download; -L follows redirects
$(SRCDIR)/%.gz: | $(SRCDIR)
	curl -C - -L -o $@ $(NCBI_BASE)/$*.gz

# ── Parquet conversion ────────────────────────────────────────────────────────

parquet: $(PARQUET_FILES)

$(PARQUET_DIR)/%.parquet: $(SRCDIR)/%.gz $(SCRIPT_DIR)to_parquet.R
	$(PARQUET_DIR_GUARD)
	@mkdir -p $(PARQUET_DIR)
	$(RSCRIPT) $(SCRIPT_DIR)to_parquet.R $< $@

# ── Provenance ────────────────────────────────────────────────────────────────

provenance: $(PROVENANCE)

$(PROVENANCE): $(PARQUET_FILES)
	$(PARQUET_DIR_GUARD)
	$(RSCRIPT) $(SCRIPT_DIR)make_provenance.R $@ $(NCBI_BASE) $(RESOURCES)

# ── Upload ────────────────────────────────────────────────────────────────────

upload: $(PARQUET_FILES) $(PROVENANCE)
	$(PARQUET_DIR_GUARD)
	$(if $(RCLONE_CONFIG_DIR),,$(error RCLONE_CONFIG_DIR is not set -- export it before running make upload))
	sh $(SCRIPT_DIR)doall.sh

# ── Repository dispatch ───────────────────────────────────────────────────────
# Notify RNCBIGene and pyNCBIGene CI that the bucket has been updated.
# Requires GITHUB_TOKEN to be set (a personal access token with repo scope).

dispatch:
	$(if $(GITHUB_TOKEN),,$(error GITHUB_TOKEN is not set -- export it before running make dispatch))
	curl -s -X POST \
	  -H "Authorization: token $(GITHUB_TOKEN)" \
	  -H "Accept: application/vnd.github.v3+json" \
	  https://api.github.com/repos/vjcitn/RNCBIGene/dispatches \
	  -d '{"event_type":"bucket-updated"}'
	curl -s -X POST \
	  -H "Authorization: token $(GITHUB_TOKEN)" \
	  -H "Accept: application/vnd.github.v3+json" \
	  https://api.github.com/repos/vjcitn/pyNCBIGene/dispatches \
	  -d '{"event_type":"bucket-updated"}'
	@echo "Repository dispatch sent to RNCBIGene and pyNCBIGene."

# ── Housekeeping ──────────────────────────────────────────────────────────────

clean:
	rm -rf $(SRCDIR)
