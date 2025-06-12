process PURGEDUPS_GETSEQS {
    tag "${assembly.simpleName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/purge_dups:1.2.6--h7132678_0':
        'biocontainers/purge_dups:1.2.6--h7132678_0' }"

    input:
    tuple val(meta), path(assembly), path(bed)

    output:
    tuple val(meta), path("*_hap.fa.gz"),                                                              emit: haplotigs
    tuple val(meta), path("*_purged.fa.gz"),                                                           emit: purged
    tuple val("${task.process}"), val('purgedups'), eval('purge_dups -h |& sed "3!d; s/.*: //"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${assembly.simpleName}"
    """
    get_seqs \\
        $args \\
        -e $bed \\
        -p $prefix \\
        $assembly

    gzip -c ${prefix}.purged.fa > ${prefix}_purged.fa.gz
    gzip -c ${prefix}.hap.fa > ${prefix}_hap.fa.gz
    """
}
