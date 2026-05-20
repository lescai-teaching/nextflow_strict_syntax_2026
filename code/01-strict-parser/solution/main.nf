#!/usr/bin/env nextflow

def trimmedName(value) {
    value.replace('.fastq.gz', '_trimmed.fastq.gz')
}

workflow {
    main:
    def fastqs = ['HG002.fastq.gz', 'HG003.fastq.gz', 'control.fastq.gz']
    def raw_run_label = 'run.fastq.gz'
    def run_label = trimmedName(raw_run_label)
    channel.fromList(fastqs)
        .filter { fastq -> fastq.startsWith('HG') }
        .map { fastq -> trimmedName(fastq) }
        .view { fastq -> "[${run_label}] ${fastq}" }
}
