include { HIC_SHORT_READS_PREPARATION   } from '../hic_short_reads_preparation'
include { ARIMA_MAPPING_PIPELINE_HIC    } from '../arima_mapping_pipeline_hic'
include { SAMTOOLS_FAIDX                } from '../../../modules/local/samtools/faidx'
include { YAHS                          } from '../../../modules/nf-core/yahs'


workflow SCAFFOLDING_WITH_HIC {

    take:
    ch_hic_read_pairs
    ch_reference_genome_fasta

    main:

    ch_versions = Channel.empty()

    HIC_SHORT_READS_PREPARATION ( ch_hic_read_pairs )

    ARIMA_MAPPING_PIPELINE_HIC (
        HIC_SHORT_READS_PREPARATION.out.prepared_hic_short_reads,
        ch_reference_genome_fasta
    )

    SAMTOOLS_FAIDX ( ch_reference_genome_fasta )

    YAHS (
        ARIMA_MAPPING_PIPELINE_HIC.out.alignment,
        ch_reference_genome_fasta.map { meta, fasta -> [ fasta ]},
        SAMTOOLS_FAIDX.out.fai.map { meta, index -> [ index ]}
    )

    YAHS.out.scaffolds_fasta.view()

    ch_versions = ch_versions
                    .mix ( HIC_SHORT_READS_PREPARATION.out.versions )
                    .mix ( ARIMA_MAPPING_PIPELINE_HIC.out.versions )
                    .mix ( YAHS.out.versions )

    emit:
    scaffolds_fasta = YAHS.out.scaffolds_fasta
    fastqc_raw_zip                  = HIC_SHORT_READS_PREPARATION.out.fastqc_raw_zip
    fastqc_prepared_reads_zip       = HIC_SHORT_READS_PREPARATION.out.fastqc_prepared_reads_zip
    fastp_json                      = HIC_SHORT_READS_PREPARATION.out.fastp_json
    versions = ch_versions                     // channel: [ versions.yml ]
}

