#!/usr/bin/env nextflow

def stripExt(values) {
    values.collect { value -> value.replace('.bam', '') }
}

workflow {
    main:
    def parser = new groovy.json.JsonSlurper()
    def thresholds = parser.parseText('{"min_reads":1000,"library":"WGS"}')
    def bam_count = 0
    def manifest_path = file('manifest.txt')
    def bams = stripExt(['HG002.bam', 'HG003.bam', 'undetermined.bam'])
    bams.each { _bam -> bam_count += 1 }
    def library_label = thresholds.library == 'WGS' ? 'whole-genome' : 'targeted'
    def keep = bams.findAll { bam -> bam != 'undetermined' }
    def summary = [thresholds.library, keep[0], keep[1], bam_count.toString()]
    channel.of(summary).view { values -> values.join('|') }
    channel.of(library_label).view { value -> "library=${value}; manifest=${manifest_path.name}" }
}
