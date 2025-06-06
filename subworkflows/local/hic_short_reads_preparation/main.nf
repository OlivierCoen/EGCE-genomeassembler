include { FASTP                              } from '../../../modules/nf-core/fastp'
include { FASTQC as FASTQC_RAW               } from '../../../modules/local/fastqc'
include { FASTQC as FASTQC_PREPARED_READS    } from '../../../modules/local/fastqc'


workflow HIC_SHORT_READS_PREPARATION {

    take:
    ch_hic_short_reads

    main:

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    FASTQC_RAW ( ch_hic_short_reads.filter { meta, assembly -> meta.run_fastqc_raw_hic } )

    // ---------------------------------------------------------------------
    // Trimming / Filtering
    // ---------------------------------------------------------------------

    ch_hic_short_reads
        .branch { meta, reads ->
            trim_me: meta.trim_filter_reads_hic
            leave_me_alone: !meta.trim_filter_reads_hic
        }
        .set { ch_hic_short_reads }

    FASTP (
        ch_hic_short_reads.trim_me,
        [], false, false, true
    )

    ch_fastq_reads.leave_me_alone
        .mix ( FASTP.out.reads )
        .set { ch_hic_short_reads }

    ch_versions = ch_versions.mix ( FASTP.out.versions )

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    FASTQC_PREPARED_READS ( ch_hic_short_reads.filter { meta, assembly -> meta.run_fastqc_prepared_hic } )

    emit:
    prepared_hic_short_reads        = ch_hic_short_reads
    fastqc_raw_zip                  = FASTQC_RAW.out.zip
    fastqc_prepared_reads_zip       = FASTQC_PREPARED_READS.out.zip
    fastp_json                      = FASTP.out.json
    versions                        = ch_versions
}
