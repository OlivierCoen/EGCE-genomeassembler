include { LONG_READ_PREPARATION                                              } from '../long_read_preparation/main'
include { DRAFT_ASSEMBLY                                                     } from '../draft_assembly/main'
include { POLISH                                                             } from '../polish'
include { ASSEMBLY_QC                                                        } from '../assembly_qc/main'
include { HAPLOTYPE_PHASING                                                  } from '../haplotype_phasing'
include { LONG_READ_PREPARATION as HAPLOTYPE_LONG_READ_PREPARATION           } from '../long_read_preparation'
include { DRAFT_ASSEMBLY as HAPLOTYPE_DRAFT_ASSEMBLY                         } from '../draft_assembly/main'
//include { HAPLOTIG_CLEANING                                                } from '../haplotig_cleaning'
include { ASSEMBLY_QC as HAPLOTYPE_ASSEMBLY_QC                               } from '../assembly_qc/main'



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CRITERIA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def polishBranchCriteria = branchCriteria { meta, assembly ->
    polish_me: meta.polish_draft_assembly
    leave_me_alone: !meta.polish_draft_assembly
}

/*
def runHaplotypeCleaningCriteria = branchCriteria {
    meta, assembly ->
        to_clean: meta.clean_haplotypes
        leave_me_alone: !meta.clean_haplotypes
}
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def runAssembly = { meta, assembly -> meta.run_step.assembly }

def runHaplotypePhasing = { meta, assembly -> meta.run_step.haplotype_phasing }

def runHaplotypeAssembly = { meta, haplotype_reads -> meta.run_step.haplotype_assembly }

def runHaplotypeCleaning = { meta, haplotype -> meta.clean_haplotypes }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow MANUAL_PHASED_ASSEMBLY {

    take:
    ch_input_reads
    ch_input_draft_assemblies
    ch_input_haplotype_1_reads
    ch_input_haplotype_2_reads
    ch_input_haplotypes_1
    ch_input_haplotypes_2
    ch_input_hic_reads

    main:

    ch_versions = Channel.empty()
    ch_haplotypes = Channel.empty()
    ch_haplotype_busco_batch_summaries = Channel.empty()
    ch_haplotype_busco_short_summaries = Channel.empty()
    ch_haplotype_reads_fastqc_raw_zip = Channel.empty()
    ch_haplotype_reads_fastqc_prepared_reads_zip = Channel.empty()
    ch_haplotype_reads_nanoq_stats = Channel.empty()
    ch_haplotype_flye_report = Channel.empty()

    // ------------------------------------------------------------------------------------
    // READ PREPARATION
    // ------------------------------------------------------------------------------------

    // by default, we prepare all reads, even for samples for which we do not want an assembly
    // because reads are used at multiple different crucial steps
    LONG_READ_PREPARATION ( ch_input_reads )

    ch_prepared_reads = LONG_READ_PREPARATION.out.prepared_reads

    // --------------------------------------------------------
    // PRIMARY ASSEMBLY
    // --------------------------------------------------------

    DRAFT_ASSEMBLY ( ch_prepared_reads )

    DRAFT_ASSEMBLY.out.assemblies
        .mix ( ch_input_draft_assemblies )
        .set { ch_all_draft_assemblies }

    DRAFT_ASSEMBLY.out.draft_assembly_versions.set { ch_all_draft_assembly_versions_and_alternatives }

    // ------------------------------------------------------------------------------------
    // QUALITY CONTROLS
    // ------------------------------------------------------------------------------------

    ASSEMBLY_QC (
        ch_prepared_reads,
        ch_all_draft_assembly_versions_and_alternatives
    )

    ch_versions = ch_versions
        .mix ( LONG_READ_PREPARATION.out.versions )
        .mix ( DRAFT_ASSEMBLY.out.versions )
        .mix ( ASSEMBLY_QC.out.versions )


    if ( params.assembly_mode == "diploid" ) {

        ch_all_draft_assemblies.set { ch_assemblies }

    } else { // haploype

        // ------------------------------------------------------------------------------------
        // HAPLOTYPE PHASING
        // ------------------------------------------------------------------------------------

        ch_all_draft_assemblies
            .filter ( runHaplotypePhasing )
            .set { ch_all_draft_assemblies_to_phase }

        HAPLOTYPE_PHASING (
            ch_prepared_reads,
            ch_all_draft_assemblies_to_phase
        )

        HAPLOTYPE_PHASING.out.haplotype_reads
            .mix ( ch_input_haplotype_1_reads )
            .mix ( ch_input_haplotype_2_reads )
            .set { ch_haplotype_reads }

        // ------------------------------------------------------------------------------------
        // HAPLOTYPE READ PREPARATION
        // ------------------------------------------------------------------------------------

        HAPLOTYPE_LONG_READ_PREPARATION ( ch_haplotype_reads )

        HAPLOTYPE_LONG_READ_PREPARATION.out.prepared_reads.set { ch_prepared_haplotype_reads }
        HAPLOTYPE_LONG_READ_PREPARATION.out.fastqc_raw_zip.set { ch_haplotype_reads_fastqc_raw_zip }
        HAPLOTYPE_LONG_READ_PREPARATION.out.fastqc_prepared_reads_zip.set { ch_haplotype_reads_fastqc_prepared_reads_zip }
        HAPLOTYPE_LONG_READ_PREPARATION.out.nanoq_stats.set { ch_haplotype_reads_nanoq_stats }

        // --------------------------------------------------------
        // PRIMARY ASSEMBLY
        // --------------------------------------------------------

        HAPLOTYPE_DRAFT_ASSEMBLY ( ch_prepared_haplotype_reads )

        HAPLOTYPE_DRAFT_ASSEMBLY.out.draft_assembly_versions.set { ch_all_haplotype_draft_assembly_versions_and_alternatives }
        HAPLOTYPE_DRAFT_ASSEMBLY.out.flye_report.set { ch_haplotype_flye_report }

        HAPLOTYPE_DRAFT_ASSEMBLY.out.assemblies
            .mix ( ch_input_haplotypes_1 )
            .mix ( ch_input_haplotypes_2 )
            .set { ch_assemblies }

        // ------------------------------------------------------------------------------------
        // QUALITY CONTROLS
        // ------------------------------------------------------------------------------------

        HAPLOTYPE_ASSEMBLY_QC (
            ch_prepared_haplotype_reads,
            ch_all_draft_assembly_versions_and_alternatives
        )

        HAPLOTYPE_ASSEMBLY_QC.out.busco_batch_summaries .set { ch_haplotype_busco_batch_summaries }
        HAPLOTYPE_ASSEMBLY_QC.out.busco_short_summaries.set { ch_haplotype_busco_short_summaries }

        ch_versions = ch_versions
        .mix ( HAPLOTYPE_PHASING.out.versions )
        .mix ( HAPLOTYPE_DRAFT_ASSEMBLY.out.versions )
        .mix ( HAPLOTYPE_LONG_READ_PREPARATION.out.versions )
        .mix ( HAPLOTYPE_ASSEMBLY_QC.out.versions )

    }

    emit:
    assemblies                                     = ch_assemblies
    haplotypes                                     = ch_haplotypes

    flye_report                                    = DRAFT_ASSEMBLY.out.flye_report
    haplotype_flye_report                          = ch_haplotype_flye_report
    busco_batch_summaries                          = ASSEMBLY_QC.out.busco_batch_summaries
    busco_short_summaries                          = ASSEMBLY_QC.out.busco_short_summaries
    haplotype_busco_batch_summaries                = ch_haplotype_busco_batch_summaries
    haplotype_busco_short_summaries                = ch_haplotype_busco_short_summaries
    fastqc_raw_zip                                 = LONG_READ_PREPARATION.out.fastqc_raw_zip
    fastqc_prepared_reads_zip                      = LONG_READ_PREPARATION.out.fastqc_prepared_reads_zip
    nanoq_stats                                    = LONG_READ_PREPARATION.out.nanoq_stats
    haplotype_reads_fastqc_raw_zip                 = ch_haplotype_reads_fastqc_raw_zip
    haplotype_reads_fastqc_prepared_reads_zip      = ch_haplotype_reads_fastqc_prepared_reads_zip
    haplotype_reads_nanoq_stats                    = ch_haplotype_reads_nanoq_stats

    versions                                       = ch_versions                     // channel: [ versions.yml ]

}
