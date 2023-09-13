include { COMPRESSION_ENCRYPTION } from '../modules/local/compression_encryption'

workflow ENCRYPTION_WF {

    take: 
    imputed_chunks 

    main:
    COMPRESSION_ENCRYPTION (
      imputed_chunks 
    )

}

