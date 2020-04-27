require(tidyverse)
require(yaml)

maps <- list.files("mapping_files", pattern="^mapping_file_run", full.names = T)
run_nrs <- gsub("\\.txt", "", sapply(strsplit(maps, "mapping_file_run"), tail, -1))
# function requires a mapping file with the name mapping_file_run{id}.txt

#run_nrs <- suppressWarnings(lapply(maps, read.table, fill=TRUE, header=T, sep="\t", check.names=F, comment.char="") %>%
#                              bind_rows %>%
#                              pull(run_nr) %>%
#                              unique)
# Althernative approach with 'run_nr' variables includedas variable in mapping_file.

raw_path <- yaml::read_yaml("config/config.yaml")$raw_path
#raw_path <- snakemake@config[["raw_path"]]

run_sheet_list <- lapply(run_nrs, function(run_nr) {
  full_paths <- list.files(file.path(raw_path, paste0("run_", run_nr)), pattern="\\_r.fastq$|\\_f.fastq$", recursive=T, full.names = T)
  names(full_paths) <- basename(full_paths)
  return(full_paths)
}) %>% unlist

run_sheet.df <- stack(run_sheet_list) %>%
  select(full_paths=values, file_names=ind) %>% 
  mutate(run_ids=gsub("\\_f.fastq|\\_r.fastq", "", file_names),
         read=ifelse(grepl("\\_f.fastq", file_names), "f", "r")) %>%
  select(run_ids, read, full_paths)

write.csv(run_sheet.df, "config/run_sheet.csv", row.names=F)