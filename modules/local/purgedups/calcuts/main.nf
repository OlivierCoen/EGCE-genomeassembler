process PURGEDUPS_CALCUTS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8a/8afcc1222a0512a4fae7a7e7315ccfc841f3578df600b99d3dc563c3a8361352/data':
        'community.wave.seqera.io/library/purge_dups:1.2.6--1966ab26985f9f67' }"

    input:
    tuple val(meta), path(stat)
    val assembly_mode

    output:
    tuple val(meta), path("*.cutoffs"),         optional: true,                                   emit: cutoff
    tuple val(meta), path("*.calcuts.log"),     optional: true,                                   emit: log
    tuple val(meta), path("no_peaks.flag.txt"), optional: true,                                   emit: no_peaks
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def assembly_mode_args = assembly_mode == "haplotype" ? "-d 1": "-d 0"
    """
    calcuts \\
        $assembly_mode_args \\
        $args \\
        $stat \\
        > ${prefix}.cutoffs 2> \\
        >(tee ${prefix}.calcuts.log >&2)
    """
}
