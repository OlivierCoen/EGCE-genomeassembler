process HERRO_INFERENCE {
    tag "$meta.id"
    label 'process_high'

    //conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/herro:0.0.2':
        'ocoen/herro:0.0.2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${prefix}.fastq.gz"),                                               emit: corrected_reads
    tuple val("${task.process}"), val('herro'), eval('herro --version | sed "s/herro //g"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_corrected"
    def ont_platform = "R10" // or R9
    def model_filename = ont_platform == "R10" ? "model_R10_v0.1.pt" : "model_R9_v0.1.pt"
    """
    herro inference \\
        -m /herro/models/${model_filename} \\
        -b 64 \\
        -t 1 \\
        $reads \\
        ${prefix}.fastq.gz
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_corrected"
    """
    touch ${prefix}.fastq.gz
    """
}
