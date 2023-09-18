include { EAGLE } from '../modules/local/phasing/eagle'
include { BEAGLE } from '../modules/local/phasing/beagle'

workflow PHASING {

    take: 
        chunks_vcf 
        chunks_csv
        phasing_reference_ch
        phasing_map
    main:
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

    if ("${params.phasing}" == 'eagle') {

        eagle_bcf_metafiles_ch =  phasing_reference_ch.combine(metafiles_ch, by: 0)

        EAGLE ( eagle_bcf_metafiles_ch, phasing_map )

        phased_ch = EAGLE.out.eagle_phased_ch

    }

    if ("${params.phasing}" == 'beagle') {

        beagle_bcf_metafiles_ch = phasing_reference_ch.combine(metafiles_ch, by: 0)

        //combine with map since also split by chromsome
        beagle_bcf_metafiles_map_ch = beagle_bcf_metafiles_ch.combine(phasing_map, by: 0)

        BEAGLE ( beagle_bcf_metafiles_map_ch )

        phased_ch = BEAGLE.out.beagle_phased_ch

    }

    if ("${params.phasing}" == 'no_phasing') {

        
           metafiles_ch
                .map {it -> tuple(it[0],it[1],it[2],it[3],file(it[4])) }
                .set {phased_ch}

        phased_ch.view()

    }

    emit: phased_ch

}
