process WHATSHAP_STATS {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8babad63f830b45fc174b0921fea89d84561d38a562ce4229b59f17887e11581/data':
        'community.wave.seqera.io/library/whatshap:2.7--41cae4706d221f38' }"

    input:
    tuple val(meta), path(vcf), path(vcf_index)

    output:
    tuple val(meta), path("*.tsv"),                                            emit: stats
    tuple val("${task.process}"), val('whatshap'), eval('whatshap --version'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    whatshap stats \\
        --tsv ${prefix}_phasing_stats.tsv\\
        --gtf ${prefix}_phased_blocks.gtf \\
        ${vcf}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv
    """
}
