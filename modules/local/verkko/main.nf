process VERKKO {
    tag "$meta.id"
    label 'process_very_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b9/b93232aa841f628343f5fc073eea96dcd897b83c3f76c46f8da73d2f07a48e5e/data':
        'community.wave.seqera.io/library/verkko:2.2.1--fb7344de848f21eb' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${prefix}.fastq.gz"),                                                emit: corrected_reads
    tuple val("${task.process}"), val('verkko'), eval('verkko --version 2>& 1 | tail -n 1 | sed "s/release //g"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_corrected"
    def platform_arg = meta.platform == "nanopore" ? "nano" : "hifi"
    """
    verkko \\
        ${args} \\
        --${platform_arg} ${reads} \\
        -d .
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_corrected"
    """
    touch ${prefix}.fastq.gz
    """
}
