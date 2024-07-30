process BRAKER3_LR {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/teambraker/braker3:isoseq' :
        'docker.io/teambraker/braker3:isoseq' }"
    containerOptions = "--user root"

    input:
    tuple val(meta), path(assembly)
    tuple val(meta), path(bam)
    path(prot_db)
    val(busco)
    val(species)

    output:
    tuple val(meta), path("braker/braker.log")              , emit: log
    tuple val(meta), path("braker/braker.gtf")              , emit: gtf
    tuple val(meta), path("braker/braker.codingseq")        , emit: codingseq
    tuple val(meta), path("braker/braker.aa")               , emit: aa
    tuple val(meta), path("braker/hintsfile.gff")           , emit: hintsfile
    tuple val(meta), path("braker/braker.gff3")             , emit: gff3
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat /opt/BRAKER/scripts/braker_cleanup.pl | sed 's/0700/0777/g' > /opt/BRAKER/scripts/braker_cleanup.pl
    name=\$(basename $prot_db .gz)
    zcat $prot_db > \$name
    braker.pl \\
        --genome=$assembly \\
        --prot_seq=\$name \\
        --species=$species \\
        --gff3 \\
        --bam=$bam \\
        --threads $task.cpus \\
        --busco_lineage=$busco \\
        --makehub \\
        --email rlinder02@gmail.com \\
        $args
       
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        braker3lr: \$(braker.pl --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        braker3lr:\$(braker.pl --version)
    END_VERSIONS
    """
}
