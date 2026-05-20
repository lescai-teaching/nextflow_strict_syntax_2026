#!/usr/bin/env nextflow

def defaultSampleSuffix(value) {
    value
}

workflow {
    main:
    String suffix = defaultSampleSuffix(value = '_trimmed')
    Channel.of('sample_a', 'sample_b')
        .map { it + suffix }
        .view { "renamed: ${it}" }
}
