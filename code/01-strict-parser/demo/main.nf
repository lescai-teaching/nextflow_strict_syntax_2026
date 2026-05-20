#!/usr/bin/env nextflow

def defaultSampleSuffix(value) {
    value
}

workflow {
    main:
    def raw_suffix = '_trimmed'
    def suffix = defaultSampleSuffix(raw_suffix)
    channel.of('sample_a', 'sample_b')
        .map { sample_id -> sample_id + suffix }
        .view { sample_id -> "renamed: ${sample_id}" }
}
