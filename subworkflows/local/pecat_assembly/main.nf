include { PECAT_UNZIP      } from '../../../modules/local/pecat/unzip/main'

include { QC_BUSCO         } from '../qc/busco/main'
include { QC_BUSCO         } from '../qc/busco/main'

workflow PECAT_ASSEMBLY {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()

    ch_pecat_config_file = Channel.fromPath ( params.pecat_config_file, checkIfExists: true )
    PECAT_UNZIP (
        ch_reads,
        ch_pecat_config_file
    )
    ch_assembly_fasta = PECAT_UNZIP.out.haplotype_1_assembly


    emit:
    assembly_fasta = ch_assembly_fasta

    versions = ch_versions                     // channel: [ versions.yml ]
}

