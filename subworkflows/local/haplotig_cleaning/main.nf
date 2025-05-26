include { PURGEDUPS_PURGEDUPS          } from '../../../modules/nf-core/purgedups/purgedups/main'
include { PURGEDUPS_CALCUTS            } from '../../../modules/nf-core/purgedups/calcuts/main'
include { PURGEDUPS_PBCSTAT            } from '../../../modules/nf-core/purgedups/pbcstat/main'
include { PURGEDUPS_GETSEQS            } from '../../../modules/nf-core/purgedups/getseqs/main'
include { PURGEDUPS_SPLITFA            } from '../../../modules/nf-core/purgedups/splitfa/main'
include { MINIMAP2_SELF_ALIGNMENT      } from '../../../modules/local/minimap2/self_align/main'
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

    // Grouping by meta and giving to Winnowmap
    MERYL_PRINT.out.repetitive_kmers
        .concat( ch_assembly_fasta )
        .concat( ch_ont_reads )
        .groupTuple()
        .map {
            meta, list ->
                [ meta, *list ]
        }
        .set { ch_winnowmap_input }

    WINNOWMAP ( ch_winnowmap_input )

    PURGEDUPS_PBCSTAT( WINNOWMAP.out.paf )
    PURGEDUPS_CALCUTS( PURGEDUPS_PBCSTAT.out.stat )

    PURGEDUPS_SPLITFA ( ch_assembly_fasta )
    MINIMAP2_SELF_ALIGNMENT ( PURGEDUPS_SPLITFA.out.split_fasta )

    // Purge dups
    PURGEDUPS_PBCSTAT.out.basecov
        .concat( PURGEDUPS_CALCUTS.out.cutoff )
        .concat( MINIMAP2_SELF_ALIGNMENT.out.paf )
        .groupTuple()
        .map {
            meta, list ->
                [ meta, *list ]
        }
        .set { ch_purgedups_input}

    PURGEDUPS_PURGEDUPS ( ch_purgedups_input )

    // Get seqs
    ch_assembly_fasta
        .concat( PURGEDUPS_PURGEDUPS.out.bed )
        .groupTuple()
        .map {
            meta, list ->
                [ meta, *list ]
        }
        .set { ch_getseqs_input }

    PURGEDUPS_GETSEQS ( ch_getseqs_input )

    ch_versions = ch_versions
                    .mix ( MERYL_COUNT.out.versions )
                    .mix ( PURGEDUPS_PBCSTAT.out.versions )
                    .mix ( PURGEDUPS_CALCUTS.out.versions )
                    .mix ( PURGEDUPS_SPLITFA.out.versions )
                    .mix ( PURGEDUPS_PURGEDUPS.out.versions )
                    .mix ( PURGEDUPS_GETSEQS.out.versions )


    emit:
    haplotigs = PURGEDUPS_GETSEQS.out.haplotigs
    versions = ch_versions                     // channel: [ versions.yml ]
}

