process PURGEDUPS_PBCSTAT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/purge_dups:1.2.6--py39h7132678_1':
        'biocontainers/purge_dups:1.2.6--py39h7132678_1' }"

    input:
    tuple val(meta), path(paf_alignment)

    output:
    tuple val(meta), path("${prefix}.PB.stat"),     emit: stat,     optional: true
    tuple val(meta), path("${prefix}.PB.base.cov"), emit: basecov,  optional: true
    tuple val(meta), path("no_peaks.flag.txt"),     emit: no_peaks, optional: true
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.6' // WARN: Incorrect version printed inside the container, please check this if bumping version
    """
    pbcstat \\
        $args \\
        $paf_alignment

    if [ "\$(awk '{print \$2}' $stat | sort | uniq)" -eq "0" ]
    then
        echo 'No peaks detected in input file. Aborting'
        touch no_peaks.flag.txt
    else
        for PBFILE in PB.*; do mv \$PBFILE ${prefix}.\$PBFILE; done
    fi
    """

}
