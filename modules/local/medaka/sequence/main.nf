process MEDAKA_SEQUENCE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/1842062447c537b95476a00c46d1f3776096972f66ef0935923ae238a39c16ad/data' :
        'community.wave.seqera.io/library/medaka_pigz:38dfdf8a96315448' }"

    input:
    tuple val(meta), path(hdf_files, stageAs: '*/*'), path(draft_assembly)

    output:
    tuple val(meta), path("*_medaka.fa.gz"),                                                           emit: polished_assembly
    tuple val("${task.process}"), val('medaka'), eval('medaka --version 2>&1 | sed "s/medaka //g"'),   topic: versions
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),              topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_medaka"
    """
    pigz -dkf $draft_assembly
    reference=\$(basename $draft_assembly .gz)

    medaka sequence \\
        --threads $task.cpus \\
        $args \\
        $hdf_files \\
        \$reference \\
        ${prefix}.fa

    pigz ${prefix}.fa
    """
}
