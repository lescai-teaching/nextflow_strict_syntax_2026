#!/usr/bin/env nextflow

include { MERGE_LANE } from './modules/merge_lanes' addParams(suffix: params.suffix)

workflow {
    main:
    MERGE_LANE(channel.of('HG002_L1', 'HG002_L2', 'HG003_L1'))
    MERGE_LANE.out.view { "merged ${it.name}" }
}
