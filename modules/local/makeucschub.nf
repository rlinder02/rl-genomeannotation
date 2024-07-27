process MAKE_UCSC_HUB {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/teambraker/braker3:v3.0.7.5' :
        'docker.io/teambraker/braker3:v3.0.7.5' }"
    containerOptions = "--user root"

    input:
    tuple val(meta), path(gtf)
    tuple val(meta), path(assembly)
    val(label)
    val(contact)
    
    output:
    tuple val(meta), path("${prefix}"), emit: ucsc_hub
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_${meta.haplotype}"
    """
    make_hub.py \\
        -l ${prefix} \\
        -L $label \\
        -g $assembly \\
        -e $contact \\
        -a $gtf \\
        $args 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        makeucschub: \$(make_hub.py --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        makeucschub: \$(make_hub.py --version)
    END_VERSIONS
    """
}
