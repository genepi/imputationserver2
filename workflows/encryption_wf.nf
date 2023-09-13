if (params.refpanel_yaml){
    params.refpanel = RefPanelUtil.loadFromFile(params.refpanel_yaml)
}

include { COMPRESSION_ENCRYPTION } from '../modules/local/compression_encryption'

workflow ENCRYPTION_WF {

    take: 
        imputed_chunks 
    main:

    COMPRESSION_ENCRYPTION (
      imputed_chunks 
    )

}

workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}


