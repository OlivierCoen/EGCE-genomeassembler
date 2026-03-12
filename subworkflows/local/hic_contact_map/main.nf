include { JUICERTOOLS_PRE                        } from '../../../modules/local/juicer_tools/pre'
include { PRETEXTMAP                             } from '../../../modules/local/pretext/pretextmap'
include { PRETEXTSNAPSHOT                        } from '../../../modules/local/pretext/pretextsnapshot'

include { JUICER                                 } from '../juicer'


workflow HIC_CONTACT_MAP {

    take:
    ch_alignments
    ch_chrom_sizes
    export_to_multiqc

    main:

    ch_alignments_chrom_sizes = ch_alignments.join( ch_chrom_sizes )

    JUICERTOOLS_PRE( ch_alignments_chrom_sizes )

    PRETEXTMAP ( ch_alignments_chrom_sizes )

    PRETEXTSNAPSHOT (
        PRETEXTMAP.out.pretext,
        export_to_multiqc
    )

}
