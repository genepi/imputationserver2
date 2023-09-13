include { INPUT_VALIDATION } from '../modules/local/input_validation'

Channel
    .fromPath(params.files)
    .set {files}

workflow INPUT_VALIDATION_WF {
    
    main:
    INPUT_VALIDATION(files.collect())

    emit:
    INPUT_VALIDATION.out.validated_files.collect()

}


