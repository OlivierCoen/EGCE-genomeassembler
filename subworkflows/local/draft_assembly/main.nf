include { FLYE                                 } from '../../../modules/local/flye'
include { HIFIASM_WORKFLOW                     } from '../hifiasm/main'


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

    emit:
    assemblies                       = ch_assemblies
    alternate_assemblies             = ch_alternate_assemblies
    flye_report                      = ch_flye_report
    versions                         = ch_versions


}
