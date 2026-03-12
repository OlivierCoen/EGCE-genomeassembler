process PURGEDUPS_CALCUTS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/purge_dups:1.2.6--h7132678_0':
        'biocontainers/purge_dups:1.2.6--h7132678_0' }"

    input:
    tuple val(meta), path(stat)
    val assembly_mode

    output:
    tuple val(meta), path("*.cutoffs"),         optional: true,                                   emit: cutoff
    tuple val(meta), path("*.calcuts.log"),     optional: true,                                   emit: log
    tuple val(meta), path("no_peaks.flag.txt"), optional: true,                                   emit: no_peaks
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def assembly_mode_args = assembly_mode == "haplotype" ? "-d 1": "-d 0"
    """
    if [ "\$(awk '{print \$2}' $stat | sort | uniq)" -eq "0" ]; then
        echo 'No peaks detected in input file. Aborting'
        touch no_peaks.flag.txt
        exit 0
    fi

    calcuts \\
        $assembly_mode_args \\
        $args \\
        $stat \\
        > ${prefix}.cutoffs 2> \\
        >(tee ${prefix}.calcuts.log >&2)
    """
}
