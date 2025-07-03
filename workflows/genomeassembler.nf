/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MANUAL_ASSEMBLY                                         } from '../subworkflows/local/manual_assembly'
include { AUTO_ASSEMBLY                                           } from '../subworkflows/local/auto_assembly'
include { ASSEMBLY_QC                                             } from '../subworkflows/local/assembly_qc'
include { SCAFFOLDING_WITH_HIC                                    } from '../subworkflows/local/scaffolding_with_hic'
include { MULTIQC_WORKFLOW                                        } from '../subworkflows/local/multiqc'

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

        MANUAL_ASSEMBLY (
            ch_input_reads,
            ch_input_draft_assemblies,
            ch_input_haplotype_reads.hap1,
            ch_input_haplotype_reads.hap2,
            ch_input_haplotypes.hap1,
            ch_input_haplotypes.hap2,
            ch_input_hic_reads
        )

        MANUAL_ASSEMBLY.out.assemblies.set { ch_assemblies }
        MANUAL_ASSEMBLY.out.reads.set { ch_reads }
        MANUAL_ASSEMBLY.out.all_draft_assembly_versions_and_alternatives.set { ch_all_draft_assembly_versions_and_alternatives }

        ch_versions = ch_versions.mix ( MANUAL_ASSEMBLY.out.versions )

    } else {

        AUTO_ASSEMBLY (
            ch_input_reads
        )

        AUTO_ASSEMBLY.out.assemblies.set { ch_assemblies }
        AUTO_ASSEMBLY.out.reads.set { ch_reads }
        AUTO_ASSEMBLY.out.draft_assembly_versions.set { ch_all_draft_assembly_versions_and_alternatives }

        ch_versions = ch_versions.mix ( AUTO_ASSEMBLY.out.versions )

    }

    // ------------------------------------------------------------------------------------
    // SCAFFOLDING WITH HIC
    // ------------------------------------------------------------------------------------

    SCAFFOLDING_WITH_HIC (
        ch_input_hic_reads,
        ch_assemblies
    )
    ch_assembly = SCAFFOLDING_WITH_HIC.out.scaffolds_fasta
    ch_versions = ch_versions.mix ( SCAFFOLDING_WITH_HIC.out.versions )


    // ------------------------------------------------------------------------------------
    // QC
    // ------------------------------------------------------------------------------------

    ASSEMBLY_QC (
        ch_reads,
        ch_all_draft_assembly_versions_and_alternatives
    )

    // ------------------------------------------------------------------------------------
    // MULTIQC
    // ------------------------------------------------------------------------------------

    MULTIQC_WORKFLOW ( ch_versions )

    emit:
    multiqc_report = MULTIQC_WORKFLOW.out.multiqc_report.toList()


}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
