import os
import pandas as pd
import subprocess

configfile: "config/config.yaml"

wildcard_constraints:
  read="[fr]{1}"

# import RUNS
if not os.path.exists("config/run_sheet.csv"):
  subprocess.call(["Rscript", "workflow/scripts/create_run_sheet.R"])

run_sheet_df = pd.read_csv("config/run_sheet.csv")

def df_to_nested_dict(df):
    result = {}
    for lst in df.values:
        leaf = result
        for path in lst[:-2]:
            leaf = leaf.setdefault(path, {})
        leaf.setdefault(lst[-2], list()).append(lst[-1])
    return(result)

RUNS = df_to_nested_dict(run_sheet_df)

rule all:
  input:
    expand("data/demux_mapping/demux_mapping_{run_id}.txt", run_id=RUNS),
    "config/sample_sheet.csv",
    "data/qc/multiqc_input/multiqc.html",
    "logs/fastq_moved.done",
    "logs/demux_overview.csv"

rule create_mappings:
  input:
    mapping_files=expand("mapping_files/mapping_file_{run_id}.txt", run_id=RUNS)
  output:
    demux_mappings=expand("data/demux_mapping/demux_mapping_{run_id}.txt", run_id=RUNS),
    sample_sheet="config/sample_sheet.csv"
  script:
    "workflow/scripts/create_mappings.R"

rule fastqc:
  input:
    lambda wildcards: RUNS[wildcards.run_id][wildcards.read]
  output:
    "data/qc/fastqc_input/{run_id}_{read}_fastqc.html",
    "data/qc/fastqc_input/{run_id}_{read}_fastqc.zip"
  params:
    outdir="data/qc/fastqc_input/"
  resources: mem=15, time=15 #, cpus-per-task=1
  conda:
    "workflow/envs/qc.yaml"
  shell:
    "fastqc {input} -o {params.outdir} -f fastq"

rule multiqc:
  input:
    expand("data/qc/fastqc_input/{run_id}_{read}_fastqc.zip", run_id=RUNS, read=["f", "r"])
  output:
    "data/qc/multiqc_input/multiqc.html"
  params:
    outdir="data/qc/multiqc_input/" 
  conda:
    "workflow/envs/qc.yaml"
  shell: 
    "multiqc {input} --force -o {params.outdir} -n multiqc.html"

rule format:
  input:
    lambda wildcards: RUNS[wildcards.run_id][wildcards.read]
  output:
    temp("data/temp/{run_id}_{read}.fastq")
  resources: mem=15, time=15
  shell:
    """
    cat {input} | awk -F ':' 'NR == 1 || NR % 4 == 1 {{split($10, arr, "+"); barcode=arr[1]arr[2]; print $0}} NR % 4 == 2 || NR % 4 == 0 {{print barcode $0}} NR % 4 == 3 {{print $0}}' > {output}
    """

rule demux:
  input:
    fw="data/temp/{run_id}_f.fastq",
    rv="data/temp/{run_id}_r.fastq",
    bc="data/demux_mapping/demux_mapping_{run_id}.txt"
  output:
    u="data/demux/no_bc_match/{run_id}_R1.fastq",
    w="data/demux/no_bc_match/{run_id}_R2.fastq"
  resources: mem=15, time=15
  conda:
    "workflow/envs/sabre.yaml"
  log:
    "logs/demux_{run_id}.log"
  shell:
    """
    sabre pe -f {input.fw} -r {input.rv} -b {input.bc} -u {output.u} -w {output.w} -c > {log} 2>&1
    """
    #gzip -f *_001.fastq
    #mv *_001.fastq.gz {params.outdir}
    #https://bitbucket.org/snakemake/snakemake/issues/964/snakemake-shadow-directory-copies-unneeded

rule move:
  input: 
    expand("data/demux/no_bc_match/{run_id}_{read_format}.fastq", run_id=RUNS, read_format=["R1", "R2"])
  output:
    touch("logs/fastq_moved.done")
  params:
    outdir=directory("data/demux/")
  shell:
    """
    gzip -f *_001.fastq
    mv *_001.fastq.gz {params.outdir}
    """
    #rule move was added as gzip/mv of non-defined fastq-files did not work in a parallel setting when added to demux.
    
rule create_demux_overview:
  input:
    demux_mappings=expand("data/demux_mapping/demux_mapping_{run_id}.txt", run_id=RUNS),
    logs=expand("logs/demux_{run_id}.log", run_id=RUNS)
  output:
    demux_overview="logs/demux_overview.csv"
  script:
    "workflow/scripts/create_demux_overview.R"