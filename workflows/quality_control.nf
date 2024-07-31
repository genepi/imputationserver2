include { QUALITY_CONTROL_VCF } from '../modules/local/quality_control/quality_control_vcf'
include { QUALITY_CONTROL_REPORT } from '../modules/local/quality_control/quality_control_report'

workflow QUALITY_CONTROL {

    take:
    validated_files
    validation_report
    site_files_ch
    
    main:

    def chain_file = []
    def panel_version = params.refpanel.build
    if(!panel_version.equals(params.build)) {
        def name = params.build + "To" + panel_version + ".over.chain.gz"
        chain_file = file("$projectDir/files/chains/" + name, checkIfExists: true)
    } 

    QUALITY_CONTROL_VCF(
        validated_files,
        site_files_ch,
        chain_file,
        panel_version
    )

    QUALITY_CONTROL_VCF.out.chunks_vcf
        .flatten()
        .map { it -> tuple(file(it).baseName, it) }
        .set{ chunks_vcf_index }

    QUALITY_CONTROL_VCF.out.chunks_csv
        .flatten()
        .splitCsv(header:false, sep:'\t')
        .map{ 
            row-> tuple(file(row[4]).baseName, row[0], row[1], row[2], row[3], row[4], row[5], row[6])
        }
        .set { chunks_csv_index }

    chunks_csv_index
        .combine(chunks_vcf_index, by: 0)
        .map{
            row-> tuple(row[1], row[2], row[3], row[4], file(row[8]))
        }
        .set { metafiles_ch }


    QUALITY_CONTROL_REPORT(
        QUALITY_CONTROL_VCF.out.maf_file.ifEmpty([]),
        validation_report,
        QUALITY_CONTROL_VCF.out.qc_report,
        file("$baseDir/files/qc-report.Rmd", checkIfExists: true)
    )

    emit:
    qc_metafiles = metafiles_ch

}
