# Set up Snakemake on HPC (SLURM)

Although Snakemake can be run interactively in an `srun`-session, it would be better to run it in `sbatch`, preferably specifying different resources per rule. This can be most easily done by setting up a Snakemake profile for SLURM, which can be found [here](https://github.com/Snakemake-Profiles/slurm).
These profiles will allow portability of the pipeline, making it irrespective of job submission system used (e.g. SLURM/SGE).

## SLURM

A SLURM Snakemake profile has to be set up once to be able to submit Snakemake rules as separate jobs. The profile is by default searched for the in user's home-directory (`/home/dla_mm/<user_name>`).

Activate the cookiecutter-conda environment:

```
conda activate cookiecutter
```

Then run the following lines:

```
mkdir -p ~/.config/snakemake
cd ~/.config/snakemake
cookiecutter https://github.com/Snakemake-Profiles/slurm.git
```

Subsequently, fill in the following specification:

- **profile_name**: `slurm` 
- **sbatch defaults**: `time=10 mem=10 cpus-per-task=1 mail-type=FAIL mail-user=user@mail.com output=logs/slurm_logs/slurm-%A.out`
- **cluster_config**:
- **Select advanced_argument_conversion**: 1

Specify your own e-mail address after `mail-user=`.
Note: hit `<return>` when prompted to specify **cluster_config**.

Next, adjust `config.yaml` slightly, by adding the following two lines:

```
jobs: 10
use-conda: true

# Note the file already contains these defaults:
restart-times: 3
jobscript: "slurm-jobscript.sh"
cluster: "slurm-submit.py"
cluster-status: "slurm-status.py"
max-jobs-per-second: 1
max-status-checks-per-second: 10
local-cores: 1
latency-wait: 60
```

Now, you should be able to run the following command:

```
snakemake --profile slurm
```

Also, in the `Snakefile` resources can be specified, including `time` (in minutes) and `mem` (in Gb), per rule (if not specified, the defaults will be used).


