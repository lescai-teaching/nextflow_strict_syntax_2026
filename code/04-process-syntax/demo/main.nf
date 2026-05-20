#!/usr/bin/env nextflow

process INDEX_SUMMARY {

    input:
    tuple val(sample_id), val(read_count)
    env 'RUN_ID'

    output:
    path "${sample_id}.summary.tsv"

    script:
    """
    printf 'run_id\t%s\n' "\$RUN_ID" > ${sample_id}.summary.tsv
    printf 'sample\t%s\n' '${sample_id}' >> ${sample_id}.summary.tsv
    printf 'reads\t%s\n' '${read_count}' >> ${sample_id}.summary.tsv
    """
}

workflow {
    main:
    def samples = channel.of(['HG002', 1500000])
    INDEX_SUMMARY(samples, 'run_42')
    INDEX_SUMMARY.out.view { file -> "wrote ${file.name}" }
}
