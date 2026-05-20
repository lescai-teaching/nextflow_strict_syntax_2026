#!/usr/bin/env nextflow

process FLAGSTAT_SUMMARY {

    input:
    tuple val(sample_id), val(total_reads)
    env ANALYSIS_NS

    output:
    path 'flagstat.txt'

    shell:
    '''
    echo "namespace=$ANALYSIS_NS" > flagstat.txt
    echo "sample=!{sample_id}" >> flagstat.txt
    echo "total=!{total_reads}" >> flagstat.txt
    '''
}

workflow {
    main:
    def stats = channel.of(['NA12878', 2400000])
    FLAGSTAT_SUMMARY(stats, 'discovery')
    FLAGSTAT_SUMMARY.out.view { "wrote ${it.name}" }
}
