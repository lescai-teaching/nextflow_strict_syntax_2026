#!/usr/bin/env nextflow

include { QC_SUMMARY } from './modules/qc_summary' addParams(suffix: params.suffix)

def buildMeta(sample_id) {
    return [id: sample_id, cohort: 'discovery']
}

workflow {
    main:
    String run_id = 'capstone_run_v1'
    def samples = Channel.of(
        tuple(buildMeta('sample_a'), file('data/sample_a.txt')),
        tuple(buildMeta('sample_b'), file('data/sample_b.txt'))
    )
    QC_SUMMARY(samples, run_id)
    QC_SUMMARY.out.view { it.name }
}
