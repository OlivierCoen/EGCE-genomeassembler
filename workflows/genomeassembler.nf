/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MULTIQC                                                 } from '../modules/nf-core/multiqc/main'

include { ONT_READ_PREPARATION                                    } from '../subworkflows/local/ont_read_preparation/main'
include { ASSEMBLY                                                } from '../subworkflows/local/assembly/main'
include { ASSEMBLY as HAPLOTIG_ASSEMBLY                           } from '../subworkflows/local/assembly/main'
include { HAPLOTYPE_PHASING                                       } from '../subworkflows/local/haplotype_phasing/main'
include { HAPLOTIG_CLEANING                                       } from '../subworkflows/local/haplotig_cleaning/main'
include { SCAFFOLDING_WITH_HIC                                    } from '../subworkflows/local/scaffolding_with_hic/main'
include { ASSEMBLY_QC                                             } from '../subworkflows/local/assembly_qc/main'
include { ASSEMBLY_QC as HAPLOTIG_ASSEMBLY_QC                     } from '../subworkflows/local/assembly_qc/main'

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
    meta, reads, draft_assembly, haplotype_1_reads, haplotype_2_reads, haplotig_1, haplotig_2, hic_fastq_1, hic_fastq_2 ->

        def first_step = getFirstStep ( reads, draft_assembly, haplotype_1_reads, haplotype_2_reads, haplotig_1, haplotig_2 )
        def run_step_map = createStepMap( first_step )
        def new_meta = meta + [ run_step: run_step_map ]

        reads: reads ? [ new_meta, reads ] : null
        draft_assemblies: draft_assembly ? [ new_meta, draft_assembly ] : null
        haplotype_reads: haplotype_1_reads && haplotype_2_reads ? [ new_meta, haplotype_1_reads, haplotype_2_reads ] : null
        haplotigs: haplotig_1 && haplotig_2 ? [ new_meta, haplotig_1, haplotig_2 ] : null
        hic_reads: hic_fastq_1 && hic_fastq_2 ? [ new_meta, [ hic_fastq_1, hic_fastq_2 ] ] : null
}

def runHaplotigCleaningCriteria = branchCriteria {
    meta, assembly ->
        to_clean: meta.clean_haplotigs
        leave_me_alone: !meta.clean_haplotigs
}

def isNotNull = { v -> v != null }

def runAssembly = { meta, assembly -> meta.run_step.assembly }

def runHaplotypePhasing = { meta, assembly -> meta.run_step.haplotype_phasing }

def runHaplotigAssembly = { meta, haplotype_reads -> meta.run_step.haplotig_assembly }

def runHaplotigCleaning = { meta, haplotig -> meta.clean_haplotigs }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def getOrderedSteps() {
    def ordered_steps = [
        "assembly",
        "haplotype_phasing",
        "haplotig_assembly"
    ]
    return ordered_steps
}


def getFirstStep ( long_reads, assembly, haplotype_1_reads, haplotype_2_reads, haplotig_1, haplotig_2 ) {

    def ordered_steps = getOrderedSteps()

    if ( haplotig_1 && haplotig_2 ) {
        return null
    } else if ( haplotype_1_reads && haplotype_2_reads ) {
        return ordered_steps[-1]
    } else if ( assembly ) {
        return ordered_steps[-2]
    } else if ( long_reads ) {
        return ordered_steps[-3]
    } else {
        error(
            "Could not determine first assembly step to run with provided inputs: ${long_reads}, ${assembly}, ${haplotype_1_reads}, ${haplotype_2_reads}, ${haplotig_1}, ${haplotig_2}"
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


def putHaplotigFilesInSeparateChannels ( ch_files ) {
    return ch_files
        .multiMap {
            meta, file_1, file_2 ->
                hap1:
                    [ meta + [ haplotig: 1 ], file_1 ]
                hap2:
                    [ meta + [ haplotig: 2 ], file_2 ]
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
    ch_input.haplotigs.filter( isNotNull ).set { ch_input_haplotigs }
    ch_input.hic_reads.filter( isNotNull ).set { ch_input_hic_reads }

    // separating haplotig-specific files in separate channels
    // we don't do it directly in the multiMap because it gives more flexibility this way
    // in the future, one can add support for polyploid assemblies
    ch_input_haplotype_reads = putHaplotigFilesInSeparateChannels( ch_input_haplotype_reads )

    ch_input_haplotigs = putHaplotigFilesInSeparateChannels( ch_input_haplotigs )

    // ------------------------------------------------------------------------------------
    // READ PREPARATION
    // ------------------------------------------------------------------------------------

    // by default, we prepare all reads, even for samples for which we do not want an assembly
    // because reads are used at multiple different crucial steps
    ONT_READ_PREPARATION ( ch_input_reads )

    ch_reads = ONT_READ_PREPARATION.out.prepared_reads

    // ------------------------------------------------------------------------------------
    // ASSEMBLY
    // ------------------------------------------------------------------------------------

    ASSEMBLY (
       ch_reads.filter ( runAssembly )
    )

    // ------------------------------------------------------------------------------------
    // QUALITY CONTROLS
    // ------------------------------------------------------------------------------------

    ch_input_draft_assemblies
       .mix ( ASSEMBLY.out.draft_assembly_versions )
       .set { all_assembly_versions }

    ASSEMBLY_QC (
        ch_reads,
        all_assembly_versions
    )

    // ------------------------------------------------------------------------------------
    // HAPLOTYPE PHASING
    // ------------------------------------------------------------------------------------

    ASSEMBLY.out.assemblies
        .mix ( ch_input_draft_assemblies )
        .filter ( runHaplotypePhasing )
        .set { ch_draft_assemblies_to_phase }

    HAPLOTYPE_PHASING (
        ch_reads,
        ch_draft_assemblies_to_phase
    )

    // ------------------------------------------------------------------------------------
    // HAPLOTIG ASSEMBLIES
    // ------------------------------------------------------------------------------------

    HAPLOTYPE_PHASING.out.haplotype_reads
        .mix ( ch_input_haplotype_reads.hap1 )
        .mix ( ch_input_haplotype_reads.hap2 )
        .set { ch_haplotig_reads }

    HAPLOTIG_ASSEMBLY (
        ch_haplotig_reads.filter ( runHaplotigAssembly )
    )

    // ------------------------------------------------------------------------------------
    // HAPLOTIG CLEANING
    // ------------------------------------------------------------------------------------

    HAPLOTIG_ASSEMBLY.out.assemblies
        .mix ( ch_input_haplotigs.hap1 )
        .mix ( ch_input_haplotigs.hap2 )
        .branch ( runHaplotigCleaningCriteria )
        .set { ch_branched_haplotigs }

    HAPLOTIG_CLEANING (
        ch_haplotig_reads,
        ch_branched_haplotigs.to_clean
    )

    ch_branched_haplotigs.leave_me_alone
        .mix ( HAPLOTIG_CLEANING.out.cleaned_haplotigs )
        .set { ch_cleaned_haplotigs }

    // ------------------------------------------------------------------------------------
    // QUALITY CONTROLS
    // ------------------------------------------------------------------------------------

    ch_input_haplotigs.hap1
       .mix ( ch_input_haplotigs.hap2 )
       .mix ( HAPLOTIG_ASSEMBLY.out.draft_assembly_versions )
       .mix ( ch_cleaned_haplotigs )
       .set { all_haplotig_assembly_versions }

    HAPLOTIG_ASSEMBLY_QC (
        ch_haplotig_reads,
        all_haplotig_assembly_versions
    )

    // ------------------------------------------------------------------------------------
    // SCAFFOLDING WITH HIC
    // ------------------------------------------------------------------------------------

    /*
    if ( !params.skip_scaffolding_with_hic ) {
        SCAFFOLDING_WITH_HIC ( ch_hic_reads, ch_assembly )
        ch_assembly = SCAFFOLDING_WITH_HIC.out.scaffolds_fasta
        ch_versions = ch_versions.mix ( SCAFFOLDING_WITH_HIC.out.versions )
    }
    */


    // ------------------------------------------------------------------------------------
    // VERSIONS
    // ------------------------------------------------------------------------------------

    ch_versions = ch_versions
                    .mix ( ONT_READ_PREPARATION.out.versions )
                    .mix ( ASSEMBLY.out.versions )
                    .mix ( ASSEMBLY_QC.out.versions )
                    .mix ( HAPLOTYPE_PHASING.out.versions )
                    .mix ( HAPLOTIG_ASSEMBLY.out.versions )
                    .mix ( HAPLOTIG_CLEANING.out.versions )
                    .mix ( HAPLOTIG_ASSEMBLY_QC.out.versions )
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
    ch_multiqc_files = Channel.empty()
                            .mix( ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml') )
                            .mix( ch_collated_versions )
                            .mix( ch_methods_description.collectFile( name: 'methods_description_mqc.yaml', sort: true ) )

    // Adding data to MultiQC
    ch_multiqc_files = ch_multiqc_files
                        .mix( ONT_READ_PREPARATION.out.fastqc_raw_zip.map            { meta, zip -> [ zip ] } )
                        .mix( ONT_READ_PREPARATION.out.fastqc_prepared_reads_zip.map { meta, zip -> [ zip ] } )
                        .mix( ONT_READ_PREPARATION.out.nanoq_stats.map               { meta, stats -> [ stats ] } )
                        .mix( ASSEMBLY.out.flye_report.map                           { meta, report -> [ report ] } )
                        .mix( ASSEMBLY_QC.out.assembly_busco_reports.map                        { meta, report -> [ report ] } )
                        .mix( HAPLOTIG_ASSEMBLY_QC.out.assembly_busco_reports.map       { meta, report -> [ report ] } )
                        .mix( HAPLOTIG_ASSEMBLY.out.flye_report.map                  { meta, report -> [ report ] } )

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
