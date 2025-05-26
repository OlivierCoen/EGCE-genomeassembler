process ARIMA_GET_STATS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/70/707f35e66afc6996ac26db12501a2444e8024f08726a66195cc8f53fbf601a7a/data':
        'community.wave.seqera.io/library/perl:5.32.1--a61125adac4a9f65' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta), path(index)

    output:
    tuple val(meta), path("*.stats"),                              emit: stats
    tuple val("${task.process}"), val('perl'), val('5.32.1'),      topic: versions

    script:

    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    get_stats.pl $bam > ${bam}.stats

    """
}
