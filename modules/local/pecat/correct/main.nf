process PECAT_CORRECT {

    tag "${meta.id}"

    label "process_high_long"

    conda "${projectDir}/deployment/pecat/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat:0.0.3' :
        'ocoen/pecat:0.0.3' }"

    input:
    tuple val(meta), path(reads)
    path pecat_config_file

    output:
    tuple val(meta), path("correct_results.tar.gz"),                                                                            emit: results
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions

    script:
    """
    # ------------------------------------------------------
    # BUILDING PECAT CONFIG
    # ------------------------------------------------------
    build_pecat_config.py \
        --step correct \
        --config ${pecat_config_file} \
        --reads ${reads} \
        --cpus ${task.cpus} \
        --genome-size ${meta.genome_size}

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat.sh correct cfgfile

    # ------------------------------------------------------
    # ARCHIVING RESULT FOLDER
    # ------------------------------------------------------
    rm -rf results/scripts/
    tar zcvf correct_results.tar.gz results/
    rm -rf results/
    """

}
