include { MINIMAP2_ALIGN as ALIGN      } from '../../../modules/local/minimap2/align/main'
include { RACON                        } from '../../../modules/local/racon/main'

workflow RACON_POLISH {

    take:
    ch_reads
    ch_assemblies
    round

    main:

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

    RACON ( racon_input, round )


    emit:
    assemblies = RACON.out.improved_assembly
}

