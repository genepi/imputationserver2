import groovy.json.JsonOutput

process INPUT_VALIDATION_VCF {
    label 'preprocessing'

    // Use publishDir to copy outputs to params.output with flatten: true
    publishDir "${params.output}/split_vcfs", mode: 'copy', pattern: 'split_vcfs/*.vcf.gz', flatten: true
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
        # Verify if VCF file is valid by attempting to index
        if ! output=\$(tabix -p vcf "\$vcf" 2>&1); then
            echo "::group type=error"
            echo "The provided VCF file is malformed."
            echo "Error: \$output"
            echo "::endgroup::"
            exit 1
        fi

        # Index the VCF file if not already indexed
        if [ ! -f "\$vcf.csi" ] && [ ! -f "\$vcf.tbi" ]; then
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

        # For each chromosome
        for chr in \$chromosomes; do
            # Extract, sort, compress, and index
            output_vcf="split_vcfs/\${base_name}_\${chr}.vcf.gz"
            bcftools view -r "\$chr" "\$vcf" | bcftools sort -Oz -o "\$output_vcf"
            tabix -p vcf "\$output_vcf"

            # Add the split VCF file to the array
            split_vcfs+=("\$output_vcf")
        done
    done

    # Now we can use the split_vcfs array
    echo "Validated VCF files:"
    printf '%s\n' "\${split_vcfs[@]}"

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
