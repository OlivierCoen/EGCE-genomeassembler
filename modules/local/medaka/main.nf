process MEDAKA {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:1.4.4--py38h130def0_0' :
        'biocontainers/medaka:1.4.4--py38h130def0_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.fa.gz"), emit: assembly
    tuple val("${task.process}"), val('medaka'), eval('medaka --version 2>&1 | sed "s/medaka //g"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gzip -d $reads > reads.fastq
    gzip -d $assembly > assembly.fasta

    medaka_consensus \\
        -t $task.cpus \\
        $args \\
        -i reads.fastq \\
        -d assembly.fasta \\
        -o ./

    mv consensus.fasta ${prefix}.fa

    gzip -n ${prefix}.fa
    """
}
