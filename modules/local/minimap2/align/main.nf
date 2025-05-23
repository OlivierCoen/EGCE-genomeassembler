process MINIMAP2_ALIGN {
    tag "${meta.id}"
    label 'process_high'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/66/66dc96eff11ab80dfd5c044e9b3425f52d818847b9c074794cf0c02bfa781661/data' :
        'community.wave.seqera.io/library/minimap2_samtools:33bb43c18d22e29c' }"

    input:
    tuple val(meta), path(reads), path(reference)

    output:
    tuple val(meta), path("*.bam"), path(reference)        , emit: bam
    tuple val(meta), path("*.bai")                         , emit: index
    path "versions.yml"                                     , emit: versions

    script:
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def args4 = task.ext.args4 ?: ''
    def prefix = task.ext.prefix ?: "${reads.simpleName}_mapped_to_${reference.simpleName}"
    def bam_index = "${prefix}.bam##idx##${prefix}.bam.bai --write-index"
    def bam_output = "-a | samtools sort -@ ${task.cpus-1} -o ${bam_index} ${args2}"
    def bam_input = "${reads.extension}".matches('sam|bam|cram')
    def samtools_reset_fastq = bam_input ? "samtools reset --threads ${task.cpus-1} $args3 $reads | samtools fastq --threads ${task.cpus-1} $args4 |" : ''
    def query = bam_input ? "-" : reads
    def target = reference ?: (bam_input ? error("BAM input requires reference") : reads)

    """
    $samtools_reset_fastq \\
    minimap2 \\
        $args \\
        -t $task.cpus \\
        $target \\
        $query \\
        $bam_output


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${reads.baseName}.mapped_to.${reference.baseName}"
    def output_file = "${prefix}.bam"
    def make_bam_index_cmd = "touch ${prefix}.bam.${bam_index_extension}"
    def bam_input = "${reads.extension}".matches('sam|bam|cram')
    def target = reference ?: (bam_input ? error("BAM input requires reference") : reads)

    """
    touch $output_file
    ${make_bam_index_cmd}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}
