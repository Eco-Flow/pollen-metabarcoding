process CUTTING {
    tag "${meta.id}"
    label 'process_low'

    container = 'quay.io/ecoflowucl/ubuntu:jammy-20240227'

    input:
    tuple val(meta), path(tsv)

    //Only process files that have taxonomy predictions 
    when:
    tsv.size() > 0

    output:
    tuple val(meta), path('cut.*.tsv')   , optional: true, emit: tsv

    script:
    """
    cut -f 1,2 ${tsv} > "cut.${meta.id}.tsv"
    """
}
