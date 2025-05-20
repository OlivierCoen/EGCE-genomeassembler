process MINIMAP2_SELF_ALIGNMENT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/d6/d6b2df22c4ad4b0be8d2ec398104559880f9234ebefe1b37bd86ba22e0d788f3/data':
        'community.wave.seqera.io/library/minimap2:2.29--dde575a222b05b03' }"

    input:
    tuple val(meta), path(assembly_fasta)

    output:
    tuple val(meta), path("*.paf.gz"), emit: paf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gzip -df $assembly_fasta
    cp ${assembly_fasta.baseName} ${assembly_fasta.baseName}.copy

    minimap2 \
        -xasm5 \
        -DP ${assembly_fasta.baseName} ${assembly_fasta.baseName}.copy \
        | gzip -c - \
        > ${prefix}.self_aligned.paf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.paf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}
