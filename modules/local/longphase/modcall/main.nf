process LONGPHASE_MODCALL {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ca/ca1f81515569358b58ef065db1705b7393d734adeb4c5c4a5cd99cde65ea1c99/data':
        'community.wave.seqera.io/library/longphase:1.7.3--67cdda0a69288158' }"



    input:
    tuple val(meta), path(bam), path(bai), path(fasta), path(fasta_index)

    output:
    tuple val(meta), path("*_modcalled.vcf"),                                  emit: vcf
    tuple val("${task.process}"), val('longphase'), eval('longphase --help | head -1 | sed "s/Version: //g"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def platform = meta.platform == "nanopore" ? "ont": "pb"
    """
    zcat ${fasta} > assembly.fasta

    longphase modcall \\
        ${args} \\
        --reference assembly.fasta \\
        --bam-file ${bam} \\
        --threads ${task.cpus} \\
        --out-prefix ${prefix} \\
        --${platform}

    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_phased.vcf.gz
    """
}
