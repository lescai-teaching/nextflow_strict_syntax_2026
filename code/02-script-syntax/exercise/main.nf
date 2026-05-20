#!/usr/bin/env nextflow

import groovy.json.JsonSlurper

class ReadStats {
    Integer mapped
    Integer unmapped
}

def stripExt(values) {
    values.collect { it.replace('.bam', '') }
}

workflow {
    main:
    def parser = new JsonSlurper()
    def thresholds = parser.parseText('{"min_reads":1000,"library":"WGS"}')
    String library_label = 'unknown'
    Integer bam_count = 0
    Path manifest_path = file('manifest.txt')
    def bams = stripExt(values = ['HG002.bam', 'HG003.bam', 'undetermined.bam'])
    while (bam_count < bams.size()) {
        bam_count++
    }
    switch (thresholds.library) {
        case 'WGS':
            library_label = 'whole-genome'
            break
        default:
            library_label = 'targeted'
    }
    def keep = bams.findAll { it != 'undetermined' }
    def summary = [thresholds.library, *keep, bam_count.toString()]
    Channel.of(summary).view { it.join('|') }
    Channel.of(library_label).view { "library=${it}; manifest=${manifest_path.name}" }
}
