process PURGEDUPS_CALCUTS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/purge_dups:1.2.6--h7132678_0':
        'biocontainers/purge_dups:1.2.6--h7132678_0' }"

    input:
    tuple val(meta), path(stat)
    val assembly_mode

    output:
    tuple val(meta), path("*.cutoffs"),                                                             emit: cutoff
    tuple val(meta), path("*.calcuts.log"),                                                         emit: log
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def assembly_mode_args = assembly_mode == "haplotype" ? "-d 1": "-d 0"
    """
    calcuts \\
        $assembly_mode_args \\
        $args \\
        $stat \\
        > ${prefix}.cutoffs 2> \\
        >(tee ${prefix}.calcuts.log >&2)
    """
}
