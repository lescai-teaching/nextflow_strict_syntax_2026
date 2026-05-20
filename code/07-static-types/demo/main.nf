#!/usr/bin/env nextflow

nextflow.enable.types = true

record Sample {
    id: String
    reads: Path
    single_end: Boolean
}

record Report {
    id: String
    qc: Path
}

process MAKE_QC {

    input:
    sample: Sample

    output:
    record(
        id: sample.id,
        qc: file("${sample.id}.qc.tsv")
    )

    script:
    """
    printf 'sample\t%s\n' '${sample.id}' > ${sample.id}.qc.tsv
    printf 'reads_file\t%s\n' '${sample.reads.name}' >> ${sample.id}.qc.tsv
    printf 'single_end\t%s\n' '${sample.single_end}' >> ${sample.id}.qc.tsv
    """
}

workflow MAKE_REPORTS {
    take:
    samples: Channel<Sample>

    main:
    reports_ch = MAKE_QC(samples)

    emit:
    reports: Channel<Report> = reports_ch
}

workflow {
    main:
    // sample_a: exactly the fields declared by Sample.
    // sample_b: an extra `strandedness` field that Sample{} does not declare.
    // Both are accepted: typed channels are duck-typed, so as long as the
    // required fields are present, extra fields are carried through unchanged.
    samples_ch = channel.of(
        record(id: 'sample_a', reads: file('reads_a.fastq.gz'), single_end: true),
        record(id: 'sample_b', reads: file('reads_b.fastq.gz'), single_end: false, strandedness: 'forward')
    )
    reports_ch = MAKE_REPORTS(samples_ch)
    reports_ch.view { rec -> "qc=${rec.id}:${rec.qc.name}" }
}
