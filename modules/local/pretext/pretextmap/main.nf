process PRETEXTMAP {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f0/f048f2ad044b43e5be256953b8dc1131c24fbcbe614083674e7c1396ee70f0a1/data':
        'community.wave.seqera.io/library/pretext-suite:0.0.2--4aad9349908e557f' }"

    input:
    tuple val(meta), path(alignments), path(chrom_sizes)

    output:
    tuple val(meta), path("*.pretext"),                                                                      emit: pretext
    tuple val("${task.process}"), val('pretextmap'), eval("PretextMap | sed '/Version/!d; s/.*Version //'"), topic: versions

    script:
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"
    """
    ( awk \\
        'BEGIN{print "## pairs format v1.0"} {print "#chromsize:\\t"\$1"\\t"\$2} END {print "#columns:\\treadID\\tchr1\\tpos1\\tchr2\\tpos2\\tstrand1\\tstrand2"}' \\
        $chrom_sizes;
    awk \\
        '{print ".\\t"\$2"\\t"\$3"\\t"\$6"\\t"\$7"\\t.\t."}' \\
        $alignments \\
    ) | \\
        PretextMap \\
        $args \\
        -o ${prefix}.pretext
    """
}
