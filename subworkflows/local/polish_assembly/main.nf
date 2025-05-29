include { MEDAKA                       } from '../../../modules/local/medaka/main'
include { RACON                        } from '../../../modules/nf-core/racon/main'
include { MINIMAP2_ALIGN as ALIGN      } from '../../../modules/local/minimap2/align/main'

workflow POLISH_ASSEMBLY {

    take:
    ch_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    ch_reads
        .combine( ch_assemblies, by: 0 )  // cartesian product with meta as matching key
        .set { align_input }

    def bam_format = false
    ALIGN ( align_input, bam_format )

    ch_reads
        .join( ALIGN.out.paf )
        .map { meta, reads, paf, assembly -> [ meta, reads, assembly, paf ] } // reorder
        .set { racon_input }

    RACON ( racon_input )

    ch_reads
        .join( RACON.out.improved_assembly )
        .set { ch_medaka_input }

    MEDAKA ( ch_medaka_input )


    emit:
    assemblies = MEDAKA.out.assembly
    versions = ch_versions                     // channel: [ versions.yml ]
}

