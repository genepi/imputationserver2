include { EAGLE } from '../modules/local/phasing/eagle'
include { BEAGLE } from '../modules/local/phasing/beagle'

workflow PHASING {

    take: 
    metafiles_ch 
    main:

    chromosomes = Channel.of(1..22, 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')

    if (params.phasing == 'eagle' && params.refpanel.refEagle != null) {

        phasing_map_ch = file(params.refpanel.mapEagle, checkIfExists: false)

        phasing_reference_ch = chromosomes
            .map {
                it -> tuple(
                    it.toString(),
                    file(PatternUtil.parse(params.refpanel.refEagle, [chr: it])),
                    file(PatternUtil.parse(params.refpanel.refEagle + ".csi", [chr: it]))
                )
            }

        eagle_bcf_metafiles_ch =  phasing_reference_ch.combine(metafiles_ch, by: 0)

        EAGLE ( eagle_bcf_metafiles_ch, phasing_map_ch )

        phased_ch = EAGLE.out.eagle_phased_ch

    }

    if (params.phasing == 'beagle' && params.refpanel.refBeagle != null) {

        phasing_reference_ch = chromosomes
            .map {
                it -> tuple(
                    it.toString(),
                    file(Patterns.parse(params.refpanel.refBeagle, [chr: it]))
                )
            }

        phasing_map_ch = chromosomes
            .map {
                it -> tuple(
                    it.toString(),
                    file(Patterns.parse(params.refpanel.mapBeagle, [chr: it]))
                )
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
