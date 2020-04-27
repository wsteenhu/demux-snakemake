require(tidyverse)
require(yaml)

logs <- snakemake@input[["logs"]]
maps <- snakemake@input[["demux_mappings"]]

names(logs) <- unlist(lapply(logs, function(log) gsub("\\.log", "", sapply(strsplit(basename(log), "\\_"), tail, 1))))
names(maps) <- unlist(lapply(maps, function(map) gsub("\\.txt", "", sapply(strsplit(basename(map), "\\_"), tail, 1))))

lapply(names(logs), function(name) {
  log <- readLines(logs[[name]])
  map <- read.table(maps[[name]], fill=TRUE, header=F, sep="\t", comment.char="") %>%
    select(barcode="V1", fw="V2", rv="V3")

  barcode_lines <- log[grepl("FastQ records for barcode ", log)]

  barcodes <- sapply(strsplit(barcode_lines, "\\ |\\:|\\("), "[", c(5, 7, 9)) %>%
    t %>%
    as.data.frame() %>%
    select(barcode="V1", read_pairs="V3")

  barcode_mapped <- left_join(barcodes, map, by="barcode") %>%
    mutate(sample_id=gsub("_R1_001.fastq", "", fw),
           run_id=name) %>%
    select(sample_id, barcode, run_id, read_pairs, fw, rv)
  return(barcode_mapped)
}) %>% do.call(rbind, .) %>%
  write.csv(., snakemake@output[["demux_overview"]], row.names=F)