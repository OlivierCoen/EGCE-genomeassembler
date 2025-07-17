include { BWAMEM2_INDEX                          } from '../../../modules/nf-core/bwamem2/index'
include { BWAMEM2_MEM                            } from '../../../modules/local/bwamem2/mem'
include { PRETEXTMAP                             } from '../../../modules/local/pretextmap'
include { PRETEXTSNAPSHOT                        } from '../../../modules/local/pretextsnapshot'


workflow HIC_CONTACT_MAP {

    take:
    ch_hic_reads
    ch_assemblies

    main:

    BWAMEM2_INDEX ( ch_assemblies )

    ch_assemblies
        .join( BWAMEM2_INDEX.out.index )
        .set { ch_fasta_fai }

    ch_hic_reads
        .combine( ch_fasta_fai, by: 0)
        .set { bwamem2_input }

    def sort_bam = true
    BWAMEM2_MEM (
        bwamem2_input,
        sort_bam
    )

    BWAMEM2_MEM.out.bam
        .join( ch_assemblies )
        .set { pretextmap_input }

    PRETEXTMAP ( pretextmap_input )

    PRETEXTSNAPSHOT ( PRETEXTMAP.out.pretext )

}

