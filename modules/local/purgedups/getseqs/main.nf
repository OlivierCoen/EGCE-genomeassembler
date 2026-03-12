process PURGEDUPS_GETSEQS {
    tag "${assembly.simpleName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8a/8afcc1222a0512a4fae7a7e7315ccfc841f3578df600b99d3dc563c3a8361352/data':
        'community.wave.seqera.io/library/purge_dups:1.2.6--1966ab26985f9f67' }"

    input:
    tuple val(meta), path(assembly), path(bed)

    output:
    tuple val(meta), path("*_hap.fa.gz"),                                                         emit: haplotigs
    tuple val(meta), path("*_purged.fa.gz"),                                                      emit: purged
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${assembly.simpleName}"
    """
    get_seqs \\
        $args \\
        -e $bed \\
        -p $prefix \\
        $assembly

    gzip -c ${prefix}.purged.fa > ${prefix}_purged.fa.gz
    gzip -c ${prefix}.hap.fa > ${prefix}_hap.fa.gz
    """
}
