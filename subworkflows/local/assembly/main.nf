include { FLYE                                 } from '../../../modules/nf-core/flye/main'
include { PECAT_ASSEMBLY                       } from '../pecat_assembly/main'


workflow ASSEMBLY {

    take:
    ch_reads

    main:
    ch_versions = Channel.empty()
    ch_flye_report = Channel.empty()

    // --------------------------------------------------------
    // Primary Assembly
    // --------------------------------------------------------

    if ( params.assembler == "flye" ) {

        FLYE( ch_reads, params.flye_mode )

        FLYE.out.fasta.set { ch_assemblies }
        FLYE.out.txt.set { ch_flye_report }

        ch_versions = ch_versions.mix ( FLYE.out.versions )

    } else { //pecat

        PECAT_ASSEMBLY ( ch_reads )

        /*
        Channel.emtpy()
            .concat( PECAT_ASSEMBLY.out.primary_assembly )
            .concat( PECAT_ASSEMBLY.out.alternate_assembly )
            .concat( PECAT_ASSEMBLY.out.haplotype_1_assembly )
            .concat( PECAT_ASSEMBLY.out.haplotype_2_assembly )
            .concat( PECAT_ASSEMBLY.out.rest_first_assembly )
            .concat( PECAT_ASSEMBLY.out.rest_second_assembly )
            .set { ch_assemblies }
        */
        PECAT_ASSEMBLY.out.primary_assembly.set { ch_assemblies }
    }

    emit:
    assemblies                       = ch_assemblies
    flye_report                      = ch_flye_report
    versions                         = ch_versions                     // channel: [ versions.yml ]

}
