include { QUALITY_CONTROL_VCF      } from '../modules/local/quality_control_vcf'
include { QUALITY_CONTROL_REPORT   } from '../modules/local/quality_control_report'

workflow QUALITY_CONTROL {

    take:
    validated_files
    legend_files_ch
    
    main:
    
    QUALITY_CONTROL_VCF(
        validated_files,
        legend_files_ch
    )

    if (params.population != "mixed") {
        QUALITY_CONTROL_REPORT(
            QUALITY_CONTROL_VCF.out.maf_file,
            file("$baseDir/files/qc-report.Rmd", checkIfExists: true)
        )
    }

    emit:
        chunks_vcf = QUALITY_CONTROL_VCF.out.chunks_vcf
        chunks_csv = QUALITY_CONTROL_VCF.out.chunks_csv

}
