//
// Run SAMtools stats, flagstat and idxstats
//

include { SAMTOOLS_STATS    } from '../../../modules/local/samtools/stats'
include { SAMTOOLS_IDXSTATS } from '../../../modules/nf-core/samtools/idxstats'
include { SAMTOOLS_FLAGSTAT } from '../../../modules/nf-core/samtools/flagstat'

workflow BAM_STATS_SAMTOOLS {
    take:
    ch_bam_ref_bai // channel: [ val(meta), path(bam), path(ref), path(bai) ]

    main:
    ch_versions = Channel.empty()

    ch_bam_ref_bai
        .map { meta, bam, ref, bai -> [ meta, bam, bai, ref ]} // inverting order
        .set { ch_bam_bai_ref }

    SAMTOOLS_STATS ( ch_bam_bai_ref )

    ch_bam_ref_bai
        .map { meta, bam, ref, bai -> [meta, bam, bai] } // removes ref
        .set { ch_bam_bai }

    SAMTOOLS_FLAGSTAT ( ch_bam_bai )

    SAMTOOLS_IDXSTATS ( ch_bam_bai )

    ch_versions = ch_versions
                    .mix(SAMTOOLS_FLAGSTAT.out.versions)
                    .mix(SAMTOOLS_IDXSTATS.out.versions)

    emit:
    stats    = SAMTOOLS_STATS.out.stats       // channel: [ val(meta), path(stats) ]
    flagstat = SAMTOOLS_FLAGSTAT.out.flagstat // channel: [ val(meta), path(flagstat) ]
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats // channel: [ val(meta), path(idxstats) ]

    versions = ch_versions                    // channel: [ path(versions.yml) ]
}
