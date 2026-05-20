#!/usr/bin/env nextflow

process INDEX_SUMMARY {

    input:
    tuple val(sample_id), val(read_count)
    env RUN_ID

    output:
    path 'index.summary.tsv'

    shell:
    '''
    echo "run_id=$RUN_ID" > index.summary.tsv
    echo "sample=!{sample_id}" >> index.summary.tsv
    echo "reads=!{read_count}" >> index.summary.tsv
    '''
}

workflow {
    main:
    def samples = channel.of(['HG002', 1500000])
    INDEX_SUMMARY(samples, 'run_42')
    INDEX_SUMMARY.out.view { "wrote ${it.name}" }
}
