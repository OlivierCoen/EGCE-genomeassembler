process MERYL_COUNT {
    tag "${reads.simpleName}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/meryl:1.4.1--h4ac6f70_1':
        'biocontainers/meryl:1.4.1--h4ac6f70_1' }"

    input:
    tuple val(meta), path(reads)
    val kvalue

    output:
    tuple val(meta), path("*.meryl"),                                                                                     emit: meryl_db
    tuple val("${task.process}"), val('meryl'), eval('meryl --version |& sed -n "s/.* \\([a-f0-9]\\{40\\}\\))/\\1/p"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reduced_mem = task.memory.multiply(0.9).toGiga()
    """
    for READ in ${reads}; do
        meryl count \\
            k=${kvalue} \\
            threads=${task.cpus} \\
            memory=${reduced_mem} \\
            ${args} \\
            \$READ \\
            output ${prefix}.\${READ%.f*}.meryl
    done
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    for READ in ${reads}; do
        touch ${prefix}.\${READ%.f*}.meryl
    done
    """
}
