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
include { SCAFFOLDING                                                        } from '../subworkflows/local/scaffolding'
include { PURGE_DUPLICATES as SCAFFOLDED_ASSEMBLY_PURGING                    } from '../subworkflows/local/purge_duplicates'
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
                            meta, reads, hic_fastq_1, hic_fastq_2, hic_bam, assembly ->
                                reads: reads ? [ meta, reads ] : null
                                hic_reads: hic_bam ? null : hic_fastq_1 && hic_fastq_2 ? [ meta, [ hic_fastq_1, hic_fastq_2 ] ] : null
                                hic_bam: hic_bam ? [ meta, hic_bam ] : null
                                assembly: assembly ? [ meta, assembly ] : null
                        }

    ch_long_reads = ch_input.reads
    ch_assemblies = ch_input.assembly
    ch_hic_reads = ch_input.hic_reads
    ch_hic_bam = ch_input.hic_bam

    // ch_all_draft_assembly_versions_and_alternatives = ch_assemblies

    // ------------------------------------------------------------------------------------
    // READ PREPARATION
    // ------------------------------------------------------------------------------------


    if ( !params.skip_long_read_preparation ) {

        LONG_READ_PREPARATION (
            ch_long_reads,
            params.preprocessing_tool,
            params.skip_long_reads_fastqc_raw,
            params.skip_long_reads_preprocessing,
            params.skip_long_reads_fastqc_preprocessed,
            params.skip_long_read_nanoq
        )
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
    // SCAFFOLDING WITH HIC + PURGING + GAP CLOSING
    // ------------------------------------------------------------------------------------

    if ( !params.skip_scaffolding ) {

        SCAFFOLDING(
            ch_hic_reads,
            ch_hic_bam,
            ch_long_reads,
            ch_assemblies,
            params.skip_arima_hic_mapping_pipeline,
            params.skip_hic_contact_maps,
            params.skip_gap_closing,
            params.hic_primary_alignments_only
        )

        ch_assemblies = SCAFFOLDING.out.scaffolded_assemblies

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
