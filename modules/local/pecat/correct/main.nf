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
    tuple val(meta), path("results.tar.gz"),                                                                                    emit: results
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
    # IN CASE WE DO NOT USE CONTAINERS, COPYING THE ALTERNATIVE SCRIPT TO THE LOCATION OF THE NATIVE pecat.pl script
    # ------------------------------------------------------
    echo "Container engine: ${workflow.containerEngine ?: 'none'}"
    if [ "${workflow.containerEngine}" = "null" ]; then
        bash ${workflow.projectDir}/bin/copy_modified_pecat_script.sh
    fi

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat_script.sh correct cfgfile

    # ------------------------------------------------------
    # ARCHIVING RESULT FOLDER
    # ------------------------------------------------------
    rm -rf results/scripts/
    tar zcvf results.tar.gz results/
    """

}
