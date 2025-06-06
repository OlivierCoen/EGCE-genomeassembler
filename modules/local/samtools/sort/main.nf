process SAMTOOLS_SORT {
    tag "$fasta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/76/76e8e7baacbb86bca8f27e669a29a191b533bc1c5d7b08813cac7c20fcff174b/data' :
        'community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path ("*.bam"),                                                                           emit: bam
    tuple val(meta), path ("*.bai"),                                                                           emit: bai
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | awk "{print $2}"'),    topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools cat \\
        ${bam} \\
    | \\
    samtools sort \\
        ${args} \\
        --threads ${task.cpus} \\
        -o ${prefix}.bam \\
        --output-fmt bam \\
        --write-index \\
        -

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    """
}
