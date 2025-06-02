include { QUAST } from '../../../../modules/local/quast'

workflow QC_QUAST {
    take:
    ch_bam_ref // channel: [ val(meta), path(bam), path(ref), path(bai) ]

    main:

    Channel.empty().set { quast_results }
    Channel.empty().set { quast_tsv }

    ch_bam_ref
        .groupTuple() // [ meta, [bam1, bam2, bam3], [ref1, ref2, ref3]
        .map { meta, bam_list, ref_list -> [ meta, ref_list, bam_list ] } // inverting lists
        .set { quast_input }

    QUAST( quast_input )
    QUAST.out.results.set { quast_results }
    QUAST.out.tsv.set { quast_tsv }

    emit:
    quast_tsv

}
