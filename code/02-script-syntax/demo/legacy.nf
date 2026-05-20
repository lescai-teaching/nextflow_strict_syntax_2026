#!/usr/bin/env nextflow

import groovy.json.JsonSlurper

class CohortMeta {
    String runId
}

def normalizeSamples(values) {
    values.collect { it.trim().toLowerCase() }
}

workflow {
    main:
    def parser = new JsonSlurper()
    def metadata = parser.parseText('{"run_id":"run_42","suffix":"_trimmed"}')
    String cohort_status = 'unknown'
    Integer paired_count = 0
    def samples = normalizeSamples(values = [' NA12878 ', ' HG002 ', ' control '])
    for (sample in samples) {
        paired_count++
    }
    switch (paired_count) {
        case 3:
            cohort_status = 'ready'
            break
        default:
            cohort_status = 'small'
    }
    def discovery = samples.findAll { it != 'control' }
    def manifest = [*discovery, metadata.suffix]
    Channel.of(manifest).view { it.join(':') }
    Channel.of(cohort_status).view { "cohort_status=${it}" }
}
