include { MAP_TO_REFERENCE_MINIMAP2      } from '../map_to_reference/minimap2/main'
include { MAP_TO_REFERENCE_WINNOWMAP     } from '../map_to_reference/winnowmap/main'

//include { CLAIR3_PHASE_WHATSHAP        } from '../../../modules/local/clair3/phase_whatshap'
//include { CLAIR3_PHASE_LONGPHASE       } from '../../../modules/local/clair3/phase_longphase'
include { WHATSHAP_HAPLOTAG            } from '../../../modules/local/whatshap/haplotag'
include { WHATSHAP_PHASE               } from '../../../modules/local/whatshap/phase'
include { WHATSHAP_SPLIT               } from '../../../modules/local/whatshap/split'
include { WHATSHAP_STATS               } from '../../../modules/local/whatshap/stats'
include { SAMTOOLS_FAIDX               } from '../../../modules/local/samtools/faidx'
include { SAMTOOLS_INDEX               } from '../../../modules/nf-core/samtools/index'

include { CLAIR3                       } from '../../../modules/local/clair3'
include { PEPPER_MARGIN_DEEPVARIANT    } from '../../../modules/local/pepper_margin_deepvariant'
include { SNIFFLES                     } from '../../../modules/local/sniffles/main'
include { TABIX_BGZIP                  } from '../../../modules/nf-core/tabix/bgzip'
include { TABIX_TABIX                  } from '../../../modules/nf-core/tabix/tabix'
include { LONGPHASE_PHASE              } from '../../../modules/local/longphase/phase'
include { LONGPHASE_HAPLOTAG           } from '../../../modules/local/longphase/haplotag'


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
        MAP_TO_REFERENCE_WINNOWMAP.out.bai.set { ch_bai }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_WINNOWMAP.out.versions )

    } else {

        MAP_TO_REFERENCE_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_MINIMAP2.out.bam_ref.set { ch_bam_ref }
        MAP_TO_REFERENCE_MINIMAP2.out.bai.set { ch_bai }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_MINIMAP2.out.versions )

    }

    ch_bam_ref
        .join ( ch_bai )
        .map { meta, bam, fasta, bai -> [ meta, bam, bai ] }
        .set { ch_alignment_and_index }

    // --------------------------------------------------------
    // INDEXING
    // --------------------------------------------------------

    SAMTOOLS_FAIDX ( ch_assemblies )
    SAMTOOLS_FAIDX.out.fai.set { ch_assemblies_index }

    // --------------------------------------------------------
    // CALLING VARIANTS
    // --------------------------------------------------------

    ch_alignment_and_index
        .join( ch_assemblies )
        .join( ch_assemblies_index )
        .set { variant_caller_input }

    if ( params.variant_caller == "clair3" ) {

        CLAIR3 (
            variant_caller_input,
            params.clair3_model
        )

        CLAIR3.out.vcf.set { ch_variants }
        CLAIR3.out.vcf_index.set { ch_variants_index }

    } else { // pepper margin deep variant_caller

        PEPPER_MARGIN_DEEPVARIANT ( variant_caller_input )

        PEPPER_MARGIN_DEEPVARIANT.out.vcf.set { ch_variants }
        PEPPER_MARGIN_DEEPVARIANT.out.tbi.set { ch_variants_index }

    }

    variant_caller_input
        .join( ch_variants )
        .join( ch_variants_index )
        .set { phaser_input }

    if ( params.phasing_tool == "whatshap" ) {

        WHATSHAP_PHASE ( variant_caller_input )

        TABIX_BGZIP ( WHATSHAP_PHASE.out.vcf )
        TABIX_TABIX ( TABIX_BGZIP.out.output )

        WHATSHAP_PHASE.out.vcf.set { ch_phased_variants }
        TABIX_TABIX.out.tbi.set { ch_phased_variants_index }

        ch_phased_variants
            .join( ch_phased_variants_index )
            .set { whatshap_stats_input }

        WHATSHAP_STATS ( whatshap_stats_input )

        variant_caller_input
            .join( ch_phased_variants )
            .join( ch_phased_variants_index )
            .set { whatshap_haplotag_input }

        WHATSHAP_HAPLOTAG ( whatshap_haplotag_input )

    } else {

        SNIFFLES ( ch_alignment_and_index )

        phaser_input
            .join ( SNIFFLES.out.vcf )
            .join ( SNIFFLES.out.tbi )
            .set { longphase_phase_input }

        LONGPHASE_PHASE( longphase_phase_input )

    }





    // --------------------------------------------------------
    // SPLIT READS
    // --------------------------------------------------------

    ch_reads
        .join( WHATSHAP_HAPLOTAG.out.haplotag_list )
        .set { whatshap_split_input }

    WHATSHAP_SPLIT ( whatshap_split_input )

    WHATSHAP_SPLIT.out.reads_h1.map { meta, reads -> [ meta + [ haplotig: 1 ], reads ] }
        .mix ( WHATSHAP_SPLIT.out.reads_h2.map { meta, reads -> [ meta + [ haplotig: 2 ], reads ] } )
        .set { haplotype_reads }

    emit:
    haplotype_reads
    stats = WHATSHAP_STATS.out.stats
    versions = ch_versions                     // channel: [ versions.yml ]
}

