include { MULTIQC                                                 } from '../../../modules/nf-core/multiqc/main'

include { paramsSummaryMap                                        } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                                    } from '../../nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                                  } from '../../nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                                  } from '../utils_nfcore_genomeassembler_pipeline'


workflow REPORTING {

    take:
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    // ------------------------------------------------------------------------------------
    // VERSIONS
    // ------------------------------------------------------------------------------------

    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
                            .mix(topic_versions_string)
                            .collectFile(
                                storeDir: "${outdir}/pipeline_info",
                                name: 'nf_core_'  +  'variant_calling_software_'  + 'mqc_'  + 'versions.yml',
                                sort: true,
                                newLine: true
                            )

    // ------------------------------------------------------------------------------------
    // CONFIG
    // ------------------------------------------------------------------------------------

    ch_multiqc_config        = channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)

    ch_multiqc_custom_config = multiqc_config ?
        channel.fromPath(multiqc_config, checkIfExists: true) :
        channel.empty()

    ch_multiqc_logo          = multiqc_logo ?
        channel.fromPath(multiqc_logo, checkIfExists: true) :
        channel.empty()

    summary_params      = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_files = ch_multiqc_files
        .mix( ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml') )

    ch_multiqc_custom_methods_description = multiqc_methods_description ?
        file(multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

    ch_methods_description     = channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description)
    )

    ch_multiqc_files = ch_multiqc_files
        .mix( ch_collated_versions )
        .mix(
            ch_methods_description.collectFile(
                name: 'methods_description_mqc.yaml',
                sort: true
            )
        )

    // ------------------------------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------------------------------

    ch_multiqc_files = ch_multiqc_files
                    .mix( channel.topic('mqc_busco_batch_summary') )
                    .mix( channel.topic('mqc_busco_short_summaries_txt') )
                    .mix( channel.topic('mqc_nx_assembly_stats') )
                    .mix( channel.topic('mqc_lx_assembly_stats') )
                    .mix( channel.topic('mqc_fastqc_zip') )
                    .mix( channel.topic('mqc_flye_report') )
                    .mix( channel.topic('mqc_assembly_qv') )
                    .mix( channel.topic('mqc_contigs_qv') )
                    .mix( channel.topic('mqc_nanoq_report') )
                    .mix( channel.topic('mqc_quast_report') )
                    .mix( channel.topic('mqc_pretextsnapshot') )


    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )


    emit:
    multiqc_report = MULTIQC.out.report
}
