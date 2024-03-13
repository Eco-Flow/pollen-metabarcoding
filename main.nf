#!/usr/bin/env nextflow

def helpMessage() {
    log.info"""
    You have asked for the help message.
    """.stripIndent()
}

def errorMessage() {
    log.info"""
    You failed to provide the --input parameter.
    The pipeline has exited with error status 1.
    """.stripIndent()
    exit 1
}

include { PEAR } from './modules/nf-core/pear/main'
include { CUTADAPT } from './modules/nf-core/cutadapt/main'
include { VSEARCH_FASTQ_FILTER } from './modules/local/vsearch_fastq_filter.nf'
include { VSEARCH_SINTAX } from './modules/nf-core/vsearch/sintax/main'

workflow {
  if (params.help) {
    helpMessage()
    exit 0
  }
  ch_sample_list = params.input != null ? Channel.fromPath(params.input) : errorMessage()
  if (params.single_end == true) {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": true ], [ csv.split(",")[1] ] ] } | CUTADAPT
  }
  else {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": false ], [ csv.split(",")[1], csv.split(",")[2] ] ] } | CUTADAPT
  }
  CUTADAPT.out.reads | PEAR
  PEAR.out.assembled | VSEARCH_FASTQ_FILTER
}
