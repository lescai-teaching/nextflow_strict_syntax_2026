process MERGE_LANE {

    input:
    val sample_id

    output:
    path "${sample_id}.txt"

    script:
    """
    printf '%s\n' '${sample_id}_${params.suffix}' > ${sample_id}.txt
    """
}
