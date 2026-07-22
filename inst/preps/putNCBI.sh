#!/bin/sh
# Upload one file to the OSN BiocParquetNCBI bucket via rclone in docker.
#
# Required environment variables:
#   RCLONE_CONFIG_DIR  path to directory containing rclone.conf
#   PARQUET_DIR        path to directory containing the parquet / json files
#
# Usage: sh putNCBI.sh <filename>
#   e.g. sh putNCBI.sh gene_info.parquet
#        sh putNCBI.sh provenance.json

: "${RCLONE_CONFIG_DIR:?set RCLONE_CONFIG_DIR to the rclone config directory}"
: "${PARQUET_DIR:?set PARQUET_DIR to the directory containing the files to upload}"

docker run \
  -v "${RCLONE_CONFIG_DIR}:/config/rclone" \
  -v "${PARQUET_DIR}:/data" \
  -ti rclone/rclone:latest \
  copyto "$1" "osn:/bir190004-bucket01/BiocParquetNCBI/$1" -vvvv
