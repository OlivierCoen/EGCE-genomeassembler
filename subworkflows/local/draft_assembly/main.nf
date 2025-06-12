include { FLYE                                 } from '../../../modules/local/flye'

include { HIFIASM_WORKFLOW                     } from '../hifiasm/main'
include { POLISH                               } from '../polish/main'

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


workflow DRAFT_ASSEMBLY {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()
    ch_flye_report = Channel.empty()
    ch_alternate_assemblies = Channel.empty()

     if ( params.assembler == "flye" ) {

        ch_reads
           .join( Channel.topic('mean_qualities') )
           .set { ch_flye_input }

        FLYE( ch_flye_input )

        FLYE.out.fasta.set { ch_assemblies }

    } else if ( params.assembler == "hifiasm" ) {

        HIFIASM_WORKFLOW ( ch_reads )

        HIFIASM_WORKFLOW.out.assemblies.set { ch_assemblies }
        HIFIASM_WORKFLOW.out.draft_assembly_versions.set { ch_alternate_assemblies }

    } else {
        error ("Unknown assembler in this subworkflow: ${params.assembler}") // this should not happen
    }

    // --------------------------------------------------------
    // POLISHING
    // --------------------------------------------------------

    ch_assemblies
        .branch ( polishBranchCriteria )
        .set { ch_branched_assemblies }

    POLISH ( ch_reads, ch_branched_assemblies.polish_me )

    // collecting all intermediate and final assemblies (for QC)
    ch_branched_assemblies.leave_me_alone
        .mix ( POLISH.out.polished_assembly_versions )
        .mix ( ch_alternate_assemblies )
        .set { ch_draft_assembly_versions }

    ch_branched_assemblies.leave_me_alone
        .mix ( POLISH.out.assemblies )
        .set { ch_draft_assemblies }

    emit:
    assemblies                       = ch_draft_assemblies
    flye_report                      = ch_flye_report
    draft_assembly_versions          = ch_draft_assembly_versions
    versions                         = ch_versions


}
