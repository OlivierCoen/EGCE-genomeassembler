process MAKE_PAIRS {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8a/8a62f78cadf36e8604db21664b17d45cfa507609e98c377c6c75cc62e70869ff/data':
        'community.wave.seqera.io/library/awk:20250116--f813c541e6052c86' }"

    input:
    tuple val(meta), path(alignments), path(chrom_sizes)

    output:
    tuple val(meta), path("${prefix}.pairs.txt"),                                                    emit: pairs
    tuple val("${task.process}"), val('awk'), eval("awk -W version 2>&1 | head -1 | cut -d' ' -f2"), topic: versions

    script:
    prefix   = task.ext.prefix   ?: "${meta.id}"
    """
    awk \\
        'BEGIN{print "## pairs format v1.0"} {print "#chromsize:\\t"\$1"\\t"\$2} END {print "#columns:\\treadID\\tchr1\\tpos1\\tchr2\\tpos2\\tstrand1\\tstrand2"}' \\
        $chrom_sizes \\
        > ${prefix}.pairs.txt

    awk \\
        '{print ".\\t"\$2"\\t"\$3"\\t"\$6"\\t"\$7"\\t.\t."}' \\
        $alignments \\
        >> ${prefix}.pairs.txt
    """
}
