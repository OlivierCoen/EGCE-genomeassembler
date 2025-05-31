process MERYL_PRINT {
    tag "${meryl_db.baseName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/meryl:1.4.1--h4ac6f70_1':
        'biocontainers/meryl:1.4.1--h4ac6f70_1' }"

    input:
    tuple val(meta), path(meryl_db)

    output:
    tuple val(meta), path("*.repetitive_kmers.txt"),                                                                      emit: repetitive_kmers
    tuple val("${task.process}"), val('meryl'), eval('meryl --version |& sed -n "s/.* \\([a-f0-9]\\{40\\}\\))/\\1/p"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    meryl print \\
        $args \\
        $meryl_db \\
        > ${prefix}.repetitive_kmers.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    for READ in ${reads}; do
        touch ${prefix}.\${READ%.f*}.meryl
    done
    """
}
