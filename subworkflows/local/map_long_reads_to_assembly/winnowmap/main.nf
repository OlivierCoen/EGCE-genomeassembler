include { WINNOWMAP                                  } from '../../../../modules/local/winnowmap'
include { MERYL_COUNT                                } from '../../../../modules/local/meryl/count'
include { MERYL_PRINT                                } from '../../../../modules/local/meryl/print'


workflow MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP {

    take:
    ch_reads
    ch_assembly_fasta
    bam_format

    main:

    def winnowmap_meryl_k_value = 15
    MERYL_COUNT(
        ch_assembly_fasta,
        winnowmap_meryl_k_value
    )

    MERYL_PRINT( MERYL_COUNT.out.meryl_db )

    // Grouping by meta and giving to Winnowmap
    ch_winnowmap_input = MERYL_PRINT.out.repetitive_kmers
                            .join( ch_assembly_fasta )
                            .combine( ch_reads, by: 0 ) // cartesian product with meta as matching key

    WINNOWMAP (
        ch_winnowmap_input,
        bam_format
    )


    emit:
    paf_ref = WINNOWMAP.out.paf_ref
    bam_ref = WINNOWMAP.out.bam_ref
    bai     = WINNOWMAP.out.index
}
