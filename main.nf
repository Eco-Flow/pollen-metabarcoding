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

include { PEAR } from './modules/nf-core/pear/main'
include { CUTADAPT } from './modules/nf-core/cutadapt/main'
include { VSEARCH_FASTQ_FILTER } from './modules/local/vsearch_fastq_filter.nf'
include { VSEARCH_DEREP_FULL_LENGTH } from './modules/local/vsearch_derep.nf'
include { VSEARCH_SINTAX } from './modules/nf-core/vsearch/sintax/main'
include { USEARCH_SINTAX_SUMMARY } from './modules/local/sintax_summary.nf'
include { CUTTING } from './modules/local/cut.nf'
include { R_PROCESSING } from './modules/local/r_processing.nf'
include { validateParameters; paramsHelp; paramsSummaryLog } from 'plugin/nf-validation'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

workflow {

  if (params.help) {
    log.info paramsHelp("nextflow run main.nf --input input_file.csv --database database.fa --FW_primer FOWARD-PRIMER-STRING --RV_primer REVERSE-PRIMER-STRING")
    exit 0
  }

  // Validate input parameters
  validateParameters()

  // Print summary of supplied parameters
  log.info paramsSummaryLog(workflow)

  //Make a channel for version outputs:
  ch_versions = Channel.empty()

  //Input to cutadapt depends on whether a single-end fastq or a set of paired-end fastqs are provided
  if (params.single_end == true) {
     Channel.fromPath(params.input) | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": true ], [ csv.split(",")[1] ] ] } | CUTADAPT
  }
  else {
     Channel.fromPath(params.input) | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": false ], [ csv.split(",")[1], csv.split(",")[2] ] ] } | CUTADAPT
  }
  ch_versions = ch_versions.mix(CUTADAPT.out.versions.first())

  CUTADAPT.out.reads | PEAR
  ch_versions = ch_versions.mix(PEAR.out.versions.first())

  PEAR.out.assembled | VSEARCH_FASTQ_FILTER
  ch_versions = ch_versions.mix(VSEARCH_FASTQ_FILTER.out.versions.first())

  VSEARCH_FASTQ_FILTER.out.fasta | VSEARCH_DEREP_FULL_LENGTH
  ch_versions = ch_versions.mix(VSEARCH_DEREP_FULL_LENGTH.out.versions.first())

  //Need to ensure the database is provided to each fasta file
  VSEARCH_DEREP_FULL_LENGTH.out.fasta | combine(Channel.fromPath(params.database)) | multiMap { it -> fa: [it[0], it[1]]; db: it[2] } | set { ch_sintax }

  VSEARCH_SINTAX(ch_sintax.fa, ch_sintax.db)
  ch_versions = ch_versions.mix(VSEARCH_SINTAX.out.versions.first())

  if (params.gitpod == null){
  USEARCH_SINTAX_SUMMARY(VSEARCH_SINTAX.out.tsv)
  ch_versions = ch_versions.mix(USEARCH_SINTAX_SUMMARY.out.versions.first())
  }

  //Sometimes sintax produces different row lengths, only need first 2
  CUTTING(VSEARCH_SINTAX.out.tsv) | R_PROCESSING

  //Idea
  //SUMMARY(R_PROCESSING.out.classification.collect())
  // Where it would collect all the classification files and combine them to produce the same pie charts as in R_processing

  CUSTOM_DUMPSOFTWAREVERSIONS (
    ch_versions.collectFile(name: 'collated_versions.yml')
  )
  
}

workflow.onComplete {
    println ( workflow.success ? "\nDone! Check results in $params.outdir \n" : "Hmmm .. something went wrong\n" )
}
