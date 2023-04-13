if (params.refpanel_yaml){
    params.refpanel = RefPanelUtil.loadFromFile(params.refpanel_yaml)
    println params.refpanel
}

requiredParams = [
    'project', 'files', 'output', 'hdfs', 'reference_build', 'refpanel'
]

for (param in requiredParams) {
    if (params[param] == null) {
      exit 1, "Parameter ${param} is required."
    }
}

//TODO: check output, refpanel, population, ....

include { INPUT_VALIDATION         } from '../modules/local/input_validation'
include { QUALITY_CONTROL          } from '../modules/local/quality_control'
include { QUALITY_CONTROL_REPORT   } from '../modules/local/quality_control_report'
include { NO_PHASING               } from '../modules/local/no_phasing'
include { PHASING_EAGLE            } from '../modules/local/phasing_eagle'
include { PHASING_BEAGLE           } from '../modules/local/phasing_beagle'
include { IMPUTATION               } from '../modules/local/imputation'
include { COMPRESSION_ENCRYPTION   } from '../modules/local/compression_encryption'


Channel
    .fromPath(params.files)
    .set {files}

// Find legend files from full pattern and make legend file pattern relative
params.refpanel.legend_pattern = "${params.refpanel.legend}"
params.refpanel.legend = "./${file(params.refpanel.legend).fileName}"
legend_files_ch = Channel.from ( 1..22 )
        .map { it -> file(params.refpanel.legend_pattern.replaceAll('\\$chr', it.toString())) }

workflow IMPUTATIONSERVER2 {

    INPUT_VALIDATION(
        files.collect()
    )

    QUALITY_CONTROL(
        INPUT_VALIDATION.out.validated_files.collect(),
        legend_files_ch.collect()
    )

    if (params.population != "mixed") {
        QUALITY_CONTROL_REPORT(
            QUALITY_CONTROL.out.maf_file,
            file("$baseDir/files/qc-report.Rmd")
        )
    }

    QUALITY_CONTROL.out.chunks_vcf
        .flatten()
        .map { it -> tuple(file(it).baseName, it) }
        .set{ chunks_vcf_index }

    QUALITY_CONTROL.out.chunks_csv
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


    if ("${params.refEagle}" != null) {

        autosomes_eagle_ch =  Channel.from ( 1..22)
        .map { it -> tuple(it.toString(), file("$params.refEagle".replaceAll('\\$chr', it.toString())),file("$params.refEagle".replaceAll('\\$chr', it.toString())+'.csi')) }

        non_autosomes_eagle_ch =  Channel.from ( 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
        .map { it -> tuple(it.toString(), file("$params.refEagle".replaceAll('\\$chr', it.toString())),file("$params.refEagle".replaceAll('\\$chr', it.toString())+'.csi')) }

        eagle_bcf_ch = autosomes_eagle_ch.concat(non_autosomes_eagle_ch)

    }

    if ("${params.refBeagle}" != null) {

        autosomes_beagle_ch = Channel.from ( 1..22 )
        .map { it -> tuple(it.toString(), file("$params.refBeagle".replaceAll('\\$chr', it.toString()))) }

        non_autosomes_beagle_ch = Channel.from ( 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
        .map { it -> tuple(it.toString(), file("$params.refBeagle".replaceAll('\\$chr', it.toString()))) }

        beagle_bcf_ch = autosomes_beagle_ch.concat(non_autosomes_beagle_ch)

        autosomes_beagle_map_ch = Channel.from ( 1..22 )
        .map { it -> tuple(it.toString(), file("$params.mapBeagle".replaceAll('\\$chr', it.toString()))) }

        non_autosomes_beagle_map_ch = Channel.from (  'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT' )
        .map { it -> tuple(it.toString(), file("$params.mapBeagle".replaceAll('\\$chr', it.toString()))) }

        beagle_map_ch = autosomes_beagle_map_ch.concat(non_autosomes_beagle_map_ch)
    }

    autosomes_m3vcf_ch = Channel.from ( 1..22 )
        .map { it -> tuple(it.toString(), file("$params.hdfs".replaceAll('\\$chr', it.toString()))) }

    non_autosomes_m3vcf_ch = Channel.from ( 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
        .map { it -> tuple(it.toString(), file("$params.hdfs".replaceAll('\\$chr', it.toString()))) }

    minimac_m3vcf_ch = autosomes_m3vcf_ch.concat(non_autosomes_m3vcf_ch)

    //TODO: read from Dockerfile
    // check for '' required for testPipelineWithPhasedAndEmptyPhasing. Test case could be deleted since phasing is never '' anymore
    if ("${params.phasing}" == 'eagle' || "${params.phasing}" == '') {
    phasing_method = params.eagle_version
    }
    else if ("${params.phasing}" == 'beagle') {
    phasing_method = params.beagle_version
    }
    else if ("${params.phasing}" == 'no_phasing') {
    phasing_method = "n/a"
    }

    map_eagle   = file(params.mapEagle, checkIfExists: false)
    map_beagle  = file(params.mapBeagle, checkIfExists: false)
    minimac_map = file(params.mapMinimac, checkIfExists: false)


    // check for '' required for testPipelineWithPhasedAndEmptyPhasing. Test case could be deleted since phasing is never '' anymore
    if ("${params.phasing}" == 'eagle'  || "${params.phasing}" == '') {

     eagle_bcf_metafiles_ch =  eagle_bcf_ch.combine(metafiles_ch, by: 0)

     PHASING_EAGLE ( eagle_bcf_metafiles_ch, map_eagle, phasing_method )

     phased_m3vcf_ch = PHASING_EAGLE.out.eagle_phased_ch.combine(minimac_m3vcf_ch, by: 0)

    }

    if ("${params.phasing}" == 'beagle') {

     beagle_bcf_metafiles_ch = beagle_bcf_ch.combine(metafiles_ch, by: 0)

     //combine with map since also split by chromsome
     beagle_bcf_metafiles_map_ch = beagle_bcf_metafiles_ch.combine(beagle_map_ch, by: 0)

     PHASING_BEAGLE ( beagle_bcf_metafiles_map_ch, phasing_method )

     phased_m3vcf_ch = PHASING_BEAGLE.out.beagle_phased_ch.combine(minimac_m3vcf_ch, by: 0)

    }

    if ("${params.phasing}" == 'no_phasing') {

     NO_PHASING (metafiles_ch)

     phased_m3vcf_ch = NO_PHASING.out.skipped_phasing_ch.combine(minimac_m3vcf_ch, by: 0)

    }

    if ("${params.mode}" == 'imputation') {

      IMPUTATION ( phased_m3vcf_ch, minimac_map, phasing_method )

      COMPRESSION_ENCRYPTION(
        IMPUTATION.out.imputed_chunks.groupTuple()
      )

    } else {

        //TODO: run compression_encryption with results from phansing, when mode=='phasing'

    }

}


workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
