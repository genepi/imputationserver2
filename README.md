# nf-imputationserver

[![nf-gwas](https://github.com/genepi/nf-imputationserver/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/nf-imputationserver/actions/workflows/ci-tests.yml)
[![nf-test](https://img.shields.io/badge/tested_with-nf--test-337ab7.svg)](https://github.com/askimed/nf-test)

This repository includes the Michigan Imputation Server Workflow ported to Nextflow. 


## Getting Started

```
docker build -t genepi/nf-imputationserver:latest . 
```


## Run with test data

```
nextflow run main.nf -profile development -c tests/test_single_vcf.config
```


## Run testcases

```
nf-test test
```

# Parameters

| Parameter              | Default Value              | Description                                |
|------------------------|----------------------------|--------------------------------------------|
| `project`              | `null`                     | Project name                               |
| `project_date`         | `date`                     | Project date                               |
| `files`                | `null`                     | List of input files                        |
| `population`           | `null`                     | Population information                     |
| `refpanel_yaml`        | `null`                     | Reference panel YAML file                  |
| `mode`                 | `imputation`               | Processing mode (e.g., 'imputation')      |
| `phasing`              | `eagle`                    | Phasing method (e.g., 'eagle')            |
| `minimac_window`       | `500000`                   | Minimac window size                        |
| `minimac_min_ratio`    | `0.00001`                  | Minimac minimum ratio                      |
| `chunksize`            | `20000000`                 | Chunk size for processing                  |
| `phasing_window`       | `5000000`                  | Phasing window size                        |
| `cpus`                 | `1`                        | Number of CPUs to use                      |
| `min_samples`          | `20`                       | Minimum number of samples                 |
| `max_samples`          | `50000`                    | Maximum number of samples                 |
| `imputation.enabled`   | `true`                     | Enable or disable imputation               |
| `ancestry.enabled`     | `false`                    | Enable or disable ancestry analysis       |
| `ancestry.dim`         | `10`                       | Ancestry analysis dimension                |
| `ancestry.dim_high`    | `20`                       | High dimension for ancestry analysis       |
| `ancestry.batch_size`  | `50`                       | Batch size for ancestry analysis           |
| `ancestry.reference`   | `null`                     | Ancestry reference data                    |
| `ancestry.max_pcs`     | `8`                        | Maximum principal components for ancestry  |
| `ancestry.k`           | `10`                       | K value for ancestry analysis              |
| `ancestry.threshold`   | `0.75`                     | Ancestry threshold                         |
| `r2Filter`             | `0`                        | R2 filter value                            |
| `password`             | `null`                     | Password for authentication                 |
| `pipeline_version`     | `michigan-imputationserver-1.6.0-rc5` | Pipeline version                    |
| `eagle_version`        | `eagle-2.4`                | Eagle version                               |
| `beagle_version`       | `beagle.18May20.d20.jar`   | Beagle version                              |
| `imputation_version`   | `minimac4-1.0.2`           | Imputation version                          |
| `config.send_mail`     | `false`                    | Enable or disable email notifications     |
| `user.name`            | `null`                     | User's name                                |
| `user.email`           | `null`                     | User's email                               |
| `service.name`         | `nf-imputationserver`      | Service name                               |
| `service.email`        | `null`                     | Service email                              |
| `service.url`          | `null`                     | Service URL                                |
