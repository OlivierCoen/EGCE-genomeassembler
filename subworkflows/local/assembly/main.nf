include { FLYE                                 } from '../../../modules/local/flye'
include { PECAT_ASSEMBLY                       } from '../pecat_assembly/main'
include { POLISH_ASSEMBLY                      } from '../polish_assembly/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CRITERIA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def polishBranchCriteria = branchCriteria { meta, assembly ->
    polish_me: meta.polish_draft_assembly
    leave_me_alone: !meta.polish_draft_assembly
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow ASSEMBLY {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()
    ch_flye_report = Channel.empty()

    // --------------------------------------------------------
    // PRIMARY ASSEMBLY
    // --------------------------------------------------------

    if ( params.assembler == "flye" ) {

        ch_reads
           .join( Channel.topic('mean_qualities') )
           .set { flye_input }

        FLYE( flye_input )

        FLYE.out.fasta.set { ch_assemblies }
        FLYE.out.txt.set { ch_flye_report }

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

    // --------------------------------------------------------
    // POLISHING
    // --------------------------------------------------------

    if ( params.assembler == "flye" ) {

        ch_assemblies
            .branch ( polishBranchCriteria )
            .set { ch_assemblies }

        POLISH_ASSEMBLY ( ch_reads, ch_assemblies.polish_me )

        // collecting all intermediate and final assemblies (for QC)
        ch_assemblies.leave_me_alone
            .mix ( POLISH_ASSEMBLY.out.polished_assembly_versions )
            .set { ch_draft_assembly_versions }

        ch_assemblies.leave_me_alone
            .mix ( POLISH_ASSEMBLY.out.assemblies )
            .set { ch_assemblies }

    }

    emit:
    assemblies                       = ch_assemblies
    draft_assembly_versions          = ch_draft_assembly_versions
    flye_report                      = ch_flye_report
    versions                         = ch_versions                     // channel: [ versions.yml ]

}
