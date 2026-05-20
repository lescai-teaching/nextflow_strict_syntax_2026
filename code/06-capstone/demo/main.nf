#!/usr/bin/env nextflow

include { QC_SUMMARIES } from './modules/qc_summary'

def buildMeta(sample_id) {
    [id: sample_id, cohort: 'discovery']
}

workflow {
    main:
    def run_id = 'capstone_run_v1'
    def samples = channel.of(
        tuple(buildMeta('sample_a'), file('data/sample_a.txt')),
        tuple(buildMeta('sample_b'), file('data/sample_b.txt'))
    )
    QC_SUMMARIES(samples, params.suffix, run_id)
    QC_SUMMARIES.out.reports.view { file -> file.name }
}
