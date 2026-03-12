process PURGEDUPS_PBCSTAT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8a/8afcc1222a0512a4fae7a7e7315ccfc841f3578df600b99d3dc563c3a8361352/data':
        'community.wave.seqera.io/library/purge_dups:1.2.6--1966ab26985f9f67' }"

    input:
    tuple val(meta), path(paf_alignment)

    output:
    tuple val(meta), path("${prefix}.PB.stat"),     emit: stat,     optional: true
    tuple val(meta), path("${prefix}.PB.base.cov"), emit: basecov,  optional: true
    tuple val(meta), path("no_peaks.flag.txt"),     emit: no_peaks, optional: true
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.6' // WARN: Incorrect version printed inside the container, please check this if bumping version
    """
    pbcstat \\
        $args \\
        $paf_alignment

    if [ "\$(awk '{print \$2}' $stat | sort | uniq)" -eq "0" ]
    then
        echo 'No peaks detected in input file. Aborting'
        touch no_peaks.flag.txt
    else
        for PBFILE in PB.*; do mv \$PBFILE ${prefix}.\$PBFILE; done
    fi
    """

}
