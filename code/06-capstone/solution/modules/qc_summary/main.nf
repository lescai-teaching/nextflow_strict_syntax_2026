process QC_SUMMARY {

    input:
    tuple val(meta), path(input_file), val(suffix)
    env 'RUN_ID'

    output:
    path "${meta.id}.qc.tsv"

    script:
    """
    printf 'sample\t%s\n' '${meta.id}' > ${meta.id}.qc.tsv
    printf 'cohort\t%s\n' '${meta.cohort}' >> ${meta.id}.qc.tsv
    printf 'suffix\t%s\n' '${suffix}' >> ${meta.id}.qc.tsv
    printf 'run_id\t%s\n' "\$RUN_ID" >> ${meta.id}.qc.tsv
    printf 'reads\t%s\n' "\$(wc -l < ${input_file})" >> ${meta.id}.qc.tsv
    """
}

workflow QC_SUMMARIES {
    take:
    records
    suffix
    run_id

    main:
    def prepared = records.map { meta, input_file -> tuple(meta, input_file, suffix) }
    QC_SUMMARY(prepared, run_id)

    emit:
    reports = QC_SUMMARY.out
}
