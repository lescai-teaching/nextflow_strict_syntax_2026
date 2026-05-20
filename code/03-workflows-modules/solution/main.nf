#!/usr/bin/env nextflow

include { MERGE_LANES } from './modules/merge_lanes'

workflow {
    main:
    def samples = channel.of('HG002_L1', 'HG002_L2', 'HG003_L1')
    MERGE_LANES(samples, params.suffix)
    MERGE_LANES.out.files.view { file -> "merged ${file.name}" }
}
