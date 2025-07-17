//include { MASURCA_SAMBA                          } from '../../../modules/local/masurca/samba'
include { SEQKIT_FQ2FA                          } from '../../../modules/nf-core/seqkit/fq2fa'
include { TGSGAPCLOSER                          } from '../../../modules/local/tgsgapcloser'


workflow CLOSE_GAPS {

    take:
    ch_long_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()

    // we need reads in Fasta format for TGS Gap Closer
    SEQKIT_FQ2FA ( ch_long_reads )

    ch_assemblies
        .join ( SEQKIT_FQ2FA.out.fasta )
        .set { tgsgapcloser_input }

    TGSGAPCLOSER( tgsgapcloser_input )

    ch_versions = ch_versions.mix ( SEQKIT_FQ2FA.out.versions )

    emit:
    assemblies                 = TGSGAPCLOSER.out.assembly
    versions                   = ch_versions                     // channel: [ versions.yml ]
}

