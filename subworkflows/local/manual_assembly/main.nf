include { LONG_READ_PREPARATION                                              } from '../long_read_preparation/main'
include { LONG_READ_PREPARATION as HAPLOTYPE_LONG_READ_PREPARATION           } from '../long_read_preparation'

include { DRAFT_ASSEMBLY                                                     } from '../draft_assembly/main'
include { DRAFT_ASSEMBLY as HAPLOTYPE_DRAFT_ASSEMBLY                         } from '../draft_assembly/main'

include { HAPLOTYPE_PHASING                                                  } from '../haplotype_phasing'
include { HAPLOTIG_PURGING                                                   } from '../haplotig_purging'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CRITERIA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

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


workflow MANUAL_ASSEMBLY {

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
    ch_all_draft_assemblies.view { v -> "all draft: " + v}
    DRAFT_ASSEMBLY.out.draft_assembly_versions.set { ch_all_draft_assembly_versions_and_alternatives }

    ch_versions = ch_versions
        .mix ( LONG_READ_PREPARATION.out.versions )
        .mix ( DRAFT_ASSEMBLY.out.versions )


    if ( params.assembly_mode == "diploid" ) {

        HAPLOTIG_PURGING (
            ch_prepared_reads,
            ch_all_draft_assemblies
        )

        HAPLOTIG_PURGING.out.purged_assemblies.set { ch_assemblies }

        ch_all_draft_assembly_versions_and_alternatives
            .mix ( HAPLOTIG_PURGING.out.purged_assemblies )
            .set { ch_all_draft_assembly_versions_and_alternatives }

        ch_versions = ch_versions
                        .mix ( HAPLOTIG_PURGING.out.versions )

    } else { // haplotype

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

        HAPLOTYPE_LONG_READ_PREPARATION.out.prepared_reads
            .set { ch_prepared_haplotype_reads }

        // --------------------------------------------------------
        // PRIMARY ASSEMBLY
        // --------------------------------------------------------

        HAPLOTYPE_DRAFT_ASSEMBLY ( ch_prepared_haplotype_reads )

        HAPLOTYPE_DRAFT_ASSEMBLY.out.assemblies
            .mix ( ch_input_haplotypes_1 )
            .mix ( ch_input_haplotypes_2 )
            .set { ch_assemblies }

        ch_all_draft_assembly_versions_and_alternatives
            .mix ( ch_assemblies )
            .mix ( HAPLOTYPE_DRAFT_ASSEMBLY.out.draft_assembly_versions )
            .set { ch_all_draft_assembly_versions_and_alternatives }

        ch_versions = ch_versions
            .mix ( HAPLOTYPE_PHASING.out.versions )
            .mix ( HAPLOTYPE_DRAFT_ASSEMBLY.out.versions )
            .mix ( HAPLOTYPE_LONG_READ_PREPARATION.out.versions )

    }

    emit:
    assemblies                                     = ch_assemblies
    all_draft_assembly_versions_and_alternatives   = ch_all_draft_assembly_versions_and_alternatives
    reads                                          = ch_prepared_reads
    haplotypes                                     = ch_haplotypes

    versions                                       = ch_versions                     // channel: [ versions.yml ]

}
