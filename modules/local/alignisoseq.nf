process ALIGN_ISOSEQ {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::minimap2=2.28 bioconda::samtools=1.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/minimap2_samtools:7e38c0cfb1291cfb' :
        'community.wave.seqera.io/library/minimap2_samtools:7e38c0cfb1291cfb' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_${meta.haplotype}"
    """
    minimap2 \\
        $args \\
        -a \\
        -x splice:hq \\
        -uf \\
        -t $task.cpus \\
        $ref \\
        $scaffold \\
    | \\
    samtools \\
        view \\
        $args \\
        -bS \\
        --threads $task.cpus \\
        -o ${prefix}_isoseq.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alignisoseq: \$(minimap2 --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alignisoseq: \$(minimap2 --version)
    END_VERSIONS
    """
}
