include { BRAKER3_SR       } from '../../modules/local/braker3sr'
include { ALIGN_ISOSEQ     } from '../../modules/local/alignisoseq'
include { BRAKER3_LR       } from '../../modules/local/braker3lr'
include { COMBINE_LRSR     } from '../../modules/local/combinelrsr'

workflow ANNOTATE {

    take:
    ch_samplesheet // channel: [ val(meta), path(assembly.fasta), path(fastq files), path(fastq.gz) ]
    
    main:

    ch_sr = ch_samplesheet.map { meta, fasta, folder, file -> [meta, fasta, folder] }
    ch_lr = ch_samplesheet.map { meta, fasta, folder, file -> [meta, fasta, file] }
    ch_genome = ch_samplesheet.map { meta, fasta, folder, file -> [meta, fasta] }
    ch_genome.view()
    ch_versions = Channel.empty()

    BRAKER3_SR ( ch_sr,
                 params.prot_seq,
                 params.busco_lineage,
                 params.species
    )
    ch_versions = ch_versions.mix(BRAKER3_SR.out.versions.first())

    ALIGN_ISOSEQ ( ch_lr )
    ch_versions = ch_versions.mix(ALIGN_ISOSEQ.out.versions.first())

    BRAKER3_LR ( ch_genome,
                 ALIGN_ISOSEQ.out.bam,
                 params.prot_seq,
                 params.busco_lineage,
                 params.species
    )

    COMBINE_LRSR ( BRAKER3_SR.out.gtf,
                   BRAKER3_LR.out.gtf,
                   BRAKER3_SR.out.hintsfile,
                   BRAKER3_LR.out.hintsfile,
                   ch_genome
    )

    emit:
    sr_bam      = BRAKER3_SR.out.bam              // channel: [ val(meta), [bam] ]
    gtf         = COMBINE_LRSR.out.gtf            // channel: [ val(meta), [ gtf ] ]
    cds         = COMBINE_LRSR.out.codingseq      // channel: [ val(meta), [ fasta ] ]
    amino_acids = COMBINE_LRSR.out.aa             // channel: [ val(meta), [ fasta ] ]
    versions    = ch_versions                     // channel: [ versions.yml ]
}

