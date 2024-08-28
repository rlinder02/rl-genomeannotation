process OMARK {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/omark:0.3.0--pyh7cba7a3_0':
        'biocontainers/omark:0.3.0--pyh7cba7a3_0' }"
    containerOptions = "--user root"
    
    input:
    path(omamer_db)
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_omark_output")               , emit: omark_dir // need to emit each output separately to put into multiqc report
    tuple val(meta), path("*_omark_output/*.png")         , emit: png
    tuple val(meta), path("*_omark_output/*_summary.txt") , emit: summary
    path "versions.yml"                                   , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.haplotype}"
    """
    omark_splice_file.py "${fasta}"
    omamer search \\
        $args \\
        --db $omamer_db \\
        --query $fasta \\
        --out ${prefix}.omamer
    
    mkdir -p ${prefix}_omark_output
    omark \\
        $args \\
        -f ${prefix}.omamer \\
        -d $omamer_db \\
        --isoform_file isoforms.splice \\
        -o ${prefix}_omark_output

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        omark: \$(omark --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.haplotype}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        omark: \$(omark --version)
    END_VERSIONS
    """
}