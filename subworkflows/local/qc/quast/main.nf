include { QUAST } from '../../../../modules/local/quast/main'

workflow QC_QUAST {
    take:
    assembly
    aln_to_assembly

    main:

    Channel.empty().set { versions }
    Channel.empty().set { quast_results }
    Channel.empty().set { quast_tsv }
    assembly.view()
    aln_to_assembly.view()
    assembly
        .join( aln_to_assembly )
        .set { quast_input }

    QUAST( quast_input )
    QUAST.out.results.set { quast_results }
    QUAST.out.tsv.set { quast_tsv }
    QUAST.out.versions.set { versions }

    emit:
    quast_results
    quast_tsv
    versions
}
