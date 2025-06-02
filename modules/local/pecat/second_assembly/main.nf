process PECAT_SECOND_ASSEMBLY {

    tag "${meta.id}"

    label "process_high"

    conda "${projectDir}/deployment/pecat/pecat/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat:0.0.3' :
        'ocoen/pecat:0.0.3' }"

    // copy the previous results
    // so that we do not modify the previous step's output and its hash
    // this allow resuming the pipeline
    stageInMode 'copy'

    input:
    tuple val(meta), path(reads), path("correct_results.tar.gz"), path("first_assembly_results.tar.gz"), path("phase_results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("second_assembly_results.tar.gz"),                                                                                     emit: results
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),     topic: versions


    script:
    """
    # ------------------------------------------------------
    # BUILDING PECAT CONFIG
    # ------------------------------------------------------
    build_pecat_config.py \
        --step second_assembly \
        --config ${pecat_config_file} \
        --reads ${reads} \
        --cpus ${task.cpus} \
        --genome-size ${meta.genome_size}

    # ------------------------------------------------------
    # DECOMPRESSING PREVIOUS RESULT FOLDER
    # ------------------------------------------------------
    tar zxf first_assembly_results.tar.gz
    tar zxf correct_results.tar.gz
    tar zxf phase_results.tar.gz

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat.sh second_assembly cfgfile

    # ------------------------------------------------------
    # ARCHIVING RESULT FOLDER
    # ------------------------------------------------------
    rm -rf results/scripts/ results/0-prepare results/1-correct results/2-align results/3-assemble results/4-phase
    tar zcf second_assembly_results.tar.gz results/
    rm -rf results/
    """

}
