source("RNCBIGene.R", echo=TRUE) # get 'pop' list
library(arrow)
mandatory_names = c("gene2go.parquet", "gene2pubmed.parquet", "gene_info.parquet", 
"gene2accession.parquet", "gene2refseq.parquet", "gene_orthologs.parquet", 
"gene_refseq_uniprotkb_collab.parquet")
stopifnot(all(names(pop) %in% mandatory_names))

todo = setdiff(mandatory_names, "gene_refseq_uniprotkb_collab.parquet")

h4 = c("TP53", "BRCA1", "ORMDL3", "GSDMB")
ids = pop[["gene_info.parquet"]] |> filter(`#tax_id` == 9606, Symbol %in% h4) |> select(`#tax_id`, GeneID, Symbol)
gids4 = ids |> select(GeneID) |> pull(as_vector=TRUE)
list4 = lapply(pop[todo], function(x) x |> filter(GeneID %in% gids4))
lapply(list4, nrow)
ns = names(list4)
targs = paste0("lit.", ns)
dfs = lapply(todo, function(i) list4[[i]] |> collect() |> as.data.frame())
lapply(seq_len(length(dfs)), function(i) arrow::write_parquet(dfs[[i]], targs[i]))

acc = read_parquet("lit.gene2accession.parquet")
cands = acc$protein_accession.version |> setdiff("-") 
lit.uni = pop[["gene_refseq_uniprotkb_collab.parquet"]] |> filter(`#NCBI_protein_accession` %in% cands)  
udf = lit.uni |> as.data.frame()
arrow::write_parquet(udf, paste0("lit.", "gene_refseq_uniprotkb_collab.parquet"))

