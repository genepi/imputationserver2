if (params.refpanel_yaml){
    params.refpanel = RefPanelUtil.loadFromFile(params.refpanel_yaml)
    println params.refpanel
}

requiredParams = [
    'project', 'files', 'output', 'refpanel'
]

for (param in requiredParams) {
    if (params[param] == null) {
      exit 1, "Parameter ${param} is required."
    }
}

//TODO: check output, refpanel, population, ....

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


workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}


