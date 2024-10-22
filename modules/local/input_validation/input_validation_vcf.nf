import groovy.json.JsonOutput

process INPUT_VALIDATION_VCF {
    label 'preprocessing'

    publishDir "${params.output}", mode: 'copy', pattern: 'validation_report.txt'

    input:
    path vcf_files

    output:
    path("split_vcfs/*.vcf.gz"), emit: validated_files
    path("validation_report.txt"), emit: validation_report

    script:
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[INPUT_VALIDATION_VCF] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega * 0.8).intValue()
    }

    // Prepare contact information
    def contactName = params.service.contact ?: 'Admin'
    def contactEmail = params.service.email ?: 'admin@localhost'

    // Convert refpanel to JSON string without variable expansion
    def refpanel_json = JsonOutput.toJson(params.refpanel)

    """
    set +e

    # Write reference panel JSON to file without variable expansion
    cat <<'EOF' > reference-panel.json
${refpanel_json}
EOF

    # Initialize an array to hold split VCF files
    split_vcfs=()

    # Create the directory for split VCF files
    mkdir -p split_vcfs

    # Process each VCF file
    for vcf in ${vcf_files}; do
        echo "Processing VCF file: \$vcf"

        # Determine if the VCF file is compressed
        if [[ "\$vcf" == *.gz ]]; then
            compressed_vcf="\$vcf"
            echo "File is compressed: \$compressed_vcf"
        else
            # Compress the VCF file using bgzip
            compressed_vcf="\$vcf.gz"
            echo "File is uncompressed. Compressing to: \$compressed_vcf"
            bgzip -i "\$vcf"
            # Replace the original VCF with the compressed one for further processing
            vcf="\$compressed_vcf"
        fi

        # Sort the VCF file using bcftools
        echo "Sorting VCF file: \$vcf"
        bcftools sort -Oz -o "\$vcf" "\$vcf"

        # Index the VCF file if not already indexed
        if [ ! -f "\$vcf.csi" ] && [ ! -f "\$vcf.tbi" ]; then
            echo "Indexing VCF file: \$vcf"
            bcftools index -f "\$vcf"
        fi

        # Get the list of chromosomes using tabix
        chromosomes=\$(tabix -l "\$vcf")

        # Get base name without extension
        base_name=\$(basename "\$vcf")
        base_name=\${base_name%.vcf.gz}
        base_name=\${base_name%.vcf}

        # Determine if 'chr' prefix needs to be added or removed
        if [ "${params.build}" = "hg19" ]; then
            # For hg19, remove 'chr' prefixes if present
            first_chr=\$(echo "\$chromosomes" | head -n1)
            if [[ "\$first_chr" == chr* ]]; then
                echo "Chromosome names have 'chr' prefix. Removing prefixes for hg19."

                # Create a temporary chromosome mapping file
                echo "\$chromosomes" | awk '{print \$0"\t"substr(\$0,4)}' > chr_map.txt

                # Remove 'chr' prefix using bcftools annotate
                bcftools annotate --rename-chrs chr_map.txt "\$vcf" -Oz -o "\$vcf.tmp.gz"
                mv "\$vcf.tmp.gz" "\$vcf"
                tabix -f -p vcf "\$vcf"
                rm chr_map.txt
                # Update chromosomes variable
                chromosomes=\$(tabix -l "\$vcf")
            fi
        elif [ "${params.build}" = "hg38" ]; then
            # For hg38, add 'chr' prefixes if not present
            first_chr=\$(echo "\$chromosomes" | head -n1)
            if [[ "\$first_chr" != chr* ]]; then
                echo "Chromosome names lack 'chr' prefix. Adding prefixes for hg38."

                # Create a temporary chromosome mapping file
                echo "\$chromosomes" | awk '{print \$0"\tchr"\$0}' > chr_map.txt

                # Add 'chr' prefix using bcftools annotate
                bcftools annotate --rename-chrs chr_map.txt "\$vcf" -Oz -o "\$vcf.tmp.gz"
                mv "\$vcf.tmp.gz" "\$vcf"
                tabix -f -p vcf "\$vcf"
                rm chr_map.txt
                # Update chromosomes variable
                chromosomes=\$(tabix -l "\$vcf")
            fi
        fi

        # Count the number of chromosomes
        num_chromosomes=\$(echo "\$chromosomes" | wc -l)
        echo "Number of chromosomes in \$vcf: \$num_chromosomes"

        if [ "\$num_chromosomes" -eq 1 ]; then
            # Only one chromosome, skip splitting and sorting
            echo "Only one chromosome detected (\$chromosomes). Skipping split and sort."
            output_vcf="split_vcfs/\${base_name}.vcf.gz"
            cp "\$vcf" "\$output_vcf"
            # Index the output VCF if necessary
            if [ ! -f "\$output_vcf.csi" ] && [ ! -f "\$output_vcf.tbi" ]; then
                echo "Indexing output VCF: \$output_vcf"
                tabix -p vcf "\$output_vcf"
            fi
            # Add the VCF file to the array
            split_vcfs+=("\$output_vcf")
        else
            # For each chromosome, extract, sort, compress, and index
            for chr in \$chromosomes; do
                echo "Splitting chromosome: \$chr from \$vcf"
                output_vcf="split_vcfs/\${base_name}_\${chr}.vcf.gz"
                bcftools view -r "\$chr" "\$vcf" | bcftools sort -Oz -o "\$output_vcf"
                tabix -p vcf "\$output_vcf"

                # Add the split VCF file to the array
                split_vcfs+=("\$output_vcf")
            done
        fi
    done

    # Now we can use the split_vcfs array
    echo "Validated VCF files:"
    printf '%s\\n' "\${split_vcfs[@]}"

    # Run the validation program
    java -Xmx${avail_mem}M -jar /opt/imputationserver-utils/imputationserver-utils.jar \\
        validate \\
        --population ${params.population} \\
        --phasing ${params.phasing.engine} \\
        --reference reference-panel.json \\
        --build ${params.build} \\
        --mode ${params.mode} \\
        --minSamples ${params.min_samples} \\
        --maxSamples ${params.max_samples} \\
        --report validation_report.txt \\
        --no-index \\
        --contactName "${contactName}" \\
        --contactEmail "${contactEmail}" \\
        "\${split_vcfs[@]}"
    exit_code_a=\$?

    cat validation_report.txt
    exit \$exit_code_a
    """
}
