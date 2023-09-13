include { INPUT_VALIDATION_VCF } from '../modules/local/input_validation/input_validation_vcf'

Channel
    .fromPath(params.files)
    .set {files}

workflow INPUT_VALIDATION {
    
    main:
    INPUT_VALIDATION_VCF(files.collect())

    emit:
    validated_files = INPUT_VALIDATION_VCF.out.validated_files.collect()

}


