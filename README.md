# nf-genome-assembler

[![GitHub Actions CI Status](https://github.com/nf-genome-assembler/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-genome-assembler/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-genome-assembler/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-genome-assembler/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-genome-assembler)

## Introduction

**nf-genome-assembler** is a bioinformatics pipeline that is designed to assemble genomes from long-read sequencing data and Hi-C data. It is built using Nextflow, a workflow management system that allows for the creation of reproducible and scalable pipelines.

## Installation

Please check the [installation instructions](docs/install.md) for more details on how to install Nextflow and Docker / Apptainer.

## Running the pipeline

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.yaml`:

```yaml
- name: my_assembly
  platform: nanopore
  reads: /path/to/ont_reads.fastq.gz
  hic_fastq_1: /path/to/hic_read_r1.fastq.gz
  hic_fastq_2: /path/to/hic_read_r2.fastq.gz
  genome_size: 1000000000
  assembly: /path/to/assembly
```

It can also be a `CSV` samplesheet:

```csv
name,platform,reads,hic_fastq_1,hic_fastq_2,genome_size,assembly
my_assembly,nanopore,/path/to/ont_reads.fastq.gz,/path/to/hic_read_r1.fastq.gz,/path/to/hic_read_r2.fastq.gz,1000000000,/path/to/assembly
```

>[!NOTE]
> The `assembly` column is also optional and serves only when you want to skip early steps and continue with a specific assembly.
> The `genome_size` column is optional and serves only for `Flye` to estimate the expected genome size.

Now, you can run the pipeline using:

```bash
nextflow run OlivierCoen/nf-genome-assembler \
   -latest \
   -profile <docker/apptainer/conda/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
   -resume
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

nf-genome-assembler was originally written by Olivier Coen.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-genome-assembler for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
