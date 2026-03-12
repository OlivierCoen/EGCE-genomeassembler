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
    ch_versions = channel.empty()

    //CONTIG_STATS ( ch_assemblies )

    // ------------------------------------------------------------------------------------
    // QUAST
    // ------------------------------------------------------------------------------------

    if ( !params.skip_quast ) {

        def bam_format = true
        if ( params.quast_mapper == 'winnowmap' ) {

            MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP ( ch_long_reads, ch_assemblies, bam_format )
            ch_bam_ref  = MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP.out.bam_ref
            ch_versions = ch_versions.mix ( MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP.out.versions )

        } else {

            MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2 ( ch_long_reads, ch_assemblies, bam_format )
            ch_bam_ref  = MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2.out.bam_ref
            ch_versions = ch_versions.mix ( MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2.out.versions )

        }

        quast_input = ch_bam_ref
                        .map { meta, bam, assembly -> [ meta, assembly, bam ] } // inverting

        QUAST( quast_input )

    }

   // ------------------------------------------------------------------------------------
    // BUSCO
    // ------------------------------------------------------------------------------------

    if ( !params.skip_busco ) {

        busco_input = ch_assemblies.groupTuple() // one run of BUSCO per meta

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

        merqury_input = MERYL_COUNT.out.meryl_db
                            .combine( ch_assemblies, by: 0 ) // cartesian product with meta as matching key

        MERQURY( merqury_input )

    }

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]

}
