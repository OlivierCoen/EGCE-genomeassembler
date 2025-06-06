process WINNOWMAP {
    tag "${ont_reads.simpleName} on ${ref_fasta.simpleName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8e/8e2bc2e2145ff6ea009e5862234630bbc98128146bbe31b040467ef0ad5a4721/data':
        'community.wave.seqera.io/library/samtools_winnowmap:fde47544606aaf19' }"

    input:
    tuple val(meta), path(repetitive_kmers), path(ref_fasta), path(ont_reads)
    val bam_format

    output:
    tuple val(meta), path("*.bam"), path(ref_fasta),                                      optional: true,   emit: bam_ref
    tuple val(meta), path("*.paf.gz"), path(ref_fasta),                                   optional: true,   emit: paf_ref
    tuple val(meta), path("*.bai"),                                                       optional: true,   emit: index
    tuple val("${task.process}"), val('winnowmap'), eval('winnowmap --version'),                            topic: versions
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | awk "{print $2}"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam_index = "${prefix}.bam##idx##${prefix}.bam.bai --write-index"
    def bam_output = bam_format ? "-a | samtools sort -@ ${task.cpus-1} -o ${bam_index} ${args2}" : "-o ${prefix}.paf"
    def gzip_paf_output = bam_format ? "" : "gzip -n ${prefix}.paf"
    def preset = meta.platform == "nanopore" ? "ont": "pb"
    // TODO: complete the preset function
    """
    winnowmap \\
        -x map-${preset} \\
        -W $repetitive_kmers \\
        -y \\
        $ref_fasta \\
        $ont_reads \\
        $bam_output

    $gzip_paf_output
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """"
    touch ${prefix}.paf.gz
    """
}
