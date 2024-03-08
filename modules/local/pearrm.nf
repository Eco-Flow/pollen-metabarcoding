process PEARRM {

    label 'process_single'
    tag "$sample_id"
    container = 'ecoflowucl/pearrm:pearrm-v0.9.11_Linux_x86_64'
    publishDir "$params.outdir/merged_fastqs" , mode: "${params.publish_dir_mode}", pattern: "*_merged.assembled.fastq.gz"

    input:
    tuple val(sample_id), path(fq1), path(fq2)

    output:
    tuple val(sample_id), path("${sample_id}_merged.assembled.fastq.gz"), emit: merged_fastq
    path "versions.yml", emit: versions

    script:
    """
    pear -j $task.cpus -f $fq1 -r $fq2 -o "${sample_id}_merged"
    gzip "${sample_id}_merged.assembled.fastq"
    
    md5sum "${sample_id}_merged.assembled.fastq.gz" > "${sample_id}_merged.assembled.fastq.md5"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pear version: \$(pear --version)
    END_VERSIONS
    """
}
