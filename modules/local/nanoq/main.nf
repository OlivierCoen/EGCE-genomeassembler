process NANOQ {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanoq:0.10.0--h031d066_2' :
        'biocontainers/nanoq:0.10.0--h031d066_2'}"

    input:
    tuple val(meta), path(ontreads)

    output:
    tuple val(meta), path("*.{stats,json}"),                                                       emit: stats
    tuple val("${task.process}"), val('nanoq'), eval('nanoq --version | sed -e "s/nanoq //g"'),   topic: versions


    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    nanoq -i $ontreads \\
        ${args} \\
        -r ${prefix}.stats \\
        -o ${prefix}.fastq
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    echo "" | gzip > ${prefix}.$output_format
    touch ${prefix}.stats
    """
}
