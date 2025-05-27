# EGCE/genomeassembler

[![GitHub Actions CI Status](https://github.com/EGCE/genomeassembler/actions/workflows/ci.yml/badge.svg)](https://github.com/EGCE/genomeassembler/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/EGCE/genomeassembler/actions/workflows/linting.yml/badge.svg)](https://github.com/EGCE/genomeassembler/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/EGCE/genomeassembler)

## Introduction

**EGCE/genomeassembler** is a bioinformatics pipeline that ...

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))


## Installation

### Nextflow

If your Java version is >= 17, you can install Nextflow in your `$HOME` folder using:

```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
mkdir -p $HOME/.local/bin/
mv nextflow $HOME/.local/bin/
echo "export PATH=$HOME/.local/bin/:$PATH" >> $HOME/.bashrc
```

> [!NOTE]
> If your Java version is < 17, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow.

> [!NOTE]
> You can also install Nextflow system-wide by moving the `nextflow` executable to a directory accessible to all users:
> ```bash
> sudo mv nextflow /usr/local/bin/
> ```

### Apptainer

When running the pipeline of multi-user server or on a cluster, the best practice is to use Apptainer (formerly Singularity).

You can install Apptainer by following these [instructions](https://apptainer.org/docs/admin/main/installation.html#).

In case you encounter the following error when running Apptainer:
```
ERROR  : Could not write info to setgroups: Permission denied
ERROR  : Error while waiting event for user namespace mappings: no event received
```
you may need to install the `apptainer-suid` package instead of `apptainer`:

```
# Debian / Ubuntu
sudo apt install apptainer-suid
# RHEL / CentOS
sudo yum install apptainer-suid
# Fedora
sudo dnf install apptainer-suid
```


### Docker / Podman / Shifter / Charliecloud

You can also use other container technologies to run the pipeline. See the following instructions to install:
* [Docker](https://docs.docker.com/engine/install/)
* [Podman](https://podman.io/docs/installation)
* [Shifter](https://shifter.readthedocs.io/en/latest/install_guides.html)
* [Charliecloud](https://charliecloud.io/latest/install.html)

> [!NOTE]
> For now, the only one that is tested is Docker. If you encounter any problem, please open an issue.


### Micromamba / Conda

This pipeline can be launched with Micromamba (or Conda) too and it has been tested successfully.

Although it is not the best practice, it should work perfectly and it can be very convenient when you cannot run containers (Apptainer, Docker, Podman, ...).

* To install Micromamba in your `$HOME` folder:

```bash
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)
```
(or see these [instructions](https://micromamba.readthedocs.io/en/latest/installation.html)).

* To install Miniconda in your `$HOME` folder, see these [instructions](https://www.anaconda.com/docs/getting-started/miniconda/install).


## Running the pipeline


First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run EGCE/genomeassembler \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

EGCE/genomeassembler was originally written by Olivier Coen.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use EGCE/genomeassembler for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
