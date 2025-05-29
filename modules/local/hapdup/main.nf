process HAPDUP {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'mkolmogo/hapdup:0.12':
        'mkolmogo/hapdup:0.12' }"

    input:
    tuple val(meta), path(assembly), val(bam), val(read_length)

    output:
    tuple val(meta), path(assembly), path(bam),                                                                    emit: summary
    tuple val("${task.process}"), val('hapdup'), eval('hapdup -v'),   topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hapdup \
        --assembly $assembly \
        --bam $bam \
        --out-dir $HD_DIR/hapdup \
        -t ${task.cpus} \
        --rtype ont

    """

}
