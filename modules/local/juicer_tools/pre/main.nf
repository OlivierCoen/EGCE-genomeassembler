process JUICERTOOLS_PRE {
    tag "$meta.id"
    label 'process_medium'
    errorStrategy 'ignore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/2a/2a4a05a859de8175ade33ae14f17898abfa0842864da8779e59ef5630161a9e8/data' :
        'community.wave.seqera.io/library/juicertools_awk:f50b895a6167822a' }"

    input:
    tuple val(meta), path(alignments), path(chrom_sizes)

    output:
    tuple val(meta), path("${prefix}.hic"), emit: hic
    tuple val("${task.process}"), val('juicer'), eval("juicer_tools -V | grep Version | cut -d' ' -f4"), topic: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "Running Juicertools Pre"
    juicer_tools pre $args $alignments ${prefix}.hic $chrom_sizes
    """

}
