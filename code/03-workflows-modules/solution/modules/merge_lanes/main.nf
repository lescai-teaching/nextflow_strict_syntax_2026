process MERGE_LANE {

    input:
    tuple val(sample_id), val(suffix)

    output:
    path "${sample_id}${suffix}.txt"

    script:
    """
    printf 'sample=%s\nsuffix=%s\n' '${sample_id}' '${suffix}' > ${sample_id}${suffix}.txt
    """
}

workflow MERGE_LANES {
    take:
    samples
    suffix

    main:
    def records = samples.map { sample_id -> [sample_id, suffix] }
    MERGE_LANE(records)

    emit:
    files = MERGE_LANE.out
}
