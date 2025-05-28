process PECAT_POLISH {

    tag "${meta.id}"

    label "process_high_long"

    conda "${projectDir}/deployment/pecat_medaka/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat_medaka:0.0.3-v1.7.2' :
        'ocoen/pecat_medaka:0.0.3-v1.7.2' }"

    // copy the previous results
    // so that we do not modify the previous step's output and its hash
    // this allow resuming the pipeline
    stageInMode 'copy'

    input:
    tuple val(meta), path(reads), path(previous_results, name: "second_assembly_results.tar.gz")
    path pecat_config_file

    output:
    tuple val(meta), path("results/6-polish/medaka/primary.fasta"),                                                             emit: primary_assembly
    tuple val(meta), path("results/6-polish/medaka/alternate.fasta"),                                                           emit: alternate_assembly
    tuple val(meta), path("results/6-polish/medaka/haplotype_1.fasta"), optional: true,                                         emit: haplotype_1_assembly
    tuple val(meta), path("results/6-polish/medaka/haplotype_2.fasta"), optional: true,                                         emit: haplotype_2_assembly
    tuple val(meta), path("results/3-assemble/rest_first_assembly.fasta"),                                                      emit: rest_first_assembly
    tuple val(meta), path("results/5-assemble/rest_second_assembly.fasta"),                                                     emit: rest_second_assembly
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
    tar zxf second_assembly_results.tar.gz

    # ------------------------------------------------------
    # RUNNING PECAT PIPELINE
    # ------------------------------------------------------
    launch_modified_pecat.sh polish cfgfile

    # ------------------------------------------------------
    # RENAMING SOME FILES
    # ------------------------------------------------------
    mv results/3-assemble/rest.fasta results/3-assemble/rest_first_assembly.fasta
    mv results/5-assemble/rest.fasta results/5-assemble/rest_second_assembly.fasta

    """

}
