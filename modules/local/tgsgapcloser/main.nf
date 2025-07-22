process TGSGAPCLOSER {
    tag "${assembly.simpleName}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/55/5585ff2ad6b14c115ea9effbb33bf2222a7ca74f9790df42f8f10e957e83ce57/data' :
        'community.wave.seqera.io/library/tgsgapcloser_pigz:bcfeaafc4b4aa363'}"

    input:
    tuple val(meta), path(assembly), path(reads)

    output:
    tuple val(meta), path("*_gapclosed.fa.gz"),                                                                               emit: assembly
    tuple val("${task.process}"), val('tgsgapcloser'), eval("tgsgapcloser | grep Version |  grep -oP '\\d+\\.\\d+\\.\\d+'"),  topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${assembly.simpleName}"
    def tgstype = meta.platform == "nanopore" ? "ont": "pb"
    """
    tgsgapcloser \\
        ${args} \\
        --thread ${task.cpus} \\
        --ne \\
        --tgstype $tgstype \\
        --scaff $assembly \\
        --reads $reads \\
        --output $prefix

    mv ${prefix}.contig ${prefix}_gapclosed.fa
    pigz ${prefix}_gapclosed.fa
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${assembly.simpleName}"
    """
    touch ${prefix}_gapclosed.fa.gz
    """
}
