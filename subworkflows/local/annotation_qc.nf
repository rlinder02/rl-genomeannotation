include { MAKE_UCSC_HUB      } from '../../modules/local/makeucschub'
include { OMARK              } from '../../modules/local/omark'

workflow ANNOTATION_QC {

    take:
    ch_samplesheet
    ch_gtf                           // channel: [ val(meta), [ gtf ] ]
    ch_amino_acids                   // channel: [ val(meta), [ fasta ] ]

    main:

    ch_genome = ch_samplesheet.map { meta, fasta, folder, file -> [meta, fasta] }
    ch_versions = Channel.empty()


    MAKE_UCSC_HUB ( ch_gtf,
                    ch_genome,
                    params.label,
                    params.email
    )
    ch_versions = ch_versions.mix(MAKE_UCSC_HUB.out.versions.first())

    OMARK ( params.omamer_db,
            ch_amino_acids
    )
    ch_versions = ch_versions.mix(OMARK.out.versions.first())

    emit:
    ucsc_hub = MAKE_UCSC_HUB.out.ucsc_hub               // channel: [ val(meta), [ bai ] ]
    omark_qc = OMARK.out.omark_dir                      // channel: [ val(meta), path(dir)]
    omark_png = OMARK.out.png                   
    omark_summary = OMARK.out.summary
    versions = ch_versions                              // channel: [ versions.yml ]
}

