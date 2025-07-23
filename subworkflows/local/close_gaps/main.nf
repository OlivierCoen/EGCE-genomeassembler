include { MASURCA_SAMBA                         } from '../../../modules/local/masurca/samba'
include { SEQKIT_FQ2FA                          } from '../../../modules/nf-core/seqkit/fq2fa'
include { TGSGAPCLOSER                          } from '../../../modules/local/tgsgapcloser'
include { FGAP                                  } from '../../../modules/local/fgap'


workflow CLOSE_GAPS {

    take:
    ch_long_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()
    ch_gapclosed_assemblies = Channel.empty()

    if ( params.gap_closer == "tgap" || params.gap_closer == "tgsgapcloser" ) {

        // we need reads in Fasta format
        SEQKIT_FQ2FA ( ch_long_reads )

        ch_versions = ch_versions.mix ( SEQKIT_FQ2FA.out.versions )

        ch_assemblies
            .join ( SEQKIT_FQ2FA.out.fasta )
            .set { gapcloser_input }

        if ( params.gap_closer == "tgap" ) {

            FGAP ( gapcloser_input )
            FGAP.out.gapclosed_assemblies.set { ch_gapclosed_assemblies }

        } else if ( params.gap_closer == "tgsgapcloser" ) {

            TGSGAPCLOSER( gapcloser_input )
            TGSGAPCLOSER.out.assembly.set { ch_gapclosed_assemblies }

        }

    } else {

        ch_assemblies
            .join ( ch_long_reads )
            .set { gapcloser_input }

        if ( params.gap_closer == "samba" ) {

            MASURCA_SAMBA( gapcloser_input )
            MASURCA_SAMBA.out.scaffolds_fasta.set { ch_gapclosed_assemblies }

        }

    }

    emit:
    gapclosed_assemblies                    = ch_gapclosed_assemblies
    versions                                = ch_versions                     // channel: [ versions.yml ]
}

