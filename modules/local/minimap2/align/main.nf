process MINIMAP2_ALIGN {
    tag "${reads.simpleName} on ${reference.simpleName}"
    label 'process_high'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/66/66dc96eff11ab80dfd5c044e9b3425f52d818847b9c074794cf0c02bfa781661/data' :
        'community.wave.seqera.io/library/minimap2_samtools:33bb43c18d22e29c' }"

    input:
    tuple val(meta), path(reads), path(reference)
    val bam_format

    output:
    tuple val(meta), path("*.bam"), path(reference),                                      optional: true,   emit: bam_ref
    tuple val(meta), path("*.paf.gz"), path(reference),                                   optional: true,   emit: paf_ref
    tuple val(meta), path("*.bai"),                                                       optional: true,   emit: index
    tuple val("${task.process}"), val('minimap2'), eval('minimap2 --version'),                              topic: versions
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | awk "{print $2}"'), topic: versions

    script:
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def args4 = task.ext.args4 ?: ''
    def prefix = task.ext.prefix ?: "${reads.simpleName}_mapped_to_${reference.simpleName}"
    def bam_index = "${prefix}.bam##idx##${prefix}.bam.bai --write-index"
    def bam_output = bam_format ? "-a | samtools sort -@ ${task.cpus-1} -o ${bam_index} ${args2}" : "-o ${prefix}.paf"
    def gzip_paf_output = bam_format ? "" : "gzip -n ${prefix}.paf"

    """
    minimap2 \\
        $args \\
        -t $task.cpus \\
        -y \\
        $reference \\
        $reads \\
        $bam_output

    $gzip_paf_output
    """

    stub:
    def prefix = task.ext.prefix ?: "${reads.baseName}.mapped_to.${reference.baseName}"
    def output_file = "${prefix}.bam"
    def bam_input = "${reads.extension}".matches('sam|bam|cram')
    def target = reference ?: (bam_input ? error("BAM input requires reference") : reads)

    """
    touch $output_file
    touch ${prefix}.bam.bai
    """
}
