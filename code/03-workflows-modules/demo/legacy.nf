#!/usr/bin/env nextflow

include { RENAME_FASTQ } from './modules/rename_fastq' addParams(suffix: params.suffix)

workflow {
    main:
    RENAME_FASTQ(channel.of('NA12878', 'HG002'))
    RENAME_FASTQ.out.view { "created ${it.name}" }
}
