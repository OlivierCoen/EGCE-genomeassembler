process QUAST {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a5/a515d04307ea3e0178af75132105cd36c87d0116c6f9daecf81650b973e870fd/data' :
        'community.wave.seqera.io/library/quast:5.3.0--755a216045b6dbdd' }"

    input:
    tuple val(meta), path(assembly_list), path(aln_long_reads_assembly_bam_list)


   output:
    path "${meta.id}*/*", emit: results
    path "*report.tsv", emit: tsv
    path "versions.yml", emit: versions


    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def assembly = assembly_list.join(' ')
    def bam = aln_long_reads_assembly_bam_list.join(',')
    println(assembly)
    println(bam)
    """
    quast.py \\
        --output-dir ${prefix} \\
        --threads ${task.cpus} \\
        ${assembly} \\
        --bam ${bam} \\
        ${args}

    ln -s ${prefix}/report.tsv ${prefix}_report.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | grep "QUAST" | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """

}
