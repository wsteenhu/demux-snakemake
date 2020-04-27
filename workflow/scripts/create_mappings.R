require(tidyverse)
require(yaml)

maps <- snakemake@input[["mapping_files"]]
results_path <- paste0(gsub("mapping_files/", "", normalizePath(dirname(maps[[1]]))), "/results/")
print(results_path)

maps_adj <- suppressWarnings(lapply(maps, function(map) { 
  read.table(map, fill=TRUE, header=T, sep="\t", check.names=F, comment.char="") %>%
    mutate(fw=paste0(`#SampleID`, "_R1_001.fastq"), 
           rv=paste0(`#SampleID`, "_R2_001.fastq")) %>%
    select(BarcodeSequence, fw, rv) }))

# write demux mapping files
lapply(1:length(maps_adj), function(x) { 
  write.table(maps_adj[[x]], file=snakemake@output[["demux_mappings"]][[x]], col.names=F, row.names=F, sep="\t", quote=F)
})

# write sample sheet
maps_adj %>% 
  do.call(rbind, .) %>%
  gather(read, name, fw:rv) %>%
  mutate(read=ifelse(read=="fw", "R1", "R2"),
         path=paste0(results_path, name)) %>%
  select(name, read, path) %>%
  write.csv(., snakemake@output[["sample_sheet"]], row.names=F)
