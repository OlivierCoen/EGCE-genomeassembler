include { BWAMEM2_INDEX                 } from '../../../modules/nf-core/bwamem2/index'
include { BWAMEM2_MEM                   } from '../../../modules/local/bwamem2/mem'
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
    hic_primary_alignments_only

    main:

    // ------------------------------------------------------------------------------------
    // SEPARATING HIC READS 1 AND 2
    // ------------------------------------------------------------------------------------

    ch_hic_reads_1 = ch_hic_read_pairs.map{ meta, reads -> [ meta, reads[0] ]}
    ch_hic_reads_2 = ch_hic_read_pairs.map{ meta, reads -> [ meta, reads[1] ]}

    ch_hic_reads = ch_hic_reads_1.mix( ch_hic_reads_2 )

    // ------------------------------------------------------------------------------------
    // MAPPING EACH READ FILE TO GENOME
    // ------------------------------------------------------------------------------------

    BWAMEM2_INDEX ( ch_reference_genome_fasta )
    ch_reference_genome_index = BWAMEM2_INDEX.out.index

    ch_fasta_fai = ch_reference_genome_fasta
                    .join( ch_reference_genome_index )

    bwamem2_input = ch_hic_reads
                      .combine( ch_fasta_fai, by: 0)

    BWAMEM2_MEM( bwamem2_input )

    // ------------------------------------------------------------------------------------
    // ARIMA SCRIPT PROCESSING
    // ------------------------------------------------------------------------------------

    ARIMA_FILTER_FIVE_END ( BWAMEM2_MEM.out.bam )

    arima_combiner_input = ARIMA_FILTER_FIVE_END.out.bam
                            .groupTuple()
                            .map {
                                meta, files ->
                                    def (read_1, read_2) = files
                                    [ meta, read_1, read_2 ]
                            }
                            .join( ch_reference_genome_index )

    def mapq_filter = 10
    ARIMA_TWO_BAM_COMBINER (
        arima_combiner_input,
        mapq_filter,
        hic_primary_alignments_only
    )

    // ------------------------------------------------------------------------------------
    // PICARD POST-PROCESSING
    // ------------------------------------------------------------------------------------

    PICARD_ADDORREPLACEREADGROUPS ( ARIMA_TWO_BAM_COMBINER.out.bam, [[:],[]], [[:],[]] )

    PICARD_MARKDUPLICATES ( PICARD_ADDORREPLACEREADGROUPS.out.bam, [[:],[]], [[:],[]] )

    // ------------------------------------------------------------------------------------
    // GETTING MAPPING STATS
    // ------------------------------------------------------------------------------------

    SAMTOOLS_INDEX ( PICARD_MARKDUPLICATES.out.bam )

    ARIMA_GET_STATS (
        PICARD_MARKDUPLICATES.out.bam,
        SAMTOOLS_INDEX.out.bai
    )


    emit:
    alignment = PICARD_MARKDUPLICATES.out.bam
}
