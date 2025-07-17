process DENTIST {
    tag "$meta.id"
    label 'process_high_cpu'
    label 'process_high_memory'
    label 'process_long'

    //container "quay.io/ocoen/dentist:4.0.0"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ca/cae3ab57e8f3ffee7165068ad77b0814b210743767eff3d02db323fe528a4843/data' :
        'community.wave.seqera.io/library/dentist-core_snakemake:dada80c0e4030069' }"

    input:
    tuple val(meta), path(reads), val(mean_quality)

    output:
    tuple val(meta), path("*.fasta.gz"),                                                                    emit: fasta
    tuple val("${task.process}"), val('dentist'), eval("dentist --version 2>&1 | awk '{print \$2; exit}'"), topic: versions
    tuple val("${task.process}"), val('snakemake'), eval("snakemake --version"),                            topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def use_frontend_arg = workflow.profile.tokenize(',').intersect(['conda']).size() >= 1 ? "--conda-frontend=conda" : ""
    """
    snakemake \\
         --use-conda \\
        --configfile=snakemake.yml \\
        --cores=${task.cpus} \\
        $use_frontend_arg
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}
