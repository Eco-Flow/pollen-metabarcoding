process R_PROCESSING {
    tag "${meta.id}"
    label 'process_low'

    container = 'ecoflowucl/rocker-r_base:r-base-4.3.3_dplyr-1.1.4_hash'

    input:
    tuple val(meta), path(sintax_tsv)

    output:
    tuple val(meta), path('*.classified.tsv')   , emit: classification
    tuple val(meta), path('*.pdf')   , emit: pie
    tuple val(meta), path('summary.tsv')   , emit: summary_table

    script:
    """
    #Run the R script in \$projectDir/bin/r_processing.R
    r_processing.R ${sintax_tsv}
    """
}
