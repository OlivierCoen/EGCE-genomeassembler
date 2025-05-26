include { BWAMEM2_INDEX                 } from '../../../modules/nf-core/bwamem2/index/main'
include { BWAMEM2_MEM                   } from '../../../modules/nf-core/bwamem2/mem/main'
include { ARIMA_FILTER_FIVE_END         } from '../../../modules/local/arima/filter_five_end/main'
include { ARIMA_TWO_BAM_COMBINER        } from '../../../modules/local/arima/two_bam_combiner/main'
include { ARIMA_GET_STATS               } from '../../../modules/local/arima/get_stats/main'
include { PICARD_ADDORREPLACEREADGROUPS } from '../../../modules/nf-core/picard/addorreplacereadgroups/main'
include { PICARD_MARKDUPLICATES         } from '../../../modules/nf-core/picard/markduplicates/main'
include { SAMTOOLS_INDEX                } from '../../../modules/nf-core/samtools/index/main'


workflow ARIMA_MAPPING_PIPELINE_HIC {

    take:
    ch_hic_read_pairs
    ch_reference_genome_fasta

    main:

    ch_versions = Channel.empty()

    ch_hic_read_pairs
        .multiMap { meta, reads ->
            def meta1 = [ id: "${meta.id}_R1", sample: meta.id]
            def meta2 = [ id: "${meta.id}_R2", sample: meta.id ]
            r1: [ meta1, reads[0] ]
            r2: [ meta2, reads[1] ]
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

    ARIMA_FILTER_FIVE_END.out.bamPICARD_MARKDUPLICATES.out.bam
        .map { meta, file -> [ [ id: meta.sample ], file ] }
        .groupTuple()
        .map { meta, files -> [ meta, *files ] }
        .set { ch_filtered_bam }

    def mapq_filter = 10
    ARIMA_TWO_BAM_COMBINER (
        ch_filtered_bam,
        ch_reference_genome_index,
        mapq_filter
    )

    PICARD_ADDORREPLACEREADGROUPS ( ARIMA_TWO_BAM_COMBINER.out.bam )

    PICARD_MARKDUPLICATES ( PICARD_ADDORREPLACEREADGROUPS.out.bam )

    SAMTOOLS_INDEX ( PICARD_MARKDUPLICATES.out.bam )

    ARIMA_GET_STATS (
        PICARD_MARKDUPLICATES.out.bam,
        SAMTOOLS_INDEX.out.bai
    )

    emit:
    alignment = PICARD_MARKDUPLICATES.out.bam

    versions = ch_versions                     // channel: [ versions.yml ]
}

