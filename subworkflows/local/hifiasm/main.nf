include { HIFIASM                              } from '../../../modules/local/hifiasm'
include { GFA_2_FA                             } from '../../../modules/local/gfa2fa'


workflow HIFIASM_WORKFLOW {

    take:
    ch_reads

    main:

    // TODO: parse Nanoq output to distinguish between long and ultra long reads
    ch_reads
        .map { meta, reads -> [ meta, reads, [] ] }
        .set { hifiasm_inputs }

    HIFIASM( hifiasm_inputs )

    /*
    HIFIASM.out.primary_contigs
        .map { meta, primary_contigs -> [ meta + [ type: 'primary' ], primary_contigs ] }
        .set { gfa_primary_contigs }

    HIFIASM.out.alternate_contigs .set { gfa_alternate_contigs }
    HIFIASM.out.hap1_contigs.set { gfa_haplotig_1_contigs }
    HIFIASM.out.hap2_contigs.set { gfa_haplotig_2_contigs }

    gfa_primary_contigs
        .mix( gfa_alternate_contigs )
        .mix( gfa_haplotig_1_contigs )
        .mix( gfa_haplotig_2_contigs )
        .set { gfa_assemblies }
    */

    GFA_2_FA( HIFIASM.out.primary_contigs )

    GFA_2_FA.out.fasta
        .tap { draft_assembly_versions }
        .filter { meta, assembly -> meta.type == 'primary' }
        .map {
            meta, assembly ->
                def new_meta = meta
                new_meta.remove('type')
                [ new_meta, assembly ]
        }
        .set { assemblies }


    emit:
    assemblies
    draft_assembly_versions

}
