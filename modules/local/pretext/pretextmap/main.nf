process PRETEXTMAP {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f0/f048f2ad044b43e5be256953b8dc1131c24fbcbe614083674e7c1396ee70f0a1/data':
        'community.wave.seqera.io/library/pretext-suite:0.0.2--4aad9349908e557f' }"

    input:
    tuple val(meta), path(pairs)

    output:
    tuple val(meta), path("*.pretext"),                                                                      emit: pretext
    tuple val("${task.process}"), val('pretextmap'), eval("PretextMap | sed '/Version/!d; s/.*Version //'"), topic: versions

    script:
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${pairs.baseName}"
    """
    echo $pairs | \\
        PretextMap \\
        $args \\
        -o ${prefix}.pretext
    """
}
