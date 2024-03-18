#!/usr/bin/env nextflow

log.info """\
 =========================================

 nf-pollen-metabarcoding (v1.0.0)

 -----------------------------------------

 Authors:
   - Simon Murray <simon.murray@ucl.ac.uk>
   - Chris Wyatt <c.wyatt@ucl.ac.uk>

 -----------------------------------------

 Copyright (c) 2024

 =========================================""".stripIndent()

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
include { validateParameters; paramsHelp; paramsSummaryLog; fromSamplesheet } from 'plugin/nf-validation'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow {

  if (params.help) {
    helpMessage()
    exit 0
  }

  //Ensuring mandatory parameters are provided
  ch_sample_list = params.input != null ? Channel.fromPath(params.input) : errorMessage()
  ch_database = params.database != null ? Channel.fromPath(params.database) : errorMessage()

  // Validate input parameters
  validateParameters()

  // Print summary of supplied parameters
  log.info paramsSummaryLog(workflow)

  //Make a channel for version outputs:
  ch_versions = Channel.empty()

  //Input to cutadapt depends on whether a single-end fastq or a set of paired-end fastqs are provided
  if (params.single_end == true) {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": true ], [ csv.split(",")[1] ] ] } | CUTADAPT
  }
  else {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": false ], [ csv.split(",")[1], csv.split(",")[2] ] ] } | CUTADAPT
  }
  ch_versions = ch_versions.mix(CUTADAPT.out.versions.first())

  CUTADAPT.out.reads | PEAR
  ch_versions = ch_versions.mix(PEAR.out.versions.first())

  PEAR.out.assembled | VSEARCH_FASTQ_FILTER
  ch_versions = ch_versions.mix(VSEARCH_FASTQ_FILTER.out.versions.first())

  VSEARCH_FASTQ_FILTER.out.fasta | VSEARCH_DEREP_FULL_LENGTH
  ch_versions = ch_versions.mix(VSEARCH_DEREP_FULL_LENGTH.out.versions.first())

  //Need to ensure the database is provided to each fasta file
  VSEARCH_DEREP_FULL_LENGTH.out.fasta | combine(ch_database) | multiMap { it -> fa: [it[0], it[1]]; db: it[2] } | set { ch_sintax }

  VSEARCH_SINTAX(ch_sintax.fa, ch_sintax.db)
  ch_versions = ch_versions.mix(VSEARCH_SINTAX.out.versions.first())

  //Original scripts used R for wrangling the sintax output, same can be done with a single line of bash code so made the R script an optional module
  if (params.r_processing == true) {
    R_PROCESSING(VSEARCH_SINTAX.out.tsv)
    ch_versions = ch_versions.mix(R_PROCESSING.out.versions.first())
  }
  else {
    PROCESSING(VSEARCH_SINTAX.out.tsv)
  }

  CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.collectFile(name: 'collated_versions.yml')
  )
}

workflow.onComplete {
    println ( workflow.success ? "\nDone! Check results in $params.outdir \n" : "Hmmm .. something went wrong\n" )
}
