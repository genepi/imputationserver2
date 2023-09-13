include { QUALITY_CONTROL          } from '../modules/local/quality_control'
include { QUALITY_CONTROL_REPORT   } from '../modules/local/quality_control_report'

workflow QC_WF {

    take:
    validated_files
    legend_files_ch
    
    main:
    
    QUALITY_CONTROL(
        validated_files,
        legend_files_ch
    )

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
