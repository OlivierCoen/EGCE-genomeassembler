process PECAT_SPLIT_CONFIGS {

    tag "${pecat_config_file.name}"
    label "process_low"

    conda "${projectDir}/deployment/pecat/pecat/spec-file.txt"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ocoen/pecat:0.0.3' :
        'ocoen/pecat:0.0.3' }"

    input:
    path pecat_config_file

    output:
    path "correct.cfgfile",         emit: correct
    path "first_assembly.cfgfile",  emit: first_assembly
    path "phase.cfgfile",           emit: phase
    path "second_assembly.cfgfile", emit: second_assembly
    path "polish.cfgfile",          emit: polish


    script:
    """
    split_pecat_custom_configs.py ${pecat_config_file}
    """

}
