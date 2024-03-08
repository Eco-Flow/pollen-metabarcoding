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

include { PEARRM } from './modules/local/pearrm.nf' 
//CUTADAPT multiple process logic taken from nf-core ampliseq 
include { CUTADAPT as CUTADAPT_BASIC } from './modules/nf-core/cutadapt/main'
include { CUTADAPT as CUTADAPT_READTHROUGH } from './modules/nf-core/cutadapt/main'
include { CUTADAPT as CUTADAPT_DOUBLEPRIMER } from './modules/nf-core/cutadapt/main'

workflow {
  if (params.help) {
    helpMessage()
    exit 0
  }
  ch_sample_list = params.input != null ? Channel.fromPath(params.input) : errorMessage()
  //Flattening sample list so each sample is a separate channel and converting contents of that channel to a 3 item array
  //ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [csv.split(",")[0], csv.split(",")[1], csv.split(",")[2]] } | PEARRM
  //ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": params.single_end == true ? true : false ], [ csv.split(",")[1], csv.split(",")[2] ] ] } | CUTADAPT_BASIC
  if (params.single_end == true) {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": true ], [ csv.split(",")[1] ] ] } | CUTADAPT_BASIC
  }
  else {
     ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [ [ "id":csv.split(",")[0], "single_end": false ], [ csv.split(",")[1], csv.split(",")[2] ] ] } | CUTADAPT_BASIC
  }
  CUTADAPT_BASIC.out.reads | map { meta, fastqs -> [ meta.id, fastqs[0], fastqs[1] ] } | PEARRM
  //Mapping the sample and fastq into separate channels for CUTADAPT
  //PEARRM.out.merged_fastq | map { id, fastq -> params.single_end != null ? [["id": id, "single_end": "single_end"], fastq] : [["id": id, "paired_end": 'paired_end'], fastq] } | set{ cutadapt_input }
  //CUTADAPT_BASIC(cutadapt_input)
}
