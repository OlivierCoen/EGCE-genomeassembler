process PRETEXTMAP {
    tag "${fasta.baseName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a5/a586fe0189c4e48c4b3f5a7dcfb6308b1fa7cfddcd6db71f758a22e608f3a54c/data':
        'community.wave.seqera.io/library/pretextmap_samtools:fe518f32a75cf4dd' }"

    input:
    tuple val(meta), path(bam), path(fasta)

    output:
    tuple val(meta), path("*.pretext"),                                                                      emit: pretext
    tuple val("${task.process}"), val('pretextmap'), eval("PretextMap | sed '/Version/!d; s/.*Version //'"), topic: versions
    tuple val("${task.process}"), val('samtools'), eval("samtools --version | sed '1!d; s/samtools //'"),    topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args     ?: ''
    def prefix      = task.ext.prefix   ?: "${fasta.baseName}"
    """
    samtools \\
        view \\
        --reference $fasta \\
        -h \\
        $bam | \\
        PretextMap \\
        $args \\
        -o ${prefix}.pretext
    """

    stub:
    def prefix = task.ext.prefix ?: "${fasta.baseName}"
    """
    touch ${prefix}.pretext
    """
}
