process FASTPLONG {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/e5/e53f2d854500cba9b85619f1ae987371c2890f28a6059f4957b1b95a7317b4c7/data':
        'community.wave.seqera.io/library/fastplong:0.4.1--73e8274104613b58' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("${prefix}.fq.gz"), emit: fastq
    tuple val("${task.process}"), val('fastplong'), eval("fastplong --version | cut -d' ' -f2"), topic: versions

    script:
    def args   = task.ext.args   ?: ''
    prefix = task.ext.prefix ?: "${meta.id}.preprocessed"
    """
    fastplong \\
        $args \\
        --in $fastq \\
        --out ${prefix}.fq.gz \\
        --thread ${task.cpus}
    """
}
