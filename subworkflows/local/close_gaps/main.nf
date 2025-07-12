include { MASURCA_SAMBA                          } from '../../../modules/local/masurca/samba'


workflow CLOSE_GAPS {

    take:
    ch_long_reads
    ch_reference_genome_fasta

    main:

    ch_versions = Channel.empty()

    ch_reference_genome_fasta
        .join ( ch_long_reads )
        .set { samba_input }

    MASURCA_SAMBA( samba_input )

    emit:
    scaffolds_fasta                 = MASURCA_SAMBA.out.scaffolds_fasta
    versions                        = ch_versions                     // channel: [ versions.yml ]
}

