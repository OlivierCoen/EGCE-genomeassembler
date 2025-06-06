process SNIFFLES {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/53/53e770c0a98c24e99c242595c537bc49303438addfa7b6123ae1561871444c6b/data' :
        'community.wave.seqera.io/library/sniffles:2.6.2--3effe9696ea3e00c' }"

    input:
    tuple val(meta), path(bam), path(index)


    output:
    tuple val(meta), path("*_sniffles.vcf.gz"),                                                                                emit: vcf
    tuple val(meta), path("*_sniffles.vcf.gz.tbi"),                                                                            emit: tbi
    tuple val("${task.process}"), val('sniffles'), eval('sniffles --help | grep Version | grep -oP "[0-9]+\\.[0-9]+\\.[0-9]+"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    sniffles \\
        ${args} \\
        --input $bam \\
        --vcf ${prefix}_sniffles.vcf.gz \\
        --threads ${task.cpus}
    """
}
