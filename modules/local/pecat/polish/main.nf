process PECAT_POLISH {

    tag "${meta.id}"

    label "process_high_long"

    conda "${projectDir}/deployment/pecat/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat_medaka:0.0.3-v1.7.2' :
        'ocoen/pecat_medaka:0.0.3-v1.7.2' }"

    input:
    tuple val(meta), path(reads), path(previous_results, name: "results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("results/6-polish/medaka/primary.fasta"),                                                             emit: primary_assembly
    tuple val(meta), path("results/6-polish/medaka/alternate.fasta"),                                                           emit: alternate_assembly
    tuple val(meta), path("results/6-polish/medaka/haplotype_1.fasta"),                                                         emit: haplotype_1_assembly
    tuple val(meta), path("results/6-polish/medaka/haplotype_2.fasta"),                                                         emit: haplotype_2_assembly
    tuple val(meta), path("results/3-assemble/rest_first_assembly.fasta"),                                                      emit: rest_first_assembly
    tuple val(meta), path("results/5-assemble/rest_second_assembly.fasta"),                                                     emit: rest_second_assembly
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions
    tuple val("${task.process}"), val('pecat'), eval('medaka --version | sed "s/medaka //g"'),                                  topic: versions



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

    polish_medaka = 1
    polish_medaka_command = medaka

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
    rm results.tar.gz

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat_script.sh polish cfgfile

    # ------------------------------------------------------
    # RENAMING SOME FILES
    # ------------------------------------------------------
    mv results/3-assemble/rest.fasta results/3-assemble/rest_first_assembly.fasta
    mv results/5-assemble/rest.fasta results/5-assemble/rest_second_assembly.fasta

    """

}
