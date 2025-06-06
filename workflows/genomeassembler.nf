/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MULTIQC                                                 } from '../modules/nf-core/multiqc/main'

include { MANUAL_PHASED_ASSEMBLY                                  } from '../subworkflows/local/manual_phased_assembly/main'
include { AUTO_PHASED_ASSEMBLY                                    } from '../subworkflows/local/auto_phased_assembly/main'
include { ASSEMBLY_QC                                             } from '../subworkflows/local/assembly_qc/main'
include { SCAFFOLDING_WITH_HIC                                    } from '../subworkflows/local/scaffolding_with_hic/main'


include { paramsSummaryMap                                        } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                                    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { customSoftwareVersionsToYAML                            } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'
include { methodsDescriptionText                                  } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'
include { softwareVersionsToYAML                                  } from '../subworkflows/nf-core/utils_nfcore_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CRITERIA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def inputMultiMapCriteria = multiMapCriteria {
    meta, reads, draft_assembly, haplotype_1_reads, haplotype_2_reads, haplotype_1, haplotype_2, hic_fastq_1, hic_fastq_2 ->

        def first_step = getFirstStep ( reads, draft_assembly, haplotype_1_reads, haplotype_2_reads, haplotype_1, haplotype_2 )
        def run_step_map = createStepMap( first_step )
        def new_meta = meta + [ run_step: run_step_map ]

        reads: reads ? [ new_meta, reads ] : null
        draft_assemblies: draft_assembly ? [ new_meta, draft_assembly ] : null
        haplotype_reads: haplotype_1_reads && haplotype_2_reads ? [ new_meta, haplotype_1_reads, haplotype_2_reads ] : null
        haplotypes: haplotype_1 && haplotype_2 ? [ new_meta, haplotype_1, haplotype_2 ] : null
        hic_reads: hic_fastq_1 && hic_fastq_2 ? [ new_meta, [ hic_fastq_1, hic_fastq_2 ] ] : null
}

def isNotNull = { v -> v != null }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def getOrderedSteps() {
    def ordered_steps = [
        "assembly",
        "haplotype_phasing",
        "haplotype_assembly"
    ]
    return ordered_steps
}


def getFirstStep ( long_reads, assembly, haplotype_1_reads, haplotype_2_reads, haplotype_1, haplotype_2 ) {

    def ordered_steps = getOrderedSteps()

    if ( haplotype_1 && haplotype_2 ) {
        return null
    } else if ( haplotype_1_reads && haplotype_2_reads ) {
        return ordered_steps[-1]
    } else if ( assembly ) {
        return ordered_steps[-2]
    } else if ( long_reads ) {
        return ordered_steps[-3]
    } else {
        error(
            "Could not determine first assembly step to run with provided inputs: ${long_reads}, ${assembly}, ${haplotype_1_reads}, ${haplotype_2_reads}, ${haplotype_1}, ${haplotype_2}"
        )
    }
}


def createStepMap( target_step ) {

    def ordered_steps = getOrderedSteps()

    def step_map = [:]
    def target_index = ordered_steps.indexOf( target_step )

    if (target_index == -1) {
        error("Target step '$target_step' not found in ordered steps")
    }

    ordered_steps.eachWithIndex { step, index ->
        if (index < target_index) {
            step_map[step] = false
        } else {
            step_map[step] = true
        }
    }

    return step_map
}


def putHaplotypeFilesInSeparateChannels ( ch_files ) {
    return ch_files
        .multiMap {
            meta, file_1, file_2 ->
                hap1:
                    [ meta + [ haplotype: 1 ], file_1 ]
                hap2:
                    [ meta + [ haplotype: 2 ], file_2 ]
                }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow GENOMEASSEMBLER {

    take:
    ch_input // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    // ------------------------------------------------------------------------------------
    // INPUT DATA POST-PARSING
    // ------------------------------------------------------------------------------------

    // multiMap the input to separate input files in different channels
    ch_input
        .multiMap ( inputMultiMapCriteria )
        .set { ch_input }

    // filtering out all null data
    ch_input.reads.filter( isNotNull ).set { ch_input_reads }
    ch_input.draft_assemblies.filter( isNotNull ).set { ch_input_draft_assemblies }
    ch_input.haplotype_reads.filter( isNotNull ).set { ch_input_haplotype_reads }
    ch_input.haplotypes.filter( isNotNull ).set { ch_input_haplotypes }
    ch_input.hic_reads.filter( isNotNull ).set { ch_input_hic_reads }

    // separating haplotype-specific files in separate channels
    // we don't do it directly in the multiMap because it gives more flexibility this way
    // in the future, one can add support for polyploid assemblies
    ch_input_haplotype_reads = putHaplotypeFilesInSeparateChannels( ch_input_haplotype_reads )

    ch_input_haplotypes = putHaplotypeFilesInSeparateChannels( ch_input_haplotypes )



    // ------------------------------------------------------------------------------------
    // PHASED ASSEMBLY
    // ------------------------------------------------------------------------------------

    if ( params.assembler in ["hifiasm", "flye"] ) {

        MANUAL_PHASED_ASSEMBLY (
            ch_input_reads,
            ch_input_draft_assemblies,
            ch_input_haplotype_reads.hap1,
            ch_input_haplotype_reads.hap2,
            ch_input_haplotypes.hap1,
            ch_input_haplotypes.hap2,
            ch_input_hic_reads
        )

        MANUAL_PHASED_ASSEMBLY.out.assemblies.set { ch_assemblies }

        // Adding data to MultiQC
        ch_multiqc_files
            .mix( MANUAL_PHASED_ASSEMBLY.out.fastqc_raw_zip.map                                   { meta, zip -> [ zip ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.fastqc_prepared_reads_zip.map                        { meta, zip -> [ zip ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.nanoq_stats.map                                      { meta, stats -> [ stats ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.flye_report.map                                      { meta, report -> [ report ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.busco_batch_summaries.map                            { meta, report -> [ report ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.busco_short_summaries.map                            { meta, report -> [ report ] }.flatten() )
            .mix( MANUAL_PHASED_ASSEMBLY.out.haplotype_reads_fastqc_raw_zip.map                   { meta, zip -> [ zip ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.haplotype_reads_fastqc_prepared_reads_zip.map        { meta, zip -> [ zip ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.haplotype_reads_nanoq_stats.map                      { meta, stats -> [ stats ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.haplotype_flye_report.map                            { meta, report -> [ report ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.haplotype_busco_batch_summaries.map                  { meta, report -> [ report ] } )
            .mix( MANUAL_PHASED_ASSEMBLY.out.haplotype_busco_short_summaries.map                  { meta, report -> [ report ] }.flatten() )
            .set { ch_multiqc_files }

        ch_versions = ch_versions.mix ( MANUAL_PHASED_ASSEMBLY.out.versions )

    } else {

        AUTO_PHASED_ASSEMBLY (
            ch_input_reads
        )

        AUTO_PHASED_ASSEMBLY.out.assemblies.set { ch_assemblies }

        // Adding data to MultiQC
        ch_multiqc_files
            .mix( AUTO_PHASED_ASSEMBLY.out.busco_batch_summaries.map { meta, report -> [ report ] } )
            .mix( AUTO_PHASED_ASSEMBLY.out.busco_short_summaries.map { meta, report -> [ report ] }.flatten() )
            .set { ch_multiqc_files }

        ch_versions = ch_versions.mix ( AUTO_PHASED_ASSEMBLY.out.versions )

    }

    // ------------------------------------------------------------------------------------
    // SCAFFOLDING WITH HIC
    // ------------------------------------------------------------------------------------
    /*
    SCAFFOLDING_WITH_HIC (
        ch_input_hic_reads,
        ch_assemblies
    )
    ch_assembly = SCAFFOLDING_WITH_HIC.out.scaffolds_fasta
    ch_versions = ch_versions.mix ( SCAFFOLDING_WITH_HIC.out.versions )
    */
    // ------------------------------------------------------------------------------------
    // VERSIONS
    // ------------------------------------------------------------------------------------

    //ch_versions = ch_versions
                    //.mix ( SCAFFOLDING_WITH_HIC.out.versions )

    // Collate and save software versions obtained from topic channels
    // TODO: use the nf-core functions when they are adapted to channel topics

    ch_collated_versions = customSoftwareVersionsToYAML( Channel.topic('versions') )
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'software_mqc_topic_versions.yml',
            sort: true,
            newLine: true
        )
    ch_versions = ch_versions.concat( Channel.fromPath("${params.outdir}/pipeline_info/software_mqc_topic_versions.yml") )

    // Collate and save software versions
    softwareVersionsToYAML( ch_versions )
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    // ------------------------------------------------------------------------------------
    // MULTIQC
    // ------------------------------------------------------------------------------------

    ch_multiqc_config = Channel.fromPath( "$projectDir/assets/multiqc_config.yml", checkIfExists: true )

    summary_params = paramsSummaryMap( workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value( paramsSummaryMultiqc(summary_params) )

    ch_multiqc_custom_config = params.multiqc_config ?
                                    Channel.fromPath(params.multiqc_config, checkIfExists: true) :
                                    Channel.empty()

    ch_multiqc_logo = params.multiqc_logo ?
                        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
                        Channel.empty()

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
                                                file(params.multiqc_methods_description, checkIfExists: true) :
                                                file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

    ch_methods_description = Channel.value( methodsDescriptionText(ch_multiqc_custom_methods_description) )

    // Adding metadata to MultiQC
    ch_multiqc_files = ch_multiqc_files
                            .mix( ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml') )
                            .mix( ch_collated_versions )
                            .mix( ch_methods_description.collectFile( name: 'methods_description_mqc.yaml', sort: true ) )



    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList()


}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
