#!/usr/bin/env nextflow

process MULTIQC_INPUTS {

    output:
    path 'multiqc_inputs.tsv'

    script:
    """
    printf 'qc_id\tstatus\n' > multiqc_inputs.tsv
    printf 'sample_a\tpass\n' >> multiqc_inputs.tsv
    printf 'sample_b\tpass\n' >> multiqc_inputs.tsv
    """
}

process FASTQC_VERSION {

    output:
    path 'fastqc.version.txt', topic: 'versions'

    script:
    """
    printf 'fastqc\t0.12.1\n' > fastqc.version.txt
    """
}

process BWAMEM2_VERSION {

    output:
    path 'bwamem2.version.txt', topic: 'versions'

    script:
    """
    printf 'bwa-mem2\t2.2.1\n' > bwamem2.version.txt
    """
}

process SAMTOOLS_VERSION {

    output:
    path 'samtools.version.txt', topic: 'versions'

    script:
    """
    printf 'samtools\t1.20\n' > samtools.version.txt
    """
}

workflow {
    main:
    report_ch = MULTIQC_INPUTS()
    FASTQC_VERSION()
    BWAMEM2_VERSION()
    SAMTOOLS_VERSION()
    report_ch.view { file -> "report=${file.name}" }
    channel.topic('versions').view { file -> "version=${file.text.trim()}" }

    publish:
    reports = missing_report_ch
}

output {
    reports {
        path 'reports'
    }
}
