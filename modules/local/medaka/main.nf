process MEDAKA {
    tag "$meta.id"
    label 'process_high_cpu'
    label 'process_high_memory'
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/1842062447c537b95476a00c46d1f3776096972f66ef0935923ae238a39c16ad/data' :
        'community.wave.seqera.io/library/medaka_pigz:38dfdf8a96315448' }"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.fa.gz"), emit: assembly
    tuple val("${task.process}"), val('medaka'), eval('medaka --version 2>&1 | sed "s/medaka //g"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_medaka"
    """
    pigz -dc $reads > reads.fastq
    pigz -dc $assembly > assembly.fasta

    medaka_consensus \\
        -t $task.cpus \\
        $args \\
        -i reads.fastq \\
        -d assembly.fasta

    mv medaka/consensus.fasta ${prefix}.fa

    pigz ${prefix}.fa
    """
}
