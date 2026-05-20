#!/usr/bin/env nextflow

// Reference wrapper that consumes an installed registry module.
//
// To run this end-to-end you need to install the module first into this
// directory:
//
//     nextflow module install nf-core/fastqc
//
// This creates ./modules/nf-core/fastqc/main.nf which the include below
// resolves to. The wrapper itself is intentionally tiny: it shows the
// include + call shape that every consumer of a registry module ends up
// writing.

include { FASTQC } from './modules/nf-core/fastqc'

workflow {
    main:
    def samples = channel.of(
        tuple([id: 'sample_a', single_end: true], file('data/reads_a.fastq'))
    )
    FASTQC(samples)
    FASTQC.out.html.view { meta, html -> "html=${html.name}" }
}
