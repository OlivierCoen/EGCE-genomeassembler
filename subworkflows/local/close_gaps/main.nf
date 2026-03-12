include { NTLINK_GAP_FILL                       } from '../../../modules/local/ntlink/gap_fill'

include { POLISH                                } from '../polish'

workflow CLOSE_GAPS {

    take:
    ch_long_reads
    ch_assemblies

    main:

    NTLINK_GAP_FILL (
        ch_assemblies.join ( ch_long_reads )
    )

    POLISH (
        ch_long_reads,
        NTLINK_GAP_FILL.out.fasta
    )


    emit:
    gapclosed_assemblies       = POLISH.out.assemblies
}
