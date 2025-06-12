include { MAP_TO_REFERENCE_MINIMAP2      } from '../map_to_reference/minimap2/main'
include { MAP_TO_REFERENCE_WINNOWMAP     } from '../map_to_reference/winnowmap/main'

include { BUSCO_BUSCO as BUSCO           } from '../../../modules/local/busco/busco'
include { MERQURY                        } from '../../../modules/local/merqury'
include { MERYL_COUNT                    } from '../../../modules/local/meryl/count'
include { QUAST                          } from '../../../modules/local/quast'
include { CONTIG_STATS                   } from '../../../modules/local/contig_stats'


workflow ASSEMBLY_QC {

    take:
    ch_reads
    ch_assemblies

    main:
    ch_versions = Channel.empty()

    CONTIG_STATS ( ch_assemblies )

    if ( !params.skip_quast ) {

        def bam_format = true
        if ( params.mapper == 'winnowmap' ) {

            MAP_TO_REFERENCE_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
            MAP_TO_REFERENCE_WINNOWMAP.out.bam_ref.set { ch_bam_ref }
            ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_WINNOWMAP.out.versions )

        } else {

            MAP_TO_REFERENCE_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
            MAP_TO_REFERENCE_MINIMAP2.out.bam_ref.set { ch_bam_ref }
            ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_MINIMAP2.out.versions )

        }

        ch_bam_ref
            .groupTuple() // [ meta, [bam1, bam2, bam3], [ref1, ref2, ref3]
            .map { meta, bam_list, ref_list -> [ meta, ref_list, bam_list ] } // inverting lists
            .set { quast_input }

        QUAST( quast_input )

    }

    /*
    QC on initial assembly
    */
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

    if ( !params.skip_merqury ) {

        MERYL_COUNT(
            ch_reads,
            params.meryl_k_value
        )

        MERYL_COUNT.out.meryl_db
            .combine( ch_assemblies, by: 0 ) // cartesian product with meta as matching key
            .set { merqury_input }
        MERYL_COUNT.out.meryl_db.view { v -> "meryl_db: $v" }
        ch_assemblies.view { v -> "assembly: $v" }
        merqury_input.view { v -> "merqury_input: $v" }
        MERQURY( merqury_input )

    }

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]

}
