#!/usr/bin/env nextflow

process FLAGSTAT_SUMMARY {

    input:
    tuple val(sample_id), val(total_reads)
    env 'ANALYSIS_NS'

    output:
    path "${sample_id}.flagstat.tsv"

    script:
    """
    printf 'namespace\t%s\n' "\$ANALYSIS_NS" > ${sample_id}.flagstat.tsv
    printf 'sample\t%s\n' '${sample_id}' >> ${sample_id}.flagstat.tsv
    printf 'total\t%s\n' '${total_reads}' >> ${sample_id}.flagstat.tsv
    """
}

workflow {
    main:
    def stats = channel.of(['NA12878', 2400000])
    FLAGSTAT_SUMMARY(stats, 'discovery')
    FLAGSTAT_SUMMARY.out.view { file -> "wrote ${file.name}" }
}
