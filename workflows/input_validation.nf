include { INPUT_VALIDATION_VCF } from '../modules/local/input_validation/input_validation_vcf'

workflow INPUT_VALIDATION {
    main:
    files = Channel.fromPath(params.files)

    INPUT_VALIDATION_VCF(files.collect())

    emit:
    validated_files = INPUT_VALIDATION_VCF.out.validated_files.collect()
    validation_report = INPUT_VALIDATION_VCF.out.validation_report
}
