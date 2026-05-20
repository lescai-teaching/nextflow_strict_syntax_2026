#!/usr/bin/env nextflow

include { RENAME_FASTQS } from './modules/rename_fastq'

workflow {
    main:
    def samples = channel.of('NA12878', 'HG002')
    RENAME_FASTQS(samples, params.suffix)
    RENAME_FASTQS.out.files.view { file -> "created ${file.name}" }
}
