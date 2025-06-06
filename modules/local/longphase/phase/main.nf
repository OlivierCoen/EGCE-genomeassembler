process LONGPHASE_PHASE {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ca/ca1f81515569358b58ef065db1705b7393d734adeb4c5c4a5cd99cde65ea1c99/data':
        'community.wave.seqera.io/library/longphase:1.7.3--67cdda0a69288158' }"



    input:
    tuple val(meta), path(bam), path(bai), path(fasta), path(fasta_index), path(vcf), path(vcf_index), path(sv_vcf), path(sv_vcf_index)

    output:
    tuple val(meta), path("*_phased.vcf"),                                  emit: vcf
    tuple val("${task.process}"), val('longphase'), eval('longphase --help | head -1 | sed "s/Version: //g"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def platform = meta.platform == "nanopore" ? "ont": "pb"
    def sv_file_arg = sv_vcf && sv_vcf_index ? "--sv-file ${sv_vcf}": ""
    // def mod_file_arg = mod_vcf && mod_vcf_index ? "--mod-file ${mod_vcf}": ""
    """
    zcat ${fasta} > assembly.fasta

    longphase phase \\
        ${args} \\
        --snp-file ${vcf} \\
        ${sv_file_arg} \\
        --reference assembly.fasta \\
        --bam-file ${bam} \\
        --threads ${task.cpus} \\
        --out-prefix ${prefix}_phased \\
        --${platform}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_phased.vcf.gz
    """
}
