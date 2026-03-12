include { ARIMA_MAPPING_PIPELINE_HIC    } from '../arima_mapping_pipeline_hic'
include { HIC_CONTACT_MAP               } from '../hic_contact_map'
include { GAP_CLOSING                   } from '../gap_closing'

include { SAMTOOLS_FAIDX                } from '../../../modules/local/samtools/faidx'
include { YAHS                          } from '../../../modules/local/yahs'
include { ASSEMBLY_STATS                } from '../../../modules/local/assembly_stats'


workflow SCAFFOLDING {

    take:
    ch_hic_reads
    ch_long_reads
    ch_assemblies
    skip_arima_hic_mapping_pipeline
    skip_hic_contact_maps
    skip_gap_closing
    hic_reads_mapping
    hic_primary_alignments_only

    main:

    // ------------------------------------------------------------------------------------
    // MAPPING OF HI-C READS TO ASSEMBLY
    // ------------------------------------------------------------------------------------

    if ( skip_arima_hic_mapping_pipeline ) {

        if ( hic_reads_mapping ) {
            ch_hic_bam = channel.fromPath( hic_reads_mapping, checkExists: true )
        } else {
            error("You must provide a BAM file consisting of Hi-C reads mapped to the current assembly if you set --skip_arima_hic_mapping_pipeline")
        }

    } else {

        ARIMA_MAPPING_PIPELINE_HIC (
            ch_hic_reads,
            ch_assemblies,
            hic_primary_alignments_only
        )

        ch_hic_bam  =  ARIMA_MAPPING_PIPELINE_HIC.out.alignment

    }

    // ------------------------------------------------------------------------------------
    // SCAFFOLDING
    // ------------------------------------------------------------------------------------

    SAMTOOLS_FAIDX ( ch_assemblies )
    ch_fai = SAMTOOLS_FAIDX.out.fai

    YAHS (
        ch_hic_bam.join( ch_assemblies ).join( ch_fai )
    )
    ch_scaffolded_assembies = YAHS.out.fasta

    // ------------------------------------------------------------------------------------
    // MAKING CONTACT MAP AFTER SCAFFOLDING
    // ------------------------------------------------------------------------------------

    if ( !skip_hic_contact_maps ) {
        def export_to_multiqc = false
        HIC_CONTACT_MAP (
            YAHS.out.alignments,
            YAHS.out.chrom_sizes,
            export_to_multiqc
        )
    }

    // --------------------------------------------------------
    // CLOSING GAPS IN SCAFFOLDED ASSEMBLY
    // --------------------------------------------------------

    if ( !skip_gap_closing ) {
        GAP_CLOSING(
            ch_long_reads,
            ch_scaffolded_assembies
        )
        ch_scaffolded_assembies = GAP_CLOSING.out.gapclosed_assemblies

    }

    // ------------------------------------------------------------------------------------
    // COMPUTING Nx / Lx FOR NEW SCAFFOLDED ASSEMBLY
    // ------------------------------------------------------------------------------------

    ASSEMBLY_STATS ( ch_scaffolded_assembies )


    emit:
    scaffolded_assemblies          = ch_scaffolded_assembies
}
