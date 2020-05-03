# Pipeline to demultiplex using snakemake
_April 2020_  
_Wouter de Steenhuijsen Piters_

**Disclaimer: this is very much work in progress and by no means a finished pipeline**

This small pipeline serves as a test-case to explore the possibilities of [snakemake](https://academic.oup.com/bioinformatics/article/28/19/2520/290322) to develop consistent pipelines to use in our research group.

Aim of the pipeline is to convert large _multiplexed_ fastq-files, containing barcodes in the headers, into _demultiplexed_ (per-sample) .fastq.gz-files, which can be readily used in a soon to be written DADA2-pipeline in R.

## Usage

#### Step 1: create directories and clone this repository

1. Create a project-directory (e.g. `myproject`) and within that directory create another directory to create the demultiplexed data in (e.g. `demux`; can be any name). `cd` into that folder. E.g.:

```
mkdir -p myproject/demux
cd myproject/demux
```

2. Clone this repository in the directory you just `cd`'ed into:

```{shell}
git clone https://github.com/wsteenhu/demux-snakemake.git
```

Cloning the repository will download a few files and create directories (among others `config/`, `examples/` and `workflow` [including `envs/` and `scripts/`]).

#### Step 2: add mapping files

Add mapping files for each run into the folder `mapping_files`. These mapping files are formatted in the same way as the mapping files that were created to run the QIIME1-pipeline we previously used. They should minimally include two columns with sample-IDs (**#SampleID**) and barcodes (**BarcodeSequence**). Others columns, like **LinkerPrimerSequence** , **Description** or others, are optional. Please find an example of a mapping file in `examples`.

Alternatively, another location can be chosen for these mapping files, which should be adjusted in the `config/congfig.yaml`-file.

#### Step 3: create `run_sheet.csv`

In order for this pipeline to work, we need a `run_sheet.csv`-file within the `config`-folder. This file is used as a pointer to the raw sequence-files that should be demultiplexed.
The file consists of a three tab-separated columns entitled **run_ids** (i.e. `run14`), **read** (i.e. `f` or `r`) and **full_paths** (i.e. `/hpc/dla_mm/bogaert/raw/run14/run14_f.fastq`. See `examples` for an example `run_sheet.csv`. 

Note: if no `run_sheet.csv`-file is provided prior to initiating the pipeline, a script will be run on a specified `raw`-directory (which can be adjusted in the `config.yaml`-file), where it searches for `run_id` and accompanying forward (`runxx_f.fastq`) and reverse `runxx_r.fastq`) read files. This may only work with a consistent naming scheme.

#### Step 4: prepare to run the pipeline

1. First initiate an interactive session using `srun`:
```
srun --time="00:30:00" --pty bash
```

Adjust `--time=` for a longer session.

2. Activate the snakemake-environment (named `snakemake`):
```
conda activate snakemake
```

Note that this environment should be available for group members (installed here: `hpc/dla_mm/bogaert/miniconda3/envs/snakemake`). 
If this is not the case, the following command can be used to install the needed conda-environment:

```
conda env create -f workflow/envs/snakemake.yaml
```

3. Install conda environments within the project folder (necessary to run snakemake):

```
snakemake -n --use-conda --create-envs-only
```

This will create two conda-environments according to the `workflow/envs`-files (`qc` and `sabre`).

4. (Dry)run snakemake:

First dryrun snakemake to see whether all files needed are present:

```
snakemake -np
```

Note the following command can be used to run the pipeline in an interactive session, yet this is only advised when working with small files:

```
snakemake --use-conda --cores 1
```

#### Step 5: run snakemake on cluster

Set up a Snakemake SLURM profile as described [here](https://github.com/wsteenhu/demux-snakemake/blob/master/set_up_SLURM_profile.md). If needed adjust the time/memory allocated per rule in the Snakefile adjusting the `resources`.

```
snakemake --profile slurm
```

## Output

The following tree structure gives an overview of the files that are created after running the pipeline.

```
demux
└── config
    └── sample_sheet.csv
    logs
    ├── demux_overview.csv
    ├── demux_runxx.log
    └── demux_runyy.log
    data
    ├── demux
    │   ├── sample1_R1_001.fastq.gz
    │   ├── sample1_R2_001.fastq.gz
    │   ├── sample2_R1_001.fastq.gz
    │   └── sample2_R2_001.fastq.gz
    ├── demux_mapping
    │   ├── demux_mapping_runxx.txt
    │   └── demux_mapping_runyy.txt
    └── qc
        ├── fastqc_input
        │   ├── runxx_f_fastqc.html
        │   ├── runyy_f_fastqc.zip
        │   ├── runxx_r_fastqc.html
        │   └── runyy_r_fastqc.zip
        └── multiqc_input
            └── multiqc.html
```

These files include:
1. `config/sample_sheet.csv`; file that can be used in a subsequent pipeline (e.g. DADA2) as a pointer towards the files in the `data/demux`-directory.
2. `logs/demux_overview`; file providing an overview of all successfully demultiplexed files (including sample-IDs, barcodes and number of read-pairs).
3. `data/demux/`-directory, containing per-sample `.fastq.gz`-files.
4. `qc`-directory, containing `multiqc.html`, with quality measures per run.

## Changelog

... [ work in progress]

## Acknowledgements

I would like to acknowledge Mark Kroon (RIVM) for his help in setting up this pipeline.

