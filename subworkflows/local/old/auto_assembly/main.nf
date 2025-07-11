include { PECAT_ASSEMBLY                      } from '../pecat_assembly/main'
include { POLISH                              } from '../polish/main'


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
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow AUTO_ASSEMBLY {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()
    ch_flye_report = Channel.empty()

    // --------------------------------------------------------
    // PRIMARY ASSEMBLY
    // --------------------------------------------------------

    if ( params.assembler == "pecat" ) {

        PECAT_ASSEMBLY ( ch_reads )

        PECAT_ASSEMBLY.out.primary_assembly
            .tap { ch_assemblies }
            .mix( PECAT_ASSEMBLY.out.alternate_assembly )
            .mix( PECAT_ASSEMBLY.out.haplotype_1_assembly )
            .mix( PECAT_ASSEMBLY.out.haplotype_2_assembly )
            .mix( PECAT_ASSEMBLY.out.rest_first_assembly )
            .mix( PECAT_ASSEMBLY.out.rest_second_assembly )
            .set { ch_draft_assembly_versions }

        ch_reads.set { ch_prepared_reads }

    } else {
        error ( "Unknown assembler: ${params.assembler}" )
    }

    // --------------------------------------------------------
    // POLISHING
    // --------------------------------------------------------

    ch_assemblies
        .branch ( polishBranchCriteria )
        .set { ch_assemblies }

    POLISH_ASSEMBLY ( ch_reads, ch_assemblies.polish_me )

    // collecting all intermediate and final assemblies (for QC) as well as haplotypes and others...
    ch_draft_assembly_versions
        .mix ( ch_assemblies.leave_me_alone )
        .mix ( POLISH_ASSEMBLY.out.polished_assembly_versions )
        .set { ch_draft_assembly_versions }

    ch_assemblies.leave_me_alone
        .mix ( POLISH_ASSEMBLY.out.assemblies )
        .set { ch_assemblies }


    emit:
    assemblies                       = ch_assemblies
    draft_assembly_versions          = ch_draft_assembly_versions
    reads                            = ch_prepared_reads
    versions                         = ch_versions                     // channel: [ versions.yml ]

}
