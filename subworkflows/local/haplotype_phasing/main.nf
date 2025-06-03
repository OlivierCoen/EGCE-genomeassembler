include { MAP_TO_REFERENCE_MINIMAP2      } from '../map_to_reference/minimap2/main'
include { MAP_TO_REFERENCE_WINNOWMAP     } from '../map_to_reference/winnowmap/main'

include { CLAIR3                       } from '../../../modules/local/clair3'
include { WHATSAPP_HAPLOTAG            } from '../../../modules/local/whatshap/haplotag'
include { WHATSAPP_SPLIT               } from '../../../modules/local/whatshap/split'
include { WHATSAPP_STATS               } from '../../../modules/local/whatshap/stats'
include { SAMTOOLS_FAIDX               } from '../../../modules/local/samtools/faidx'
include { SAMTOOLS_INDEX               } from '../../../modules/nf-core/samtools/index'


workflow HAPLOTYPE_PHASING {

    take:
    ch_reads
    ch_assemblies

    main:
    ch_versions = Channel.empty()

    // --------------------------------------------------------
    // ALIGNING READS TO REFERENCE
    // --------------------------------------------------------

     def bam_format = true
     if ( params.mapper == 'winnowmap' ) {

        MAP_TO_REFERENCE_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_WINNOWMAP.out.bam_ref.set { ch_bam_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_WINNOWMAP.out.versions )

    } else {

        MAP_TO_REFERENCE_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_MINIMAP2.out.bam_ref.set { ch_bam_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_MINIMAP2.out.versions )

    }

    ch_bam_ref
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

    SAMTOOLS_INDEX.out.bai.set { ch_alignement_index }

    ch_alignment
        .join( ch_alignement_index )
        .join( ch_assemblies )
        .join( SAMTOOLS_FAIDX.out.fai )
        .set { clair_input }

    CLAIR3 ( clair_input )
    CLAIR3.out.vcf.set { ch_variants }
    CLAIR3.out.vcf_index.set { ch_variants_index }
    // --------------------------------------------------------
    // PHASING
    // --------------------------------------------------------

    WHATSAPP_STATS ( ch_variants )

    ch_alignment
        .join( ch_alignement_index )
        .join( ch_variants )
        .join( ch_variants_index )
        .join( ch_assemblies )
        .join( SAMTOOLS_FAIDX.out.fai )
        .set { whatshap_haplotag_input }

    WHATSAPP_HAPLOTAG ( whatshap_haplotag_input )

    // --------------------------------------------------------
    // SPLIT READS
    // --------------------------------------------------------

    ch_reads
        .join( WHATSAPP_HAPLOTAG.out.haplotag_list )
        .set { whatshap_split_input }

    WHATSAPP_SPLIT ( whatshap_split_input )

    WHATSAPP_SPLIT.out.reads_h1.map { meta, reads -> [ meta + [ haplotig: 1 ], reads ] }
        .mix ( WHATSAPP_SPLIT.out.reads_h2.map { meta, reads -> [ meta + [ haplotig: 2 ], reads ] } )
        .set { haplotype_reads }

    emit:
    haplotype_reads
    versions = ch_versions                     // channel: [ versions.yml ]
}

