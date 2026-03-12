---
hide:
  - navigation
  - toc 
---

# Imputation Server 2

[![imputationserver2](https://github.com/genepi/imputationserver2/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/imputationserver2/actions/workflows/ci-tests.yml)
[![nf-test](https://img.shields.io/badge/tested_with-nf--test-337ab7.svg)](https://github.com/askimed/nf-test)

This repository includes the Imputation Server 2 Nextflow workflow.

## Run with test data

The pipeline provides small test data to verify installation:

```
nextflow run main.nf -c conf/test_single_vcf.config
```

## Run with custom configuration

`job.config`:

```
params {
    project                 = "my-test-project"
    build                   = "hg19"
    files                   = "tests/data/input/three/*.vcf.gz"
    allele_frequency_population              = "eur"
    mode                    = "imputation"
    refpanel_yaml           = "tests/hapmap-2/2.0.0/imputation-hapmap2.yaml"
    output                  = "output"
}
```

Run pipeline with `job.config` configuration:

```
nextflow run main.nf -c job.config
```

## Parameters

| Parameter             | Default Value         | Description                                        |
| --------------------- | --------------------- | -------------------------------------------------- |
| `project`             | `null`                | Project name                                       |
| `project_date`        | `date`                | Project date                                       |
| `files`               | `null`                | List of input files                                |
| `allele_frequency_population`          | `null`                | Allele Frequency Population information                             |
| `refpanel_yaml`       | `null`                | Reference panel YAML file                          |
| `mode`                | `imputation`          | Processing mode (e.g., 'imputation' or `qc-only``) |
| `chunksize`           | `20000000`            | Chunk size for processing                          |
| `min_samples`         | `20`                  | Minimum number of samples needed                   |
| `max_samples`         | `50000`               | Maximum number of samples allowed                  |
| `merge_samples`       | `true`                | Execute compression and encryption workflow        |
| `password`            | `null`                | Password for encryption                            |
| `send_mail`           | `false`               | Enable or disable email notifications              |
| `service.name`        | `Imputation Server 2` | Service name                                       |
| `service.email`       | `null`                | Service email                                      |
| `service.url`         | `null`                | Service URL                                        |
| `user.name`           | `null`                | User's name                                        |
| `user.email`          | `null`                | User's email                                       |
| `phasing.engine`      | `eagle`               | Phasing method (e.g., 'eagle' or `beagle`)         |
| `phasing.window`      | `5000000`             | Phasing window size                                |
| `imputation.enabled`  | `true`                | Enable or disable imputation                       |
| `imputation.window`   | `500000`              | Imputation window size                             |
| `imputation.minimac_min_ratio`   | `0.00001`  | Minimac minimum ratio                              |
| `imputation.min_r2`   | `0`                   | R2 filter value                                    |
| `imputation.meta`     | `false`               | Enable or disable empirical output creation        |
| `imputation.md5`      | `false`               | Enable or disable md5 sum creation for results     |
| `imputation.create_index`    | `false`        | Enable or disable index creation for imputed files |
| `imputation.decay`    | `0`                   | Set minimac decay                                  |
| `encryption.enabled`  | `true`                | Enable or disable encryption                       |
| `encryption.aes`      | `false`               | Enable or disable AES method for encryption        |
| `ancestry.enabled`    | `false`               | Enable or disable ancestry analysis                |
| `ancestry.dim`        | `10`                  | Ancestry analysis dimension                        |
| `ancestry.dim_high`   | `20`                  | High dimension for ancestry analysis               |
| `ancestry.batch_size` | `50`                  | Batch size for ancestry analysis                   |
| `ancestry.reference`  | `null`                | Ancestry reference data                            |
| `ancestry.max_pcs`    | `8`                   | Maximum principal components for ancestry          |
| `ancestry.k`          | `10`                  | K value for ancestry analysis                      |
| `ancestry.threshold`  | `0.75`                | Ancestry threshold                                 |




## Reference Panel Configuration

This document describes the structure of a YAML file used to configure a reference panel for Imputation Servers. Reference panels are essential for genotype imputation, allowing the server to infer missing genotype data accurately.

### YAML Structure

| Field         | Description                                                                     |
| ------------- | ------------------------------------------------------------------------------- |
| `name`        | The name of the reference panel.                                                |
| `description` | A brief description of the reference panel.                                     |
| `version`     | The version of the reference panel.                                             |
| `website`     | The website where more information about the panel can be found.                |
| `category`    | The category to which the reference panel belongs. **TODO: has to be RefPanel** |
| `properties`  | A section containing specific properties of the reference panel.                |

#### Properties

The `properties` section contains the following key-value pairs:

| Property      | Description                                                                 | Required |
| ------------- | --------------------------------------------------------------------------- | -------- |
| `id`          | An identifier for the reference panel.                                      | yes      |
| `genotypes`   | The location of the genotype files for the reference panel data.            | yes      |
| `sites`      | The location of the site files for the reference panel data.                 | yes      |
| `mapEagle`    | The location of the genetic map file used for phasing with eagle.           | yes      |
| `refEagle`    | The location of the BCF file for the reference panel data for eagle.        | yes      |
| `mapBeagle`   | The location of the genetic map file used for phasing with Beagle.          | no       |
| `refBeagle`   | The location of the BCF file for the reference panel data for Beagle.       | no       |
| `build`       | The genome build version used for the reference panel (e.g., hg19 or hg38). | yes      |
| `range`       | Specify a range that is used for imputation (e.g. HLA)                      | no       |
| `mapMinimac`  | The location of the map file for Minimac                                    | no       |
| `populations` | A dictionary mapping population identifiers to their names.                 | yes      |
| `qcFilter`    | A dictionary mapping quality filters to their values.                       | no       |

##### Populations

The `populations` section contains a dictionary mapping population identifiers to their names and sample size. This mapping helps categorize and label the populations represented in the reference panel.

| Identifier | Name                                     |
| ---------- | ---------------------------------------- |
| `id`       | The id of the popualtion (e.g. eur)      |
| `name`     | The label of the population. (e.g. EUR)  |
| `samples`  | Number of samples in the reference panel |

Note: the population id has to be the same as in the legend files.

#### Quality Filters

| Filter               | Name                                                  | Default |
| -------------------- | ----------------------------------------------------- | ------- |
| `overlap`            | Minimal overlap between gwas data and reference panel | 0.5     |
| `minSnps`            | Minimal #SNPs per chunk                               | 3       |
| `sampleCallrate`     | Minimal sample call rate                              | 0.5     |
| `mixedGenotypeschrX` | -                                                     | 0.1     |
| `strandFlips`        | Maximal allowed strand flips                          | 100     |

### Example YAML

Here's an example YAML configuration for a reference panel. This configuration describes a reference panel named "HapMap 2" for an Imputation Server, including details about its version, data sources, and populations represented. The files are stored on AWS S3 and are directly consumed by the pipeline from there.

```yaml
name: HapMap 2
description: HapMap2 Reference Panel for Imputation Server
version: 2.0.0
website: http://imputationserver.sph.umich.edu
category: RefPanel

properties:
  id: hapmap2
  genotypes: s3://cloudgene/refpanels/hapmap/m3vcfs/hapmap_r22.chr$chr.CEU.hg19.recode.m3vcf.gz
  legend: s3://cloudgene/refpanels/hapmap/legends/hapmap_r22.chr$chr.CEU.hg19_impute.legend.gz
  mapEagle: s3://cloudgene/refpanels/hapmap/map/genetic_map_hg19_withX.txt.gz
  refEagle: s3://cloudgene/refpanels/hapmap/bcfs/hapmap_r22.chr$chr.CEU.hg19.recode.bcf
  build: hg19
  populations:
    - id: eur
      name: EUR
      samples: 60
    - id: off
      name: Off
      samples: -1
```

### Note on `$chr` Variable

In the example YAML configuration provided, you may have noticed the presence of the `$chr` variable in some URLs. This variable is a placeholder for the chromosome number and will be replaced by the Nextflow pipeline.

### Legend Files

A legend file is a tab-delimited file consisting of 5 columns (`id`, `position`, `a0`, `a1`, `all.aaf`).

---

## Run with Cloudgene

### Requirements:

- Install Nextflow
- Docker or Singularity
- Java 14

### Installation

- Install cloudgene3: `curl -s install.cloudgene.io | bash -s 3.0.0-rc3`
- Download latest source code zip file from releases
- Install impuationserver2 app: `./cloudgene install imputationserver2@latest`
- Install hapmap2 referenece panel: `./cloudgene install https://genepi.i-med.ac.at/downloads/imputation/imputation-hapmap2.zip`
- Start cloudgene server: `./cloudgene server`
- Open [http://localhost:8082](http://localhost:8082)
- Login with default admin account: username `admin` and password `admin1978`
- Imputation can be tested with the following [test file](https://github.com/genepi/imputationserver2/raw/main/tests/data/input/chr20-phased/chr20.R50.merged.1.330k.recode.small.vcf.gz)

### Default Configuration

The default configuration runs with Docker and uses Nextflow's [local executor](https://www.nextflow.io/docs/latest/executor.html#local).

### Running on SLURM

Configure via web interface (Applications -> imputationserver -> Settings) or adapt/create file `apps/imputationserver/nextflow.config` and add the following:

```
process {
  executor = 'slurm'
  queue = 'QueueName'  // replace with your Queue name
}

errorStrategy = {task.exitStatus == 143 ? 'retry' : 'terminate'}
maxErrors = '-1'
maxRetries = 3
```

See more about SLURM [Nextflow Documentation](https://www.nextflow.io/docs/latest/executor.html#slurm).

### Running on AWS Batch

1. Create AWS Batch queue and AMI role (see [Nextflow Documentation](https://www.nextflow.io/docs/latest/aws.html#aws-batch))
2. Configure via web interface (Applications -> imputationserver -> Settings) or adapt/create file `apps/imputationserver/nextflow.config` and add the following:

```
aws {
  region = 'eu-central-1'
  client {
    uploadChunkSize = 10485760
  }
  batch {
    cliPath = '/home/ec2-user/miniconda/bin/aws'
    executionRole = 'arn:aws:iam::***' // replace with your AMI role
  }
}

process {
  executor = 'awsbatch'
  queue = 'QueueName'  // replace with your Queue name
  scratch = false
}
```

3. Got to Settings -> General and set Workspace to "S3" and enter the location of a subfolder in an S3 bucket. Enter the location of a subfolder in an S3 bucket. Currently, it must be a subfolder; a bucket won't work (Example: `s3://cloudgene/workspace`).

Optional add [Wave](https://www.nextflow.io/docs/latest/wave.html) and [Fusion](https://www.nextflow.io/docs/latest/fusion.html) support to improve performance:

```
wave {
  enabled = true
  endpoint = 'https://wave.seqera.io'
}

fusion {
  enabled = true
}
```

### Activate mail support

- Configure mail server in Settings -> General -> Mail
- Configure Nextflow to use Cloudgenes mail settings by add the following to the global configuration (Settings -> General -> Nextflow) or adapt/create files `config/nextflow.confing` (see [Nextflow Documention](https://www.nextflow.io/docs/latest/config.html#config-mail) for all available mail settings)

```
mail {
    smtp.host = "${CLOUDGENE_SMTP_HOST}"
    smtp.port = "${CLOUDGENE_SMTP_PORT}"
    smtp.user = "${CLOUDGENE_SMTP_USER}"
    smtp.password = "${CLOUDGENE_SMTP_PASSWORD}"
    smtp.auth = true
    smtp.starttls.enable = true
    smtp.ssl.protocols = 'TLSv1.2'
}
```

- Add `params.config.send_mail = true` to the application specific configuration to activate mail notifications in the imputationserver2 pipeline

### Adapt default parameters

Parameters can be changed in the `nextflow.config`` file of the application. Example:

```
params.chunk_size = 500000
params.imputation.window = 100000
```

## Development

### Build docker image locally

```
docker build -t genepi/imputation-docker:latest .
```

### Run testcases

```
nf-test test
```

## License

imputationserver2 is MIT Licensed and was developed at the [Institute of Genetic Epidemiology](https://genepi.i-med.ac.at/), Medical University of Innsbruck, Austria.

## Contact

- [Sebastian Schönherr](https://genepi.i-med.ac.at/team/schoenherr-sebastian/)
- [Lukas Forer](https://genepi.i-med.ac.at/team/forer-lukas/)
