include { COMPRESSION_ENCRYPTION_VCF } from '../modules/local/compression/compression_encryption_vcf'

workflow ENCRYPTION {

    take: 
    imputed_chunks 

    main:
    COMPRESSION_ENCRYPTION_VCF (
        imputed_chunks 
    )

}

