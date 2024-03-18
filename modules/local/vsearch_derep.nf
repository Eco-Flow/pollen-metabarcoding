process VSEARCH_DEREP_FULL_LENGTH {

    tag "${meta.id}"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.21.1--h95f258a_0':
        'biocontainers/vsearch:2.21.1--h95f258a_0' }"

    input:
    tuple val(meta), path(filtered_fasta)

    output:
    tuple val(meta), path('*.derep.fasta')   , emit: fasta
    tuple val(meta), path('*.derep.uc')      , emit: clustering
    path "*.derep.log"                       , emit: log
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    vsearch \\
        --derep_fulllength ${filtered_fasta} \\
        $args \\
        --relabel "${prefix}." \\
        --uc ${prefix}.derep.uc \\
        --output ${prefix}.derep.fasta 2>&1 | tee ${prefix}.derep.log

    md5sum "${prefix}.derep.fasta" > "${prefix}.derep.fasta.md5"
    md5sum "${prefix}.derep.uc" > "${prefix}.derep.uc.md5"

    cat <<-END_VERSIONS > versions.yml

    "${task.process}":
        vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
    END_VERSIONS
    """
}
