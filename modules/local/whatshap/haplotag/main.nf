process WHATSHAP_HAPLOTAG {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8babad63f830b45fc174b0921fea89d84561d38a562ce4229b59f17887e11581/data':
        'community.wave.seqera.io/library/whatshap:2.7--41cae4706d221f38' }"



    input:
    tuple val(meta), path(bam), path(bai), path(fasta), path(fasta_index), path(vcf), path(vcf_index)

    output:
    tuple val(meta), path("*_haplotagged.bam"),                                emit: haplotagged_bam
    tuple val(meta), path("*_list.txt.gz"),                                    emit: haplotag_list
    tuple val("${task.process}"), val('whatshap'), eval('whatshap --version'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat ${fasta} > assembly.fasta

    whatshap haplotag \\
        --reference assembly.fasta \\
        --output ${prefix}_haplotagged.bam \\
        --output-haplotag-list ${prefix}_list.txt.gz \\
        ${vcf} \\
        ${bam}

    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_list.txt.gz
    touch ${prefix}_haplotagged.bam
    """
}
