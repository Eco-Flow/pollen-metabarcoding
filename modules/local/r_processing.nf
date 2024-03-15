process R_PROCESSING {
    tag "${meta.id}"
    label 'process_low'

    container = 'ecoflowucl/rocker-r_base:r-base-4.3.3'

    input:
    tuple val(meta), path(sintax_tsv)

    output:
    tuple val(meta), path('*.classified.tsv')   , emit: fasta
    path "versions.yml"                      , emit: versions

    script:
    """
    if [ ! -s ${sintax_tsv} ]; then
        echo "${sintax_tsv} has no sintax predictions" > "${meta.id}.classified.tsv"
    else
        Rscript ${projectDir}/bin/summarize_classification_sintax.R --input=${sintax_tsv} --output=${meta.id}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R version: \$(R --version | grep "R version" | sed 's/[(].*//' | sed 's/ //g' | sed 's/[^0-9]*//')
    END_VERSIONS
    """
}
