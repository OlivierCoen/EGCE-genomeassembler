process PECAT_PHASE {

    tag "${meta.id}"

    label "process_high_long"

    conda "${projectDir}/deployment/pecat_clair3/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat_clair3:0.0.3-v1.1.1' :
        'ocoen/pecat_clair3:0.0.3-v1.1.1' }"

    input:
    tuple val(meta), path(reads), path(previous_results, name: "results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("results.tar.gz"),                                                                                    emit: results
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions
    tuple val("${task.process}"), val('clair3'), eval('run_clair3.sh --version | sed "s/Clair3 //g"'),                          topic: versions



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

    phase_clair3_options=--platform=ont --model_path=\$(dirname \$(which run_clair3.sh))/models/ont_guppy5/  --include_all_ctgs
    phase_clair3_command = run_clair3.sh

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
    # DECOMPRESSING PREVIOUS RESULT FOLDER
    # ------------------------------------------------------
    tar zxf results.tar.gz
    sed -i "s#WORKDIR_TO_REPLACE#\$PWD#g" results/2-align/overlaps.txt
    rm results.tar.gz

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat_script.sh phase cfgfile

    # ------------------------------------------------------
    # ARCHIVING RESULT FOLDER
    # ------------------------------------------------------
    rm -rf results/scripts/
    tar zcf results.tar.gz results/
    """

}
