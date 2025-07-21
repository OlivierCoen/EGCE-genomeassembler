include { MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2      } from '../map_long_reads_to_assembly/minimap2/main'
include { MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP     } from '../map_long_reads_to_assembly/winnowmap/main'

include { ARIMA_MAPPING_PIPELINE_HIC               } from '../arima_mapping_pipeline_hic'
include { HIC_CONTACT_MAP                          } from '../hic_contact_map'

include { BUSCO_BUSCO as BUSCO                     } from '../../../modules/local/busco/busco'
include { MERQURY                                  } from '../../../modules/local/merqury'
include { MERYL_COUNT                              } from '../../../modules/local/meryl/count'
include { QUAST                                    } from '../../../modules/local/quast'
//include { CONTIG_STATS                           } from '../../../modules/local/contig_stats'


workflow ASSEMBLY_QC {

    take:
    ch_long_reads
    ch_hic_reads
    ch_assemblies

    main:
    ch_versions = Channel.empty()

    //CONTIG_STATS ( ch_assemblies )

    // ------------------------------------------------------------------------------------
    // QUAST
    // ------------------------------------------------------------------------------------

    if ( !params.skip_quast ) {

        def bam_format = true
        if ( params.quast_mapper == 'winnowmap' ) {

            MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP ( ch_long_reads, ch_assemblies, bam_format )
            MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP.out.bam_ref.set { ch_bam_ref }
            ch_versions = ch_versions.mix ( MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP.out.versions )

        } else {

            MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2 ( ch_long_reads, ch_assemblies, bam_format )
            MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2.out.bam_ref.set { ch_bam_ref }
            ch_versions = ch_versions.mix ( MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2.out.versions )

        }

        ch_bam_ref
            .groupTuple() // [ meta, [bam1, bam2, bam3], [ref1, ref2, ref3]
            .map { meta, bam_list, ref_list -> [ meta, ref_list, bam_list ] } // inverting lists
            .set { quast_input }

        QUAST( quast_input )

    }

   // ------------------------------------------------------------------------------------
    // BUSCO
    // ------------------------------------------------------------------------------------

    if ( !params.skip_busco ) {

        ch_assemblies
            .groupTuple() // one run of BUSCO per meta
            .set { busco_input }

        def busco_config_file = []
        def clean_intermediates = false
        BUSCO(
            busco_input,
            'genome',
            params.busco_lineage,
            params.busco_db ? file(params.busco_db, checkIfExists: true) : [],
            busco_config_file,
            clean_intermediates
            )

    }

    // ------------------------------------------------------------------------------------
    // MERQURY
    // ------------------------------------------------------------------------------------

    if ( !params.skip_merqury ) {

        MERYL_COUNT(
            ch_long_reads,
            params.meryl_k_value
        )

        MERYL_COUNT.out.meryl_db
            .combine( ch_assemblies, by: 0 ) // cartesian product with meta as matching key
            .set { merqury_input }

        MERQURY( merqury_input )

    }

    // ------------------------------------------------------------------------------------
    // HI-C CONTACT MAP
    // ------------------------------------------------------------------------------------

    if ( !params.skip_hic_contact_maps ) {

        ARIMA_MAPPING_PIPELINE_HIC (
            ch_hic_reads,
            ch_assemblies
        )

        HIC_CONTACT_MAP (
            ARIMA_MAPPING_PIPELINE_HIC.out.alignment,
            ch_assemblies
        )
    }

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]

}
