process JUICER_PRE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/2a/2a4a05a859de8175ade33ae14f17898abfa0842864da8779e59ef5630161a9e8/data' :
        'community.wave.seqera.io/library/juicertools_awk:f50b895a6167822a' }"

    input:
    tuple val(meta), path(bin), path(agp), path(fai)

    output:
    tuple val(meta), path("${prefix}.alignments.txt"),  emit: alignments
    tuple val(meta), path("${prefix}.chrom_sizes.txt"), emit: chrom_sizes
    tuple val("${task.process}"), val('juicer'), eval("juicer 2>&1 | grep Version | cut -d' ' -f2"),    topic: versions
    tuple val("${task.process}"), val('awk'),    eval("awk -W version 2>&1 | head -1 | cut -d' ' -f2"), topic: versions


    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """

    """

}
