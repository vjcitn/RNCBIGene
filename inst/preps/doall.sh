#!/bin/sh
# Upload all parquet files and provenance.json from PARQUET_DIR to the OSN bucket.
#
# Required environment variables:
#   RCLONE_CONFIG_DIR  path to directory containing rclone.conf
#   PARQUET_DIR        path to directory containing the files to upload
#
# Usage: sh doall.sh

: "${RCLONE_CONFIG_DIR:?set RCLONE_CONFIG_DIR to the rclone config directory}"
: "${PARQUET_DIR:?set PARQUET_DIR to the directory containing the files to upload}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for f in "${PARQUET_DIR}"/*.parquet "${PARQUET_DIR}"/provenance.json; do
  [ -f "$f" ] || continue
  echo "uploading $(basename "$f") ..."
  sh "${SCRIPT_DIR}/putNCBI.sh" "$(basename "$f")"
done

# Always upload the golden query file from the package source
echo "uploading test_queries.json ..."
cp "${SCRIPT_DIR}/test_queries.json" "${PARQUET_DIR}/test_queries.json"
sh "${SCRIPT_DIR}/putNCBI.sh" "test_queries.json"
rm -f "${PARQUET_DIR}/test_queries.json"
