if (params.refpanel_yaml){
    params.refpanel = RefPanelUtil.loadFromFile(params.refpanel_yaml)
}

include { QUALITY_CONTROL          } from '../modules/local/quality_control'
include { QUALITY_CONTROL_REPORT   } from '../modules/local/quality_control_report'

// Find legend files from full pattern and make legend file pattern relative
params.refpanel.legend_pattern = "${params.refpanel.legend}"
params.refpanel.legend = "./${file(params.refpanel.legend).fileName}"
legend_files_ch = Channel.from ( 1..22 )
        .map { it -> file(params.refpanel.legend_pattern.replaceAll('\\$chr', it.toString())) }

workflow QC_WF {

    take: validated_files
    main:
        QUALITY_CONTROL(validated_files, legend_files_ch.collect())

    if (params.population != "mixed") {
        QUALITY_CONTROL_REPORT(
            QUALITY_CONTROL.out.maf_file,
            file("$baseDir/files/qc-report.Rmd", checkIfExists: true)
        )
    }
    emit:
        chunks_vcf = QUALITY_CONTROL.out.chunks_vcf
        chunks_csv = QUALITY_CONTROL.out.chunks_csv

}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}
