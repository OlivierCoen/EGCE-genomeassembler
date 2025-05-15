include { FLYE                         } from '../../../modules/nf-core/flye/main'
include { PIGZ_UNCOMPRESS              } from '../../../modules/nf-core/pigz/uncompress/main'
include { MEDAKA                       } from '../../../modules/nf-core/medaka/main'

workflow ASSEMBLY {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()

   if ( params.skip_assembly ) {
        if ( !params.assembly_fasta ) {
            error( "When setting --skip_assembly, you must also provide an assembly with --assembly_fasta" )
        } else {
            Channel.fromPath(params.assembly_fasta, checkIfExists: true)
                    .map {
                        fasta_file ->
                            def meta = [ id: fasta_file.getBaseName() ]
                            [ meta, fasta_file ]
                    }
                    .set { ch_assembly_fasta }
        }
    }

    if ( !params.skip_assembly ) {
        FLYE(
            ch_reads,
            params.flye_mode
            )
        FLYE.out.fasta.set { ch_assembly_fasta }
    }

    if ( !params.skip_polishing ) {

        // we need to make sure that the reads and assembly files are uncompressed
        // to avoid interfering directly into the Medaka process (which does not support compressed files unfortunately)
        // we perform a complex interplay of channels

        // adding label to reads and assembly
        ch_reads.map { meta, file -> [ [meta: meta, type: "reads"], file ] }.set { ch_reads }
        ch_assembly_fasta.map { meta, file -> [ [meta: meta, type: "assembly"], file ] }.set { ch_assembly_fasta }

        // uncompressing all files together in the same channel
        ch_reads.concat( ch_assembly_fasta ) | PIGZ_UNCOMPRESS

        // separating reads and assembly again
        PIGZ_UNCOMPRESS.out.file
            .branch {
                overmeta, file ->
                    reads: overmeta.type == 'reads'
                        return [ overmeta.meta, file ]
                    assembly: overmeta.type == 'assembly'
                        return [ overmeta.meta, file ]
            }
            .set { ch_uncompressed }

        // grouping by meta
        ch_uncompressed.reads
            .concat( ch_uncompressed.assembly )
            .groupTuple()
            .map {
                meta, list ->
                    [ meta, *list ]
            }
            .set { ch_medaka_input }

        MEDAKA ( ch_medaka_input )
        MEDAKA.out.assembly.set { ch_assembly_fasta }
    }


    emit:
    assembly_fasta = ch_assembly_fasta

    versions = ch_versions                     // channel: [ versions.yml ]
}

