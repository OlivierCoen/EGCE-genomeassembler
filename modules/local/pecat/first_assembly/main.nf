process PECAT_FIRST_ASSEMBLY {

    tag "${meta.id}"

    label "process_high_long"

    conda "${projectDir}/deployment/pecat/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat:0.0.3' :
        'ocoen/pecat:0.0.3' }"


    // copy the previous results
    // so that we do not modify the previous step's output and its hash
    // this allow resuming the pipeline
    stageInMode 'copy'

    input:
    tuple val(meta), path(reads), path(previous_results, name: "correct_results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("first_assembly_results.tar.gz"),                                                                                    emit: results
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions


    script:
    """
    # ------------------------------------------------------
    # WRITING THE BASE CONFIGURATION IN THE CONFIG FILE
    # ------------------------------------------------------
    cat <<EOF > cfgfile
    project=results
    reads=${reads}
    genome_size=${meta.genome_size}
    threads=${task.cpus}
    cleanup=1
    grid=local

    EOF

    # ------------------------------------------------------
    # WRITING THE USER-DEFINED PARAMETERS IN THE CONFIG FILE
    # ------------------------------------------------------
    cat ${pecat_config_file} >> cfgfile

    # ------------------------------------------------------
    # DECOMPRESSING PREVIOUS RESULT FOLDER
    # ------------------------------------------------------
    tar zxf correct_results.tar.gz

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat_script.sh first_assembly cfgfile

    # ------------------------------------------------------
    # ARCHIVING RESULT FOLDER
    # ------------------------------------------------------
    rm -rf results/scripts/
    sed -i "s#\$PWD#WORKDIR_TO_REPLACE#g" results/2-align/overlaps.txt
    tar zcf first_assembly_results.tar.gz results/

    """

}
