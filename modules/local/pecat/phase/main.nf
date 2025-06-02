process PECAT_PHASE {

    tag "${meta.id}"

    label "process_high"

    conda "${projectDir}/deployment/pecat/pecat_clair3/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat_clair3:0.0.3-v1.1.1' :
        'ocoen/pecat_clair3:0.0.3-v1.1.1' }"

    // copy the previous results
    // so that we do not modify the previous step's output and its hash
    // this allow resuming the pipeline
    stageInMode 'copy'

    input:
    tuple val(meta), path(reads), path("correct_results.tar.gz"), path("first_assembly_results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("phase_results.tar.gz"),                                                                              emit: results
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions
    tuple val("${task.process}"), val('clair3'), eval('run_clair3.sh --version | sed "s/Clair3 //g"'),                          topic: versions



    script:
    """
    # ------------------------------------------------------
    # BUILDING PECAT CONFIG
    # ------------------------------------------------------
    build_pecat_config.py \
        --step phase \
        --config ${pecat_config_file} \
        --reads ${reads} \
        --cpus ${task.cpus} \
        --genome-size ${meta.genome_size} \
        --model-path \$(dirname \$(which run_clair3.sh))/models/ont_guppy5/

    # ------------------------------------------------------
    # DECOMPRESSING PREVIOUS RESULT FOLDER
    # ------------------------------------------------------
    tar zxf first_assembly_results.tar.gz
    tar zxf correct_results.tar.gz
    sed -i "s#WORKDIR_TO_REPLACE#\$PWD#g" results/2-align/overlaps.txt

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat.sh phase cfgfile

    # ------------------------------------------------------
    # ARCHIVING RESULT FOLDER
    # ------------------------------------------------------
    rm -rf results/scripts/ results/0-prepare results/1-correct results/2-align
    tar zcf phase_results.tar.gz results/
    rm -rf results/
    """

}
