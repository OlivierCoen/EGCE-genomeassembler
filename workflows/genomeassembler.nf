/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { LONG_READ_PREPARATION                                              } from '../subworkflows/local/long_read_preparation'
include { DRAFT_ASSEMBLY                                                     } from '../subworkflows/local/draft_assembly'
include { POLISH                                                             } from '../subworkflows/local/polish'
include { PURGE_DUPLICATES as DRAFT_ASSEMBLY_PURGING                         } from '../subworkflows/local/purge_duplicates'
include { HIC_SHORT_READS_PREPARATION                                        } from '../subworkflows/local/hic_short_reads_preparation'
include { SCAFFOLDING_WITH_HIC                                               } from '../subworkflows/local/scaffolding_with_hic'
include { PURGE_DUPLICATES as SCAFFOLDED_ASSEMBLY_PURGING                    } from '../subworkflows/local/purge_duplicates'
include { CLOSE_GAPS                                                         } from '../subworkflows/local/close_gaps'
include { ASSEMBLY_QC                                                        } from '../subworkflows/local/assembly_qc'
include { REPORTING                                                          } from '../subworkflows/local/reporting'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow GENOME_ASSEMBLER {

    take:
    ch_input // channel: samplesheet read in from --input

    main:

    // ------------------------------------------------------------------------------------
    // INPUT DATA POST-PARSING
    // ------------------------------------------------------------------------------------

    // multiMap the input to separate input files in different channels
    ch_input = ch_input.multiMap{
                            meta, reads, hic_fastq_1, hic_fastq_2, assembly ->
                                reads: reads ? [ meta, reads ] : null
                                hic_reads: hic_fastq_1 && hic_fastq_2 ? [ meta, [ hic_fastq_1, hic_fastq_2 ] ] : null
                                assembly: assembly ? [ meta, assembly ] : null
                        }

    ch_long_reads = ch_input.reads
    ch_assemblies = ch_input.assembly
    ch_hic_reads = ch_input.hic_reads

    // ch_all_draft_assembly_versions_and_alternatives = ch_assemblies

    // ------------------------------------------------------------------------------------
    // READ PREPARATION
    // ------------------------------------------------------------------------------------


    if ( !params.skip_long_read_preparation ) {

        LONG_READ_PREPARATION ( ch_long_reads )
        ch_long_reads = LONG_READ_PREPARATION.out.prepared_reads

    }

    // --------------------------------------------------------
    // PRIMARY ASSEMBLY
    // --------------------------------------------------------

    if ( !params.skip_draft_assembly ) {

        DRAFT_ASSEMBLY ( ch_long_reads )
        ch_assemblies = DRAFT_ASSEMBLY.out.assemblies

    }

    // --------------------------------------------------------
    // POLISHING
    // --------------------------------------------------------

    if ( !params.skip_draft_assembly_polishing ) {

        POLISH (
            ch_long_reads,
            ch_assemblies
        )
        ch_assemblies = POLISH.out.assemblies

    }

    // --------------------------------------------------------
    // HAPLOTIG PURGING OF DRAFT ASSEMBLY
    // --------------------------------------------------------

    if ( !params.skip_draft_assembly_purging ) {
        DRAFT_ASSEMBLY_PURGING (
            ch_long_reads,
            ch_assemblies
        )
        ch_assemblies = DRAFT_ASSEMBLY_PURGING.out.purged_assemblies

    }

    // --------------------------------------------------------
    // Hi-C SHORT READ PREPARATION
    // --------------------------------------------------------

     if ( !params.skip_short_read_preparation ) {

        HIC_SHORT_READS_PREPARATION ( ch_hic_reads )
        ch_hic_reads = HIC_SHORT_READS_PREPARATION.out.prepared_hic_short_reads

     }

    // ------------------------------------------------------------------------------------
    // SCAFFOLDING WITH HIC + PURGING
    // ------------------------------------------------------------------------------------

    if ( !params.skip_scaffolding_with_hic ) {

        SCAFFOLDING_WITH_HIC(
            ch_hic_reads,
            ch_assemblies,
            params.hic_primary_alignments_only
        )

        ch_assemblies = SCAFFOLDING_WITH_HIC.out.scaffolded_assemblies

    }

    // ------------------------------------------------------------------------------------
    // PURGING SCAFFOLDING ASSEMBLY
    // ------------------------------------------------------------------------------------

    if ( !params.skip_scaffolded_assembly_purging ) {

        SCAFFOLDED_ASSEMBLY_PURGING(
            ch_long_reads,
            ch_assemblies
        )

        ch_assemblies = SCAFFOLDED_ASSEMBLY_PURGING.out.purged_assemblies

    }

    // --------------------------------------------------------
    // CLOSING GAPS IN FINAL ASSEMBLY
    // --------------------------------------------------------

    if ( !params.skip_gap_closing ) {
        CLOSE_GAPS (
            ch_long_reads,
            ch_assemblies
        )
        ch_assemblies = CLOSE_GAPS.out.gapclosed_assemblies

    }

    // ------------------------------------------------------------------------------------
    // QC
    // ------------------------------------------------------------------------------------

     if ( !params.skip_qc ) {

        ASSEMBLY_QC (
            ch_long_reads,
            ch_hic_reads,
            ch_assemblies
        )

     }


    // ------------------------------------------------------------------------------------
    // MULTIQC
    // ------------------------------------------------------------------------------------

    REPORTING (
        params.multiqc_config,
        params.multiqc_logo,
        params.multiqc_methods_description,
        params.outdir
    )

    emit:
    multiqc_report = REPORTING.out.multiqc_report.toList()


}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
