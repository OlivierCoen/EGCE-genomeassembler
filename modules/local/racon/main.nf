process RACON {
    tag "${meta.id}::${assembly.baseName}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/racon:1.4.20--h9a82719_1' :
        'biocontainers/racon:1.4.20--h9a82719_1' }"

    input:
    tuple val(meta), path(reads), path(assembly), path(paf)
    val round

    output:
    tuple val(meta), path('*_assembly_consensus.fasta.gz') , emit: improved_assembly
    tuple val("${task.process}"), val('racon'), eval('racon --version 2>&1 | sed "s/^.*v//"'),     topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_round_${round}"

    """
    racon -t "$task.cpus" \\
        "${reads}" \\
        "${paf}" \\
        $args \\
        "${assembly}" > \\
        ${prefix}_assembly_consensus.fasta

    gzip -n ${prefix}_assembly_consensus.fasta
    """
}
