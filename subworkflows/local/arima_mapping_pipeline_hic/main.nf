include { BWAMEM2_INDEX                 } from '../../../modules/nf-core/bwamem2/index'
include { BWAMEM2_MEM                   } from '../../../modules/nf-core/bwamem2/mem'
include { ARIMA_FILTER_FIVE_END         } from '../../../modules/local/arima/filter_five_end'
include { ARIMA_TWO_BAM_COMBINER        } from '../../../modules/local/arima/two_bam_combiner'
include { ARIMA_GET_STATS               } from '../../../modules/local/arima/get_stats'
include { PICARD_ADDORREPLACEREADGROUPS } from '../../../modules/nf-core/picard/addorreplacereadgroups'
include { PICARD_MARKDUPLICATES         } from '../../../modules/nf-core/picard/markduplicates'
include { SAMTOOLS_INDEX                } from '../../../modules/nf-core/samtools/index'


workflow ARIMA_MAPPING_PIPELINE_HIC {

    take:
    ch_hic_read_pairs
    ch_reference_genome_fasta

    main:

    ch_versions = Channel.empty()

    ch_hic_read_pairs
        .multiMap { meta, reads ->
            r1: [ meta, reads[0] ]
            r2: [ meta, reads[1] ]
        }
        .set { ch_hic_reads }

    ch_hic_reads.r1
        .mix( ch_hic_reads.r2 )
        .set { ch_hic_reads }

    BWAMEM2_INDEX ( ch_reference_genome_fasta )
    ch_reference_genome_index = BWAMEM2_INDEX.out.index.collect()

    def sort_bam = false
    BWAMEM2_MEM (
        ch_hic_reads,
        ch_reference_genome_index,
        ch_reference_genome_fasta.collect(),
        sort_bam
    )

    ARIMA_FILTER_FIVE_END ( BWAMEM2_MEM.out.bam )

    ARIMA_FILTER_FIVE_END.out.bam
        .groupTuple()
        .map { meta, files -> [ meta, *files ] }
        .set { ch_filtered_bam }

    def mapq_filter = 10
    ARIMA_TWO_BAM_COMBINER (
        ch_filtered_bam,
        ch_reference_genome_index,
        mapq_filter
    )

    PICARD_ADDORREPLACEREADGROUPS ( ARIMA_TWO_BAM_COMBINER.out.bam, [[:],[]], [[:],[]] )

    PICARD_MARKDUPLICATES ( PICARD_ADDORREPLACEREADGROUPS.out.bam, [[:],[]], [[:],[]] )

    SAMTOOLS_INDEX ( PICARD_MARKDUPLICATES.out.bam )

    ARIMA_GET_STATS (
        PICARD_MARKDUPLICATES.out.bam,
        SAMTOOLS_INDEX.out.bai
    )

    ch_versions = ch_versions
                    .mix ( BWAMEM2_INDEX.out.versions )
                    .mix ( BWAMEM2_INDEX.out.versions )
                    .mix ( PICARD_ADDORREPLACEREADGROUPS.out.versions )
                    .mix ( PICARD_MARKDUPLICATES.out.versions )
                    .mix ( SAMTOOLS_INDEX.out.versions )


    emit:
    alignment = PICARD_MARKDUPLICATES.out.bam
    versions = ch_versions                     // channel: [ versions.yml ]
}

