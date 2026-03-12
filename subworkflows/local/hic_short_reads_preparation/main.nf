include { FASTP                                              } from '../../../modules/nf-core/fastp'
include { FASTQC as HIC_SHORT_READS_FASTQC_RAW               } from '../../../modules/local/fastqc'
include { FASTQC as HIC_SHORT_READS_FASTQC_PREPARED_READS    } from '../../../modules/local/fastqc'


workflow HIC_SHORT_READS_PREPARATION {

    take:
    ch_hic_short_reads

    main:

    ch_fastp_json = channel.empty()

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    if ( !params.skip_short_reads_fastqc_raw ) {
        HIC_SHORT_READS_FASTQC_RAW (
            ch_hic_short_reads
        )
    }

    // ---------------------------------------------------------------------
    // Trimming / Filtering
    // ---------------------------------------------------------------------

    if ( !params.skip_short_reads_cleaning ) {

        FASTP (
            ch_hic_short_reads.map{ meta, files -> [ meta, files, [] ] },
            false, false, false
        )
        ch_fastp_json      = FASTP.out.json
        ch_hic_short_reads = FASTP.out.reads
    }

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    if ( !params.skip_short_reads_fastqc_prepared ) {
        HIC_SHORT_READS_FASTQC_PREPARED_READS (
            ch_hic_short_reads
        )
    }

    emit:
    prepared_hic_short_reads        = ch_hic_short_reads
    fastp_json                      = ch_fastp_json
}
