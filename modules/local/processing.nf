process PROCESSING {
    tag "${meta.id}"
    label 'process_low'

    container 'ecoflowucl/ubuntu-latest:18_03_24'

    input:
    tuple val(meta), path(sintax_tsv)

    output:
    tuple val(meta), path('*.classified.tsv')   , emit: fasta

    script:
    """
    if [ ! -s ${sintax_tsv} ]; then
        echo "${sintax_tsv} has no sintax predictions" > "${meta.id}.classified.tsv"
    else
        echo -e "sample\tkingdom\tprob_kingdom\tdivision\tprob_division\tclade\tprob_clade\torder\tprob_order\tfamily\tprob_family\tgenus\tprob_genus\tspecies\tprob_species\tsize" > "${meta.id}.classified.tsv"
        while read id size <&3 && read k p c o f g s <&4; do echo -e "\${id}\t\$(echo \${k} | sed 's/k://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${p} | sed 's/p://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${c} | sed 's/c://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${o} | sed 's/o://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${f} | sed 's/f://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${g} | sed 's/g://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${s} | sed 's/s://g' | sed 's/)//g' | tr "(" "\t")\t\$(echo \${size} | sed 's/size=//g')"; done 3< <(cut -f 1 ${sintax_tsv} | tr ";" "\t") 4< <(cut -f 2 ${sintax_tsv} | tr "," "\t") >> "${meta.id}.classified.tsv"
    fi
    md5sum "${meta.id}.classified.tsv" > "${meta.id}.classified.tsv.md5"
    """
}
