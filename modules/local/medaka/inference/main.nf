process MEDAKA_INFERENCE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/1c/1cef7e8a1007b53c6364a8cf61940b0865765479eadd94ff5956ed7711016b8e/data' :
        'community.wave.seqera.io/library/medaka:2.1.0--c9b2fb4c891009f4' }"

    input:
    tuple val(meta), path(bam), path(bai), path(reads), val(contigs)

    output:
    tuple val(meta), path("results.hdf"),                                                              emit: hdf
    tuple val("${task.process}"), val('medaka'), eval('medaka --version 2>&1 | sed "s/medaka //g"'),   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_medaka"
    // Setting nb of threads to 2: https://github.com/nanoporetech/medaka?tab=readme-ov-file#improving-parallelism
    def nb_threads = 2
    """
    #model=\$(medaka tools resolve_model --auto_model consensus a_thaliana_ont_test.fastq.gz)
    #echo \$model

    medaka inference \\
        --threads $nb_threads \\
        --cpu \\
        --full_precision \\
        --check_output \\
        $bam \\
        results.hdf \\
        --regions $contigs
    """
}
