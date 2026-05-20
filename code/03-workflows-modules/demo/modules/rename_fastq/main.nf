process RENAME_FASTQ {

    input:
    tuple val(sample_id), val(suffix)

    output:
    path "${sample_id}${suffix}.fastq"

    script:
    """
    printf 'sample=%s\nsuffix=%s\n' '${sample_id}' '${suffix}' > ${sample_id}${suffix}.fastq
    """
}

workflow RENAME_FASTQS {
    take:
    samples
    suffix

    main:
    def records = samples.map { sample_id -> [sample_id, suffix] }
    RENAME_FASTQ(records)

    emit:
    files = RENAME_FASTQ.out
}
