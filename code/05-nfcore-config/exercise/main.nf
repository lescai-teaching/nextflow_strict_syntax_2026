#!/usr/bin/env nextflow

process REPORT_COHORT {

    input:
    val size
    val queue_label

    output:
    path 'cohort.txt'

    script:
    """
    printf 'cohort_size=%s\n' '${size}' > cohort.txt
    printf 'cohort_queue=%s\n' '${queue_label}' >> cohort.txt
    """
}

workflow {
    main:
    REPORT_COHORT(params.cohort_size, params.cohort_queue)
    REPORT_COHORT.out.view { file -> file.text.trim() }
}
