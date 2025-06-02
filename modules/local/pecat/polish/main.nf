process PECAT_POLISH {

    tag "${meta.id}"

    label "process_high"

    conda "${projectDir}/deployment/pecat/pecat_medaka/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat_medaka:0.0.3-v1.7.2' :
        'ocoen/pecat_medaka:0.0.3-v1.7.2' }"

    // copy the previous results
    // so that we do not modify the previous step's output and its hash
    // this allow resuming the pipeline
    stageInMode 'copy'

    input:
    tuple val(meta), path(reads), path("correct_results.tar.gz"), path("first_assembly_results.tar.gz"), path("phase_results.tar.gz"), path("second_assembly_results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("final_results/primary.fasta"),                                                             emit: primary_assembly
    tuple val(meta), path("final_results/alternate.fasta"),                                                           emit: alternate_assembly
    tuple val(meta), path("final_results/haplotype_1.fasta"), optional: true,                                         emit: haplotype_1_assembly
    tuple val(meta), path("final_results/haplotype_2.fasta"), optional: true,                                         emit: haplotype_2_assembly
    tuple val(meta), path("final_results/rest_first_assembly.fasta"), optional: true,                                      emit: rest_first_assembly
    tuple val(meta), path("final_results/rest_second_assembly.fasta"), optional: true,                                     emit: rest_second_assembly
    tuple val("${task.process}"), val('pecat'), eval('cat \$(which pecat.pl) | sed -n "s#.*/pecat-\\([0-9.]*\\)-.*#\\1#p"'),    topic: versions
    tuple val("${task.process}"), val('pecat'), eval('medaka --version | sed "s/medaka //g"'),                                  topic: versions



    script:
    """
    # ------------------------------------------------------
    # BUILDING PECAT CONFIG
    # ------------------------------------------------------
    build_pecat_config.py \
        --step polish \
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
    tar zxf second_assembly_results.tar.gz

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat.sh polish cfgfile

    # ------------------------------------------------------
    # RENAMING / REMOVING SOME FILES
    # ------------------------------------------------------
    mkdir final_results
    mv results/6-polish/medaka/primary.fasta final_results/primary.fasta
    mv results/6-polish/medaka/alternate.fasta final_results/alternate.fasta
    mv results/6-polish/medaka/haplotype_1.fasta final_results/haplotype_1.fasta || true
    mv results/6-polish/medaka/haplotype_2.fasta final_results/haplotype_2.fasta || true
    mv results/3-assemble/rest.fasta final_results/rest_first_assembly.fasta || true
    mv results/5-assemble/rest.fasta final_results/rest_second_assembly.fasta || true
    rm -rf results/
    """

}
