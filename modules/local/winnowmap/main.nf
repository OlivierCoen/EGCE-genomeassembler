process WINNOWMAP {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/winnowmap:2.03--h5ca1c30_3':
        'biocontainers/winnowmap:2.03--h5ca1c30_3' }"

    input:
    tuple val(meta), path(repetitive_kmers), path(ref_fasta), path(ont_reads)

    output:
    tuple val(meta), path("*.paf.gz"),                                              emit: paf
    tuple val("${task.process}"), val('winnowmap'), eval('winnowmap --version'),    topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    winnowmap \
        -x map-ont \
        -W $repetitive_kmers \
         $ref_fasta \
         $ont_reads \
         | gzip -c - \
         > ${prefix}.paf.gz
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """"
    touch ${prefix}.paf
    """
}
