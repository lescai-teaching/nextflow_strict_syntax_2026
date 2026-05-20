process QC_SUMMARY {

    input:
    tuple val(meta), path(input_file)
    env RUN_ID

    output:
    path "${meta.id}.qc.tsv"

    shell:
    '''
    printf 'sample\t%s\n' '!{meta.id}' > !{meta.id}.qc.tsv
    printf 'cohort\t%s\n' '!{meta.cohort}' >> !{meta.id}.qc.tsv
    printf 'suffix\t%s\n' '!{params.suffix}' >> !{meta.id}.qc.tsv
    printf 'run_id\t%s\n' "$RUN_ID" >> !{meta.id}.qc.tsv
    printf 'reads\t%s\n' "$(wc -l < !{input_file})" >> !{meta.id}.qc.tsv
    '''
}
