include { JUICER_PRE                             } from '../../../modules/local/juicer/pre'
include { JUICERTOOLS_PRE                        } from '../../../modules/local/juicer_tools/pre'

workflow JUICER {

    take:
    ch_bin
    ch_agp
    ch_fai

    main:

    ch_juicer_pre_input = ch_bin
                            .join( ch_agp )
                            .join( ch_fai )

    JUICER_PRE(
        ch_bin.join( ch_agp ).join( ch_fai )
    )
    ch_alignments = JUICER_PRE.out.alignments
    ch_chrom_sizes = JUICER_PRE.out.chrom_sizes

    JUICERTOOLS_PRE(
        ch_alignments.join( ch_chrom_sizes )
    )


    emit:
    alignments_chrom_sizes  = ch_alignments.join(ch_chrom_sizes)
}
