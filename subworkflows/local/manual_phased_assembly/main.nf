include { ONT_READ_PREPARATION                                    } from '../ont_read_preparation/main'
include { DRAFT_ASSEMBLY                                          } from '../draft_assembly/main'
include { POLISH                                                  } from '../polish'
include { ASSEMBLY_QC                                             } from '../assembly_qc/main'
include { HAPLOTYPE_PHASING                                       } from '../haplotype_phasing'
include { ONT_READ_PREPARATION as HAPLOTYPE_ONT_READ_PREPARATION  } from '../ont_read_preparation'
include { DRAFT_ASSEMBLY as HAPLOTIG_DRAFT_ASSEMBLY               } from '../draft_assembly/main'
include { HAPLOTIG_CLEANING                                       } from '../haplotig_cleaning'
include { ASSEMBLY_QC as HAPLOTIG_ASSEMBLY_QC                     } from '../assembly_qc/main'



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CRITERIA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def polishBranchCriteria = branchCriteria { meta, assembly ->
    polish_me: meta.polish_draft_assembly
    leave_me_alone: !meta.polish_draft_assembly
}

def runHaplotigCleaningCriteria = branchCriteria {
    meta, assembly ->
        to_clean: meta.clean_haplotigs
        leave_me_alone: !meta.clean_haplotigs
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def runAssembly = { meta, assembly -> meta.run_step.assembly }

def runHaplotypePhasing = { meta, assembly -> meta.run_step.haplotype_phasing }

def runHaplotigAssembly = { meta, haplotype_reads -> meta.run_step.haplotig_assembly }

def runHaplotigCleaning = { meta, haplotig -> meta.clean_haplotigs }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow MANUAL_PHASED_ASSEMBLY {

    take:
    ch_input_reads
    ch_input_draft_assemblies
    ch_input_haplotig_1_reads
    ch_input_haplotig_2_reads
    ch_input_haplotigs_1
    ch_input_haplotigs_2
    ch_input_hic_reads

    main:

    // ------------------------------------------------------------------------------------
    // READ PREPARATION
    // ------------------------------------------------------------------------------------

    // by default, we prepare all reads, even for samples for which we do not want an assembly
    // because reads are used at multiple different crucial steps
    ONT_READ_PREPARATION ( ch_input_reads )

    ch_prepared_reads = ONT_READ_PREPARATION.out.prepared_reads

    // --------------------------------------------------------
    // PRIMARY ASSEMBLY
    // --------------------------------------------------------

    DRAFT_ASSEMBLY (
       ch_prepared_reads,
       ch_input_hic_reads
    )

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
        .mix ( ch_input_haplotig_1_reads )
        .mix ( ch_input_haplotig_2_reads )
        .set { ch_haplotig_reads }

    // ------------------------------------------------------------------------------------
    // HAPLOTYPE READ PREPARATION
    // ------------------------------------------------------------------------------------

    HAPLOTYPE_ONT_READ_PREPARATION ( ch_haplotig_reads )

    ch_prepared_haplotig_reads = HAPLOTYPE_ONT_READ_PREPARATION.out.prepared_reads

    // --------------------------------------------------------
    // PRIMARY ASSEMBLY
    // --------------------------------------------------------

    HAPLOTIG_DRAFT_ASSEMBLY (
       ch_prepared_haplotig_reads,
       ch_input_hic_reads
    )

    HAPLOTIG_DRAFT_ASSEMBLY.out.draft_assembly_versions.set { ch_all_haplotig_draft_assembly_versions_and_alternatives }

    // ------------------------------------------------------------------------------------
    // HAPLOTIG CLEANING
    // ------------------------------------------------------------------------------------

    HAPLOTIG_DRAFT_ASSEMBLY.out.assemblies
        .mix ( ch_input_haplotigs_1 )
        .mix ( ch_input_haplotigs_2 )
        .branch ( runHaplotigCleaningCriteria )
        .set { ch_branched_haplotigs }

    HAPLOTIG_CLEANING (
        ch_haplotig_reads,
        ch_branched_haplotigs.to_clean
    )

    ch_branched_haplotigs.leave_me_alone
        .mix ( HAPLOTIG_CLEANING.out.cleaned_haplotigs )
        .set { ch_cleaned_haplotigs }

    ch_all_draft_assembly_versions_and_alternatives
        .mix ( ch_cleaned_haplotigs )
        .set { ch_all_haplotig_draft_assembly_versions_and_alternatives }

    // ------------------------------------------------------------------------------------
    // QUALITY CONTROLS
    // ------------------------------------------------------------------------------------

    HAPLOTIG_ASSEMBLY_QC (
        ch_prepared_haplotig_reads,
        ch_all_haplotig_draft_assembly_versions_and_alternatives
    )

    // ------------------------------------------------------------------------------------
    // VERSIONS
    // ------------------------------------------------------------------------------------

    ONT_READ_PREPARATION.out.versions
        .mix ( ASSEMBLY_QC.out.versions )
        .mix ( HAPLOTYPE_PHASING.out.versions )
        .mix ( HAPLOTYPE_ONT_READ_PREPARATION.out.versions )
        .mix ( HAPLOTIG_CLEANING.out.versions )
        .mix ( HAPLOTIG_ASSEMBLY_QC.out.versions )
        .set { ch_versions }

    emit:
    assemblies                                     = ch_all_draft_assemblies
    haplotigs                                      = ch_cleaned_haplotigs

    flye_report                                    = DRAFT_ASSEMBLY.out.flye_report
    haplotig_flye_report                           = HAPLOTIG_DRAFT_ASSEMBLY.out.flye_report
    assembly_busco_reports                         = ASSEMBLY_QC.out.assembly_busco_reports
    haplotig_assembly_busco_reports                = HAPLOTIG_ASSEMBLY_QC.out.assembly_busco_reports
    fastqc_raw_zip                                 = ONT_READ_PREPARATION.out.fastqc_raw_zip
    fastqc_prepared_reads_zip                      = ONT_READ_PREPARATION.out.fastqc_prepared_reads_zip
    nanoq_stats                                    = ONT_READ_PREPARATION.out.nanoq_stats
    haplotype_reads_fastqc_raw_zip                 = HAPLOTYPE_ONT_READ_PREPARATION.out.fastqc_raw_zip
    haplotype_reads_fastqc_prepared_reads_zip      = HAPLOTYPE_ONT_READ_PREPARATION.out.fastqc_prepared_reads_zip
    haplotype_reads_nanoq_stats                    = HAPLOTYPE_ONT_READ_PREPARATION.out.nanoq_stats

    versions                                       = ch_versions                     // channel: [ versions.yml ]

}
