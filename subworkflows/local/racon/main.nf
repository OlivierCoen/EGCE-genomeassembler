include { MAP_TO_REFERENCE_MINIMAP2      } from '../map_to_reference/minimap2'
include { MAP_TO_REFERENCE_WINNOWMAP     } from '../map_to_reference/winnowmap'
include { RACON                         } from '../../../modules/local/racon'

workflow RACON_WORKFLOW {

    take:
    ch_reads
    ch_assemblies
    round

    main:

    ch_versions = Channel.empty()

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    def bam_format = false
    if ( params.mapper == 'winnowmap' ) {
        MAP_TO_REFERENCE_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_WINNOWMAP.out.paf_ref.set { ch_paf_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_WINNOWMAP.out.versions )
    } else {
        MAP_TO_REFERENCE_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_MINIMAP2.out.paf_ref.set { ch_paf_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_MINIMAP2.out.versions )
    }

    // ---------------------------------------------------
    // Polishing
    // ---------------------------------------------------

    ch_reads
        .join( ch_paf_ref )
        .map { meta, reads, paf, assembly -> [ meta, reads, assembly, paf ] } // reorder
        .set { racon_input }

    RACON ( racon_input, round )


    emit:
    assemblies = RACON.out.improved_assembly
    versions = ch_versions                     // channel: [ versions.yml ]
}

