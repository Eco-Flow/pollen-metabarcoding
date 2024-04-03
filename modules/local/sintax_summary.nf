process USEARCH_SINTAX_SUMMARY {
    tag "${meta.id}"
    label 'process_low'

    container = 'quay.io/ecoflowucl/usearch:v11'

    input:
    tuple val(meta), path(tsv)

    //Only process files that have taxonomy predictions 
    when:
    tsv.size() > 0

    output:
    tuple val(meta), path('*.txt')   , optional: true, emit: txt
    path "versions.yml"              , emit: versions

    script:
    """
    #Summarise sintax results for each taxonomic level
    usearch -sintax_summary ${tsv} -output "${meta.id}_domain_summary.txt" -rank d

    usearch -sintax_summary ${tsv} -output "${meta.id}_kingdom_summary.txt" -rank k

    usearch -sintax_summary ${tsv} -output "${meta.id}_phylum_summary.txt" -rank p

    usearch -sintax_summary ${tsv} -output "${meta.id}_class_summary.txt" -rank c

    usearch -sintax_summary ${tsv} -output "${meta.id}_order_summary.txt" -rank o

    usearch -sintax_summary ${tsv} -output "${meta.id}_family_summary.txt" -rank f

    usearch -sintax_summary ${tsv} -output "${meta.id}_genus_summary.txt" -rank g

    usearch -sintax_summary ${tsv} -output "${meta.id}_species_summary.txt" -rank s

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        usearch: \$(usearch --version | cut -f 2 -d " ")
    END_VERSIONS
    """
}
