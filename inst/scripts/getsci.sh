tar xzf taxdump.tar.gz names.dmp
awk -F'\t\\|\t' '$4 ~ /scientific name/ {print $1"\t"$2}' names.dmp > taxid2name.tsv
