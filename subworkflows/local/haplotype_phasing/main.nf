include { MINIMAP2_ALIGN as ALIGN      } from '../../../modules/local/minimap2/align/main'
include { CLAIR3                       } from '../../../modules/local/clair3/main'
include { WHATSAPP_HAPLOTAG            } from '../../../modules/local/whatshap/haplotag/main'
include { WHATSAPP_SPLIT               } from '../../../modules/local/whatshap/split/main'
include { WHATSAPP_STATS               } from '../../../modules/local/whatshap/stats/main'
include { SAMTOOLS_FAIDX               } from '../../../modules/local/samtools/faidx/main'
include { SAMTOOLS_INDEX               } from '../../../modules/nf-core/samtools/index/main'


workflow HAPLOTYPE_PHASING {

    take:
    ch_reads
    ch_assemblies

    main:
    ch_versions = Channel.empty()

    // --------------------------------------------------------
    // ALIGNING READS TO REFERENCE
    // --------------------------------------------------------

    ch_reads
        .join( ch_assemblies )
        .set { align_input }

    def bam_format = true
    ALIGN ( align_input, bam_format )

    // [ meta, bam, reference ]
    ALIGN.out.bam
        .map { meta, bam, fasta -> [ meta, bam ] }
        .set { ch_alignment }

    // --------------------------------------------------------
    // INDEXING
    // --------------------------------------------------------

    SAMTOOLS_INDEX ( ch_alignment )

    SAMTOOLS_FAIDX ( ch_assemblies )

    // --------------------------------------------------------
    // CALLING VARIANTS
    // --------------------------------------------------------

    ch_alignment
        .join( SAMTOOLS_INDEX.out.bai )
        .join( ch_assemblies )
        .join( SAMTOOLS_FAIDX.out.fai )
        .set { clair_input }

    CLAIR3 ( clair_input )
    CLAIR3.out.vcf.set { ch_variants }
    CLAIR3.out.vcf_index.set { ch_variants_index }
    // --------------------------------------------------------
    // PHASING
    // --------------------------------------------------------

    ch_alignment
        .join( ch_variants )
        .join( ch_variants_index )
        .join( ch_assemblies )
        .join( SAMTOOLS_FAIDX.out.fai )
        .set { whatshap_haplotag_input }

    WHATSAPP_STATS ( ch_variants )

    WHATSAPP_HAPLOTAG ( whatshap_haplotag_input )

    // --------------------------------------------------------
    // SPLIT READS
    // --------------------------------------------------------

    ch_reads
        .join( WHATSAPP_HAPLOTAG.out.haplotag_list )
        .set { whatshap_split_input }

    WHATSAPP_SPLIT ( whatshap_split_input )


    emit:
    reads_h1 = WHATSAPP_SPLIT.out.reads_h1
    reads_h2 = WHATSAPP_SPLIT.out.reads_h2
    versions = ch_versions                     // channel: [ versions.yml ]
}

