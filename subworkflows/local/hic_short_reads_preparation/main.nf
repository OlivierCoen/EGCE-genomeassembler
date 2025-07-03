include { FASTP                                              } from '../../../modules/nf-core/fastp'
include { FASTQC as HIC_SHORT_READS_FASTQC_RAW               } from '../../../modules/local/fastqc'
include { FASTQC as HIC_SHORT_READS_FASTQC_PREPARED_READS    } from '../../../modules/local/fastqc'


workflow HIC_SHORT_READS_PREPARATION {

    take:
    ch_hic_short_reads

    main:

    ch_versions = Channel.empty()

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    HIC_SHORT_READS_FASTQC_RAW (
        ch_hic_short_reads.filter { meta, assembly -> meta.run_fastqc_raw_hic }
    )

    // ---------------------------------------------------------------------
    // Trimming / Filtering
    // ---------------------------------------------------------------------

    ch_hic_short_reads
        .branch { meta, reads ->
            trim_me: meta.trim_filter_reads_hic
            leave_me_alone: !meta.trim_filter_reads_hic
        }
        .set { ch_branched_hic_short_reads }

    FASTP (
        ch_branched_hic_short_reads.trim_me,
        [], false, false, true
    )

    ch_branched_hic_short_reads.leave_me_alone
        .mix ( FASTP.out.reads )
        .set { ch_prepared_hic_short_reads }

    ch_versions = ch_versions.mix ( FASTP.out.versions )

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    HIC_SHORT_READS_FASTQC_PREPARED_READS (
        ch_prepared_hic_short_reads.filter { meta, assembly -> meta.run_fastqc_prepared_hic }
    )

    emit:
    prepared_hic_short_reads        = ch_prepared_hic_short_reads
    fastp_json                      = FASTP.out.json
    versions                        = ch_versions
}
