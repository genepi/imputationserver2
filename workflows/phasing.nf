include { EAGLE } from '../modules/local/phasing/eagle'
include { BEAGLE } from '../modules/local/phasing/beagle'

workflow PHASING {

    take: 
    metafiles_ch 
    main:

    chromosomes = Channel.of(1..22, 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')

    if (params.phasing.engine == 'eagle' && params.refpanel.refEagle != null) {

        phasing_map_ch = file(params.refpanel.mapEagle, checkIfExists: true)

        phasing_reference_ch = chromosomes
            .map {
                it -> 
                    def eagle_file = file(PatternUtil.parse(params.refpanel.refEagle, [chr: it]))
                    def eagle_file_index = file(PatternUtil.parse(params.refpanel.refEagle + ".csi", [chr: it]))
                    if(!eagle_file.exists() || !eagle_file_index.exists()){
                        return null;
                    }
                    return tuple(it.toString(),eagle_file,eagle_file_index)
            }

        eagle_bcf_metafiles_ch = phasing_reference_ch.combine(metafiles_ch, by: 0)

        EAGLE ( eagle_bcf_metafiles_ch, phasing_map_ch )

        phased_ch = EAGLE.out.eagle_phased_ch

    }

    if (params.phasing.engine == 'beagle' && params.refpanel.refBeagle != null) {

        phasing_reference_ch = chromosomes
            .map {
                it -> 
                    def beagle_file = file(PatternUtil.parse(params.refpanel.refBeagle, [chr: it]))
                    if(!beagle_file.exists()){
                        return null;
                    }
                    return tuple(it.toString(),beagle_file)
            }

        phasing_map_ch = chromosomes
            .map {
                it ->
                    def beagle_map_file = file(PatternUtil.parse(params.refpanel.mapBeagle, [chr: it]))
                    if(!beagle_map_file.exists()){
                        return null;
                    }
                    return tuple(it.toString(),beagle_map_file)
            }

        beagle_bcf_metafiles_ch = phasing_reference_ch.combine(metafiles_ch, by: 0)

        //combine with map since also split by chromsome
        beagle_bcf_metafiles_map_ch = beagle_bcf_metafiles_ch.combine(phasing_map_ch, by: 0)

        BEAGLE ( beagle_bcf_metafiles_map_ch )

        phased_ch = BEAGLE.out.beagle_phased_ch

    }

    emit: 
    phased_ch

}
