include { PURGEDUPS_PURGEDUPS          } from '../../../modules/nf-core/purgedups/purgedups/main'
include { PURGEDUPS_CALCUTS            } from '../../../modules/nf-core/purgedups/calcuts/main'
include { PURGEDUPS_PBCSTAT            } from '../../../modules/nf-core/purgedups/pbcstat/main'
include { PURGEDUPS_GETSEQS            } from '../../../modules/nf-core/purgedups/getseqs/main'
include { PURGEDUPS_SPLITFA            } from '../../../modules/nf-core/purgedups/splitfa/main'
include { MINIMAP2_SELF_ALIGNMENT      } from '../../../modules/local/minimap2_self_alignment/main'
include { WINNOWMAP                    } from '../../../modules/local/winnowmap/main'
include { MERYL_COUNT                  } from '../../../modules/nf-core/meryl/count/main'
include { MERYL_PRINT                  } from '../../../modules/local/meryl/print/main'

workflow HAPLOTIG_CLEANING {

    take:
    ch_assembly_fasta
    ch_ont_reads

    main:

    ch_versions = Channel.empty()

    MERYL_COUNT(
        ch_assembly_fasta,
        params.meryl_k_value
    )
    MERYL_PRINT( MERYL_COUNT.out.meryl_db )

    WINNOWMAP (
        MERYL_PRINT.out.repetitive_kmers,
        ch_assembly_fasta,
        ch_ont_reads
    )

    PURGEDUPS_PBCSTAT( WINNOWMAP.out.paf )
    PURGEDUPS_CALCUTS( PURGEDUPS_PBCSTAT.out.stat )

    PURGEDUPS_SPLITFA ( ch_assembly_fasta )
    MINIMAP2_SELF_ALIGNMENT ( PURGEDUPS_SPLITFA.out.split_fasta )


    PURGEDUPS_PURGEDUPS (
        PURGEDUPS_PBCSTAT.out.basecov,
        PURGEDUPS_CALCUTS.out.cutoff,
        MINIMAP2_SELF_ALIGNMENT.out.paf
    )


    PURGEDUPS_GETSEQS (
        ch_assembly_fasta,
        PURGEDUPS_PURGEDUPS.out.bed
    )
    PURGEDUPS_GETSEQS.out.haplotigs



    emit:


    versions = ch_versions                     // channel: [ versions.yml ]
}

