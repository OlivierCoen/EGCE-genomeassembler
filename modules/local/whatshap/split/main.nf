process WHATSHAP_SPLIT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8babad63f830b45fc174b0921fea89d84561d38a562ce4229b59f17887e11581/data':
        'community.wave.seqera.io/library/whatshap:2.7--41cae4706d221f38' }"

    input:
    tuple val(meta), path(reads), path(haplotag_list)

    output:
    tuple val(meta), path("*_h1.fastq.gz"),                                          emit: reads_h1
    tuple val(meta), path("*_h2.fastq.gz"),                                          emit: reads_h2
    tuple val("${task.process}"), val('whatshap'), eval('whatshap --version'),       topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_happlotagged"
    """
    zcat $haplotag_list > haplo_list.txt

    whatshap split \\
        --output-h1 ${prefix}_h1.fastq.gz \\
        --output-h2 ${prefix}_h2.fastq.gz \\
        ${reads} \\
        haplo_list.txt

    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_h1.fastq.gz
    touch ${prefix}_h2.fastq.gz
    """
}
