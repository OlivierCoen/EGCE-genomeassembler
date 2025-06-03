process PECAT_FULL {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/23/231c2aa4eeee044916f6093599b721b0f8ab01144062685a5d6fe784a865a25f/data' :
        'community.wave.seqera.io/library/pecat:0.0.3--a2e6fcecffb03038'}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("final_results/primary.fasta"),                                                             emit: primary_assembly
    tuple val(meta), path("final_results/alternate.fasta"),                                                           emit: alternate_assembly
    tuple val(meta), path("final_results/haplotype_1.fasta"), optional: true,                                         emit: haplotype_1_assembly
    tuple val(meta), path("final_results/haplotype_2.fasta"), optional: true,                                         emit: haplotype_2_assembly
    tuple val(meta), path("final_results/rest_first_assembly.fasta"), optional: true,                                      emit: rest_first_assembly
    tuple val(meta), path("final_results/rest_second_assembly.fasta"), optional: true,                                     emit: rest_second_assembly
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions
    tuple val("${task.process}"), val('pecat'), eval('medaka --version | sed "s/medaka //g"'),                                  topic: versions


    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    nanoq -i $ontreads \\
        ${args} \\
        --stats \\
        --header \\
        > ${prefix}_nanoq_summary.tsv
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    echo "" | gzip > ${prefix}.$output_format
    touch ${prefix}.stats
    """
}
