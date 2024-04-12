#!/usr/bin/env nextflow

log.info """\
 =========================================

 nf-pollen-metabarcoding (v2.0.0)

 -----------------------------------------

 Authors:
   - Simon Murray <simon.murray@ucl.ac.uk>
   - Chris Wyatt <c.wyatt@ucl.ac.uk>

 -----------------------------------------

 Copyright (c) 2024

 =========================================""".stripIndent()

include { SRATOOLS_PREFETCH } from './modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP } from './modules/nf-core/sratools/fasterqdump/main'
include { CUTADAPT } from './modules/nf-core/cutadapt/main'
include { PEAR } from './modules/nf-core/pear/main'
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

  //Split processing depending on whether two or three elements are provided on each row of input file
  Channel.fromPath(params.input) | splitCsv | branch { two: it.size() == 2; three: it.size() == 3 } | set { input_type }

  //If three elements are provided then the data is paired end so organised appropriately
  input_type.three | map{ csv -> [ [ "id":csv[0], "single_end": false ], [ csv[1], csv[2] ] ] } | set { three_tuple }

  //If a row in input file is 2 elements then it could be single end fastq or an sra so need to filter accordingly
  input_type.two | branch { fastq: it[1] =~ /\.f.*q\.gz$/ || it[1] =~ /\.f.*q$/; sra: it[1] !=~ /\.f.*q\.gz$/ || it[1] !=~ /\.f.*q$/ } | set { ch_extension }

  //Combine single end fastqs channel with paired end fastqs channel
  ch_extension.fastq | map{ csv -> [ [ "id":csv[0], "single_end": true ], [ csv[1] ] ] } | mix(three_tuple) | set { fastqs_combined }

  //Input parameter "--single_end' determines whether sras are assumed to be single_end or not
  ch_sra = params.single_end == true ? ch_extension.sra | map{ csv -> [ [ "id":csv[0], "single_end": true ], csv[1] ] } : ch_extension.sra | map{ csv -> [ [ "id":csv[0], "single_end": false ], csv[1] ] }

  //Provide ncbi_settings and certificate if provided
  ch_ncbi_settings = params.ncbi_settings != null ? Channel.fromPath(params.ncbi_settings) : []
  ch_certificate = params.certificate != null ? Channel.fromPath(params.certificate) : []

  //Need to ensure ncbi_settings and certificate are provided to each sra
  ch_sra | multiMap { it -> sra: [it[0], it[1]]; ncbi: ch_ncbi_settings; cert: ch_certificate } | set { ch_prefetch }

  SRATOOLS_PREFETCH(ch_prefetch.sra, ch_prefetch.ncbi, ch_prefetch.cert)
  SRATOOLS_FASTERQDUMP(SRATOOLS_PREFETCH.out.sra, ch_prefetch.ncbi, ch_prefetch.cert)

  //Combine provided fastqs with sra fastqs
  fastqs_combined | mix(SRATOOLS_FASTERQDUMP.out.reads) | set { all_fqs }

  CUTADAPT(all_fqs)

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
