process YAHS {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/e9/e9c62e34fc2b2a7a482d894cc201be6c447d7c90047dc0fd3c6210d6893cd968/data':
        'community.wave.seqera.io/library/yahs_pigz:0ea95483ff8bc79e' }"

    input:
    tuple val(meta), path(hic_map)
    path fasta
    path fai

    output:
    tuple val(meta), path("*scaffolds_final.fa") ,                                          emit: scaffolds_fasta,  optional: true
    tuple val(meta), path("*scaffolds_final.agp"),                                          emit: scaffolds_agp,    optional: true
    tuple val(meta), path("*bin")                ,                                          emit: binary
    tuple val("${task.process}"), val('yahs'), eval('yahs --version 2>&1'),                 topic: versions
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),   topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    pigz -dkf $fasta
    reference=\$(basename $fasta .gz)
    mv $fai "\${reference}.fai"

    yahs $args \\
        -o $prefix \\
        \$reference \\
        $hic_map
    """

    stub:
    """
    touch ${prefix}_scaffold_final.fa
    touch ${prefix}_scaffolds_final.agp
    touch ${prefix}.bin
    """
}
