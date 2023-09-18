include { NO_PHASING } from '../modules/local/phasing/no_phasing'
include { EAGLE } from '../modules/local/phasing/eagle'
include { BEAGLE } from '../modules/local/phasing/beagle'

workflow PHASING {

    take: 
        chunks_vcf 
        chunks_csv
        phasing_reference_ch
        phasing_map
    main:
    //TODO move to imputationserver workflow?
    chunks_vcf
        .flatten()
        .map { it -> tuple(file(it).baseName, it) }
        .set{ chunks_vcf_index }

    chunks_csv
        .flatten()
        .splitCsv(header:false, sep:'\t')
        .map{ 
            row-> tuple(file(row[4]).baseName, row[0], row[1], row[2], row[3], row[4], row[5], row[6])
        }
        .set { chunks_csv_index }

    chunks_csv_index
        .combine(chunks_vcf_index, by: 0)
        .map{
            row-> tuple(row[1], row[2], row[3], row[4], file(row[8]), row[6], row[7])
        }
        .set { metafiles_ch }

    //TODO: read from Dockerfile
    // check for '' required for testPipelineWithPhasedAndEmptyPhasing. Test case could be deleted since phasing is never '' anymore
    if ("${params.phasing}" == 'eagle' || "${params.phasing}" == '') {
        phasing_method = params.eagle_version
    } else if ("${params.phasing}" == 'beagle') {
        phasing_method = params.beagle_version
    } else if ("${params.phasing}" == 'no_phasing') {
        phasing_method = "n/a"
    }

    // check for '' required for testPipelineWithPhasedAndEmptyPhasing. Test case could be deleted since phasing is never '' anymore
    if ("${params.phasing}" == 'eagle'  || "${params.phasing}" == '') {

        eagle_bcf_metafiles_ch =  phasing_reference_ch.combine(metafiles_ch, by: 0)

        EAGLE ( eagle_bcf_metafiles_ch, phasing_map, phasing_method )

        phased_ch = EAGLE.out.eagle_phased_ch

    }

    if ("${params.phasing}" == 'beagle') {

        beagle_bcf_metafiles_ch = phasing_reference_ch.combine(metafiles_ch, by: 0)

        //combine with map since also split by chromsome
        beagle_bcf_metafiles_map_ch = beagle_bcf_metafiles_ch.combine(phasing_map, by: 0)

        BEAGLE ( beagle_bcf_metafiles_map_ch, phasing_method )

        phased_ch = BEAGLE.out.beagle_phased_ch

    }

    if ("${params.phasing}" == 'no_phasing') {

        NO_PHASING (metafiles_ch)

        phased_ch = NO_PHASING.out.skipped_phasing_ch

    }

    emit: phased_ch

}
