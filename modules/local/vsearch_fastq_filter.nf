process VSEARCH_FASTQ_FILTER {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.21.1--h95f258a_0':
        'biocontainers/vsearch:2.21.1--h95f258a_0' }"

    input:
    tuple val(meta), path(merged_fastq)

    output:
    tuple val(meta), path('*.f*a')   , emit: fasta
    path "*.filtered.log"            , emit: log
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    vsearch \\
        --fastq_filter ${merged_fastq} \\
        --threads $task.cpus \\
        $args \\
        --fastaout ${prefix}.filtered.fasta 2>&1 | tee ${prefix}.filtered.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
    END_VERSIONS
    """
}
