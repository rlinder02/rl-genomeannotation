process COMBINE_LRSR {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/teambraker/braker3:v3.0.7.5' :
        'docker.io/teambraker/braker3:v3.0.7.5' }"
    containerOptions = "--user root"

    input:
    tuple val(meta), path(sr_gtf, stageAs: 'sr_braker.gtf')
    tuple val(meta), path(lr_gtf, stageAs: 'lr_braker.gtf')
    tuple val(meta), path(sr_hint, stageAs: 'sr_hintsfile.gff')
    tuple val(meta), path(lr_hint, stageAs: 'lr_hintsfile.gff')
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.gff3")             , emit: gff3
    tuple val(meta), path("*renamed.gtf")       , emit: gtf
    tuple val(meta), path("*.codingseq")        , emit: codingseq
    tuple val(meta), path("*.aa")               , emit: aa
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.haplotype}"
    """
    tsebra.py \\
        -g $sr_gtf,$lr_gtf \\
        -e $sr_hint,$lr_hint \\
        -o tsebra.gtf \\
        $args
    getAnnoFastaFromJoingenes.py \\
        -g $assembly \\
        -o ${prefix} \\
        -f tsebra.gtf
    
    rename_gtf.py \\
        --gtf tsebra.gtf \\
        --out tsebra_renamed.gtf
    
    gtf2gff.pl < tsebra_renamed.gtf --out ${prefix}.gff3

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        combinelrsr: \$(tsebra.py --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        combinelrsr: \$(tsebra.py --version)
    END_VERSIONS
    """
}
