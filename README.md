# nf-pollen-metabarcoding
A pipeline developed in collaboration with Exeter University

## Installation

Nextflow pipelines require a few prerequisites. There is further documentation on the nf-core webpage [here](https://nf-co.re/docs/usage/installation), about how to install Nextflow.

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) or [Singularity](https://docs.sylabs.io/guides/3.11/admin-guide/installation.html).
- [Java](https://www.java.com/en/download/help/download_options.html) and [openJDK](https://openjdk.org/install/) >= 8 (**Please Note:** When installing Java versions are `1.VERSION` so `Java 8` is `Java 1.8`).
- [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html) >= `v24.04.1`.

### Install

To install the pipeline please use the following commands but replace VERSION with a [release](https://github.com/Eco-Flow/pollen-metabarcoding/releases).

`wget https://github.com/Eco-Flow/pollen-metabarcoding/archive/refs/tags/VERSION.tar.gz -O - | tar -xvf -`

or

`curl -L https://github.com/Eco-Flow/pollen-metabarcoding/archive/refs/tags/VERSION.tar.gz --output - | tar -xvf -`

This will produce a directory in the current directory called `pollen-metabarcoding-VERSION` which contains the pipeline.

## Inputs

### Required

* `--input` - Path to a comma-separated file containing sample id and either path to the fastq(s) or an SRA ID. Each row contains information on a singular sample.
* `--database` - Path to database fasta file to be used in vsearch sintax module.
* `--outdir` - Path to the output directory where the results will be saved (you have to use absolute paths to storage on cloud infrastructure) **[default: results]**.  
* `--FW_primer` - Sequence of the forward primer.
* `--RV_primer` - Sequence of the reverse primer.

### Optional
* `--single_end` - Tells pipeline whether to expect single end or paired-end sra data **[default: false]**.
* `--custom_config` - A path/url to a custom configuration file.
* `--publish_dir_mode` - Method used to save pipeline results to output directory. (accepted: symlink, rellink, link, copy, copyNoFollow, move) **[default: copy]**. 
* `--clean` - Enable cleanup function **[default: true]**.
* `--forks` - Maximum number of each process that will be run in parallel.
* `--max_cpus` - Maximum number of CPUs that can be requested for any single job **[default: 16]**.
* `--max_memory` - Maximum amount of memory that can be requested for any single job **[default: 128.GB]**.
* `--max_time` - Maximum amount of time that can be requested for any single job **[default: 48.h]**.
* `--help` - Display help text.

#### Module parameters (check software docs for more details)
* `--cutadapt_min_overlap` - Cutadapt minimum overlap parameter **[default: 3]**.
* `--cutadapt_max_error_rate` - Cutadapt max error rate parameter **[default: 0.1]**.
* `--pacbio` - Cutadapt pacbio parameter.
* `--iontorrent` - Cutadapt iontorrent parameter.
* `--pear_p_value` - Pear p-value parameter.
* `--pear_min_overlap` - Pear min overlap parameter.
* `--pear_max_len` - Pear max length parameter.
* `--pear_min_len` - Pear min length parameter.
* `--pear_trimmed_min_len` - Pear trimmed min length parameter.
* `--pear_quality` - Pear quality score threshold parameter.
* `--pear_max_uncalled` - Pear percentage max uncalled parameter.
* `--pear_stat_test` - Pear statistical test parameter.
* `--pear_scoring_method` - Pear scoring method parameter.
* `--pear_phred` - Pear phred score threshold parameter.
* `--fastq_maxee` - vsearch fastq max expected errors parameter.
* `--fastq_minlen` - vsearch fastq min length parameter.
* `--fastq_maxns` - vsearch max Ns parameter.
* `--fasta_width` - vsearch fasta width parameter.
* `--minuniquesize` - vsearch min unique size parameter **[default: 2]**.
* `--derep_strand` - vsearch fastq dereplicate strand parameter.
* `--sintax_cutoff` - vsearch sintax cutoff parameter.
* `--sintax_strand` - vsearch sintax strand parameter.
* `--seed` - vsearch sinxtax random seed parameter **[default: 1312]**.
* `--ncbi_settings` - Path to NCBI settings folder.
* `--certificate` - Path to certificate file.

#### AWS parameters (ensure these match the infrastructure you have access to if using AWS)
* `--awsqueue` - aws queue to use with aws batch.
* `--awsregion` - aws region to use with aws batch.
* `--awscli` - path to aws cli installation on host instance.
* `--s3bucket` - s3 bucket path to use as work directory.


#### Creating a input sample sheet

In order to create an input sample sheet in the correct format, you can use the python script -> [here](https://github.com/Eco-Flow/pollen-metabarcoding/blob/main/bin/fastq_dir_to_samplesheet.py).

This has been edited from an [nf-core rnaseq](https://github.com/nf-core/rnaseq/blob/master/bin/fastq_dir_to_samplesheet.py) script.

You can use it when all your fastq files are in a single folder and end with `_R1_001.fastq.gz` and/or `_R2_001.fastq.gz`.

**Usage:**

`python3 fastq_dir_to_samplesheet.py /path/to/fastq/files Input.csv`

* Where `Input.csv` is the name of the file I want to name the samplesheet.

* And `/path/to/fastq/files` is the full path to the folder with your fastq data.

* If you have a variant ending to read 1 and read 2, you can specify endings with the `--read1_extension` and `--read2_extension` flags. Default is "_R1_001.fastq.gz".

## Results

Once completed, your output directory should be called results (unless you specified another name) and should contain the following directory structure:

```
results
├── cut_tsvs
├── cutadapt
│   ├── fastqs
│   └── logs
├── pear
│   ├── assembled
│   ├── discarded
│   └── unassembled
├── pipeline_info
│   ├── co2_emissions
│   │   ├── co2footprint_report.html
│   │   ├── co2footprint_summary.html
│   │   └── co2footprint_trace.txt
│   ├── execution_report.html
│   ├── execution_timeline.html
│   ├── execution_trace.txt
│   ├── pipeline_dag.html
│   └── software_versions.yml
├── r-processing
│   └── sample
│       ├── classified.tsv
│       ├── pie_charts
│       │   ├── family.pdf
│       │   ├── genus.pdf
│       │   └── order.pdf
│       └── summary.tsv
├── sratools_fasterq-dump
│   └── sample
├── usearch
│   └── sintax_summary
│       ├── sample
│           ├── class_summary.txt
│           ├── domain_summary.txt
│           ├── family_summary.txt
│           ├── genus_summary.txt
│           ├── kingdom_summary.txt
│           ├── order_summary.txt
│           ├── phylum_summary.txt
│           └── species_summary.txt
└── vsearch
    ├── derep
    │   ├── clusterings
    │   ├── fastas
    │   └── logs
    ├── fastq_filter
    │   ├── fastas
    │   └── logs
    └── sintax
```

`cut_tsvs` - directory containing tsvs of first 2 columns of sintax data

`cutadapt`
1. `fastqs` - directory containing adapter trimmed fastqs files for each sample.
2. `logs` - directory containing cutadapt trimming statistics for each sample.

`pear`
1. `assembled` - directory containing fastqs of successfully merged reads for each sample.
2. `discarded` - directory containing fastqs of reads disacrded due to quality for each sample.
3. `unassembled` - directory containing fastqs of reads unable to be merged for each sample.

`pipeline_info` - directory containing pipeline statistics including co2 emissions.

`r-processing`
1. `classfied.tsv` - tsv containing taxonomy prediction information.
2. `pie_charts` - pdfs of top predicted species for different taxonomic level
3. `summary.tsv` - tsv containing summary statistics.

`sratools_fasterq-dump` - fastqs obtained from SRA ID.

`usearch` - text files containing the name, number of reads, percentage of reads and cumulative percentage of reads for each taxonomic level.

`vsearch`
1. `derep`
  - `clusterings` - directory containing dereplicated clusterings for each sample.
  - `fastas` - directory containing dereplicated fastas for each sample.
  - `logs` - directory containing vsearch dereplicate statistics for each sample.
2. `fastq_filter`
  - `fastas` - directory containing filtered fastas for each sample.
  - `logs` - directory containing vsearch fastq_filter statistics for each sample.
3. `sintax` - directory containing vsearch sintax taxonomy prediction output files.

## Configuration

### Basics

The basic configuration of processes using labels can be found in `conf/base.config`.

Module specific configuration using process names can be found in `conf/modules.config`.

**Please note:** The nf-core `CUTADAPT` module is labelled as `process_medium` in the module `main.nf`. However for pollen metabarcoding data the fastqs are significantly smaller, so this resource requirement has been overwritten inside `conf/modules.config` to match the `process_single` resource requirments.

### Profiles

This pipeline is designed to run in various modes that can be supplied as a comma separated list i.e. `-profile profile1,profile2`.

#### Container Profiles

Please select one of the following profiles when running the pipeline.

* `docker` - This profile uses the container software Docker when running the pipeline. This container software requires root permissions so is used when running on cloud infrastructure or your local machine (depending on permissions). **Please Note:** You must have Docker installed to use this profile.
* `singularity` - This profile uses the container software Singularity when running the pipeline. This container software does not require root permissions so is used when running on on-premise HPCs or you local machine (depending on permissions). **Please Note:** You must have Singularity installed to use this profile.
* `apptainer` - This profile uses the container software Apptainer when running the pipeline. This container software does not require root permissions so is used when running on on-premise HPCs or you local machine (depending on permissions). **Please Note:** You must have Apptainer installed to use this profile.

#### Optional Profiles

* `aws_batch` - This profile is used if you are running the pipeline on AWS utilising the AWS Batch functionality. **Please Note:** You must use the `Docker` profile with with AWS Batch.
* `test` - This profile is used if you want to test running the pipeline on your infrastructure. **Please Note:** You do not provide any input parameters if this profile is selected but you still provide a container profile.

### Custom Configuration

If you want to run this pipeline on your institute's on-premise HPC or specific cloud infrastructure then please contact us and we will help you build and test a custom config file. This config file will be published to our [configs repository](https://github.com/Eco-Flow/configs).

## Running the Pipeline

**Please note:** The `-resume` flag uses previously cached successful runs of the pipeline.

* Running the pipeline with Docker profiles:
```
nextflow run main.nf -profile docker -resume --input data/input_full-s3.csv --database "s3://pollen-metabarcoding-test-data/data/viridiplantae_all_2014.sintax.fa" --FW_primer "ATGCGATACTTGGTGTGAAT" --RV_primer "GCATATCAATAAGCGGAGGA"
```

(The example database was obtained from [molbiodiv/meta-barcoding-dual-indexing](https://github.com/molbiodiv/meta-barcoding-dual-indexing/blob/master/precomputed/viridiplantae_all_2014.sintax.fa)).

The database should be a list of fasta sequences, where the header name contains kingdom (k),  phylum (p), c (class), o (order), f (family), g (genus) and s (species) identifiers (separated by comma). If your database does not contain all these definitions the pipeline will fail. We currently have a branch that will work with k (kindgom), called 'kingdom_fix'. To use this, clone the repo with the `--branch kingdom_fix` flag.
 

* Running the pipeline with Singularity and test profiles:
```
nextflow run main.nf -profile singularity,test_small -resume
```

* Running the pipeline with additional parameters:
```
nextflow run main.nf -profile apptainer -resume \
   --input data/input_small-s3.csv \
   --database "s3://pollen-metabarcoding-test-data/data/viridiplantae_all_2014.sintax.fa" \
   --FW_primer "ATGCGATACTTGGTGTGAAT" --RV_primer "GCATATCAATAAGCGGAGGA" \
   --clean false \
   --fastq_maxee 0.5 --fastq_minlen 250 --fastq_maxns 0 --fasta_width 0 \
   --derep_strand "plus" \
   --sintax_strand "both" --sintax_cutoff 0.95
```

* Running the pipeline with a custom config file:
```
nextflow run main.nf -profile docker,aws_batch -resume --input data/input_manual.csv --database "s3://pollen-metabarcoding-test-data/data/viridiplantae_all_2014.sintax.fa" --FW_primer "ATGCGATACTTGGTGTGAAT" --RV_primer "GCATATCAATAAGCGGAGGA" --custom_config /path/to/custom/config
```

* Running on Gitpod:
If you wish to run on Gitpod, please be aware that the usearch (sintax_summary) module will fail, as Gitpod doesn't allow 32bit programs.
```
nextflow run main.nf -profile docker,test_small -resume --gitpod
```

## Test Data 
The data used to test this pipeline via the [ENA ID: PRJEB26439](http://www.ebi.ac.uk/ena/data/view/PRJEB26439).
There are two test profiles using this data:
`test_small` - contains 3 samples for small, fast testing.
`test_full` - contains 47 samples (the entire dataset) for large, real-world replication testing.

## Contact Us

If you need any support do not hesitate to contact us at any of:

`simon.murray [at] ucl.ac.uk`

`c.wyatt [at] ucl.ac.uk`

`ecoflow.ucl [at] gmail.com`
