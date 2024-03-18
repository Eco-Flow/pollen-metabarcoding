#!/usr/bin/env nextflow

def helpMessage() {
    log.info"""
    You have asked for the help message.
    """.stripIndent()
}

def errorMessage() {
    log.info"""
    You failed to provide the --input and/or --database parameters.
    The pipeline has exited with error status 1.
    """.stripIndent()
    exit 1
}

include { PEAR } from './modules/nf-core/pear/main'
include { CUTADAPT } from './modules/nf-core/cutadapt/main'
include { VSEARCH_FASTQ_FILTER } from './modules/local/vsearch_fastq_filter.nf'
include { VSEARCH_DEREP_FULL_LENGTH } from './modules/local/vsearch_derep.nf'
include { VSEARCH_SINTAX } from './modules/nf-core/vsearch/sintax/main'
include { R_PROCESSING } from './modules/local/r_processing.nf'
include { PROCESSING } from './modules/local/processing.nf'

workflow {
  if (params.help) {
    helpMessage()
    exit 0
  }
  //Ensuring mandatory parameters are provided
  ch_sample_list = params.input != null ? Channel.fromPath(params.input) : errorMessage()
  ch_database = params.database != null ? Channel.fromPath(params.database) : errorMessage()
  //Input to cutadapt depends on whether a single-end fastq or a set of paired-end fastqs are provided
  if (params.single_end == true) {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": true ], [ csv.split(",")[1] ] ] } | CUTADAPT
  }
  else {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": false ], [ csv.split(",")[1], csv.split(",")[2] ] ] } | CUTADAPT
  }
  CUTADAPT.out.reads | PEAR
  PEAR.out.assembled | VSEARCH_FASTQ_FILTER
  VSEARCH_FASTQ_FILTER.out.fasta | VSEARCH_DEREP_FULL_LENGTH
  //Need to ensure the database is provided to each fasta file
  VSEARCH_DEREP_FULL_LENGTH.out.fasta | combine(ch_database) | multiMap { it -> fa: [it[0], it[1]]; db: it[2] } | set { ch_sintax } 
  VSEARCH_SINTAX(ch_sintax.fa, ch_sintax.db)
  if (params.r_processing == true) {
    R_PROCESSING(VSEARCH_SINTAX.out.tsv)  
  }
  else {
    PROCESSING(VSEARCH_SINTAX.out.tsv)
  }
}
