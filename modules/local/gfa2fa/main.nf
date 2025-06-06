process GFA_2_FA {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/52ccce28d2ab928ab862e25aae26314d69c8e38bd41ca9431c67ef05221348aa/data'
        : 'community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8'}"

    input:
    tuple val(meta), path(gfa_file)

    output:
    tuple val(meta), path("*fa.gz"), emit: fasta
    tuple val("${task.process}"), val('awk'), eval('echo \$(awk --version | head -n1 | sed "s/mawk //; s/ .*//")'),   topic: versions
    tuple val("${task.process}"), val('gzip'), eval('echo \$(gzip --version | head -n1 | sed "s/gzip //")'),          topic: versions

    script:
    """
    awk '/^S/{print ">"\$2;print \$3}' ${gfa_file} \\
        | gzip > ${gfa_file.simpleName}.fa.gz
    """

    stub:
    """
    touch ${gfa_file.simpleName}.fa.gz
    """
}
