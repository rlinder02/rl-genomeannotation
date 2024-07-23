include { MAKE_UCSC_HUB      } from '../../modules/local/makeucschub'
include { OMARK              } from '../../modules/local/omark'

workflow ANNOTATION_QC {

    take:
    ch_samplesheet
    ch_gtf                           // channel: [ val(meta), [ gtf ] ]
    ch_amino_acids                   // channel: [ val(meta), [ fasta ] ]
    ch_sr_bam                        // channel: [ val(meta), [ bam ] ]

    main:

    ch_genome = ch_samplesheet.map { meta, fasta, folder, file -> [meta, fasta] }
    ch_versions = Channel.empty()


    MAKE_UCSC_HUB ( ch_gff,
                    ch_genome,
                    ch_sr_bam,
                    params.label,
                    params.email
    )
    ch_versions = ch_versions.mix(MAKE_UCSC_HUB.out.versions.first())

    OMARK ( params.omamer_db,
            ch_amino_acids,
            ch_splice
    )
    ch_versions = ch_versions.mix(OMARK.out.versions.first())

    emit:
    ucsc_hub      = MAKE_UCSC_HUB.out.ucsc_hub          // channel: [ val(meta), [ bai ] ]
    csi           = SAMTOOLS_INDEX.out.csi              // channel: [ val(meta), [ csi ] ]
    versions = ch_versions                              // channel: [ versions.yml ]
}

