#!/usr/bin/env nextflow

def trimmedName(value) {
    value.replace('.fastq.gz', '_trimmed.fastq.gz')
}

workflow {
    main:
    List fastqs = ['HG002.fastq.gz', 'HG003.fastq.gz', 'control.fastq.gz']
    String run_label = trimmedName(value = 'run.fastq.gz')
    Channel.fromList(fastqs)
        .filter { it.startsWith('HG') }
        .map { trimmedName(it) }
        .view { "[${run_label}] ${it}" }
}
