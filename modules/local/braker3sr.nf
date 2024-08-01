process BRAKER3_SR {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://docker.io/teambraker/braker3:v3.0.7.5' :
        'docker.io/teambraker/braker3:v3.0.7.5' }"
    containerOptions = "--user root"

    input:
    tuple val(meta), path(assembly), path(sr_rna)  
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
    name=\$(basename $prot_db .gz)
    zcat $prot_db > \$name
    braker.pl \\
        --genome=$assembly \\
        --prot_seq=\$name \\
        --species=$species \\
        --gff3 \\
        --rnaseq_sets_ids=${meta.id} \\
        --rnaseq_sets_dirs=$sr_rna \\
        --threads $task.cpus \\
        --busco_lineage=$busco \\
        --makehub \\
        --email rlinder@sbpdiscovery.org \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        braker3sr: \$(braker.pl --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        braker3sr: \$(braker.pl --version)
    END_VERSIONS
    """
}
