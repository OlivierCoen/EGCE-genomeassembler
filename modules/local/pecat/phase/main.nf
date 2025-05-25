process PECAT_PHASE {

    tag "${meta.id}"

    label "process_high_long"

    conda "${projectDir}/deployment/pecat_clair3/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat_clair3:0.0.3-v1.1.1' :
        'ocoen/pecat_clair3:0.0.3-v1.1.1' }"

    def local_script = "${workflow.projectDir}/bin/modified_pecat.pl"
    def container_script = "/opt/conda/share/pecat-0.0.3-0/bin/modified_pecat.pl"

    containerOptions = {
        if (workflow.containerEngine in ['singularity', 'apptainer', 'charliecloud']) {
            return "--bind ${local_script}:${container_script}"
        } else { // docker, podman, shifter
            return "--volume ${local_script}:${container_script}"
        }
    }



    input:
    tuple val(meta), path(reads), path(previous_results, name: "results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("results.tar.gz"),    emit: results
    path "versions.yml",                        emit: versions


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

    # ------------------------------------------------------
    # PRINTING VERSIONS
    # ------------------------------------------------------
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pecat: \$(cat \$(which pecat.pl) | sed -n 's#.*/pecat-\\([0-9.]*\\)-.*#\\1#p')
        clair3: \$(run_clair3.sh --version | sed 's/Clair3 //g')
    END_VERSIONS
    """

}
