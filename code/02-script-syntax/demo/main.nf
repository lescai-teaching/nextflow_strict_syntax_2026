#!/usr/bin/env nextflow

def normalizeSamples(values) {
    values.collect { value -> value.trim().toLowerCase() }
}

workflow {
    main:
    def parser = new groovy.json.JsonSlurper()
    def metadata = parser.parseText('{"run_id":"run_42","suffix":"_trimmed"}')
    def paired_count = 0
    def samples = normalizeSamples([' NA12878 ', ' HG002 ', ' control '])
    samples.each { _sample -> paired_count += 1 }
    def cohort_status = paired_count == 3 ? 'ready' : 'small'
    def discovery = samples.findAll { sample -> sample != 'control' }
    def manifest = [discovery[0], discovery[1], metadata.suffix]
    channel.of(manifest).view { values -> values.join(':') }
    channel.of(cohort_status).view { value -> "cohort_status=${value}" }
}
