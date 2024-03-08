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

workflow {
  if (params.help) {
    helpMessage()
    exit 0
  }
  ch_sample_list = params.input != null ? Channel.fromPath(params.input) : errorMessage()
  //Flattening sample list so each sample is a separate channel and converting contents of that channel to a 3 item array
  ch_sample_list | flatMap{ it.readLines() } | map{ csv -> [csv.split(",")[0], csv.split(",")[1], csv.split(",")[2]] } | PEARRM
}
