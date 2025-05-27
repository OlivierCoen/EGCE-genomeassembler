include { ARIMA_MAPPING_PIPELINE_HIC    }  from '../arima_mapping_pipeline_hic/main'
include { SAMTOOLS_FAIDX                } from '../../../modules/nf-core/samtools/faidx/main'
include { YAHS                          } from '../../../modules/nf-core/yahs/main'


workflow SCAFFOLDING_WITH_HIC {

    take:
    ch_hic_read_pairs
    ch_reference_genome_fasta

    main:

    ch_versions = Channel.empty()

    ARIMA_MAPPING_PIPELINE_HIC ( ch_hic_read_pairs, ch_reference_genome_fasta )

    def get_sizes = false
    SAMTOOLS_FAIDX (
        ch_reference_genome_fasta,
        get_sizes
    )

    YAHS (
        ARIMA_MAPPING_PIPELINE_HIC.out.alignment,
        ch_reference_genome_fasta.map { meta, fasta -> [ fasta ]},
        SAMTOOLS_FAIDX.out.fai.map { meta, index -> [ index ]}
    )

    YAHS.out.scaffolds_fasta.view()

    ch_versions = ch_versions
                    .mix ( ARIMA_MAPPING_PIPELINE_HIC.out.versions )
                    .mix ( SAMTOOLS_FAIDX.out.versions )
                    .mix ( YAHS.out.versions )

    emit:
    scaffolds_fasta = YAHS.out.scaffolds_fasta
    versions = ch_versions                     // channel: [ versions.yml ]
}

