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

## Parameters

| Parameter             | Default Value                         | Description                               |
| --------------------- | ------------------------------------- | ----------------------------------------- |
| `project`             | `null`                                | Project name                              |
| `project_date`        | `date`                                | Project date                              |
| `files`               | `null`                                | List of input files                       |
| `population`          | `null`                                | Population information                    |
| `refpanel_yaml`       | `null`                                | Reference panel YAML file                 |
| `mode`                | `imputation`                          | Processing mode (e.g., 'imputation')      |
| `phasing`             | `eagle`                               | Phasing method (e.g., 'eagle')            |
| `minimac_window`      | `500000`                              | Minimac window size                       |
| `minimac_min_ratio`   | `0.00001`                             | Minimac minimum ratio                     |
| `chunksize`           | `20000000`                            | Chunk size for processing                 |
| `phasing_window`      | `5000000`                             | Phasing window size                       |
| `cpus`                | `1`                                   | Number of CPUs to use                     |
| `min_samples`         | `20`                                  | Minimum number of samples                 |
| `max_samples`         | `50000`                               | Maximum number of samples                 |
| `imputation.enabled`  | `true`                                | Enable or disable imputation              |
| `ancestry.enabled`    | `false`                               | Enable or disable ancestry analysis       |
| `ancestry.dim`        | `10`                                  | Ancestry analysis dimension               |
| `ancestry.dim_high`   | `20`                                  | High dimension for ancestry analysis      |
| `ancestry.batch_size` | `50`                                  | Batch size for ancestry analysis          |
| `ancestry.reference`  | `null`                                | Ancestry reference data                   |
| `ancestry.max_pcs`    | `8`                                   | Maximum principal components for ancestry |
| `ancestry.k`          | `10`                                  | K value for ancestry analysis             |
| `ancestry.threshold`  | `0.75`                                | Ancestry threshold                        |
| `r2Filter`            | `0`                                   | R2 filter value                           |
| `password`            | `null`                                | Password for authentication               |
| `pipeline_version`    | `michigan-imputationserver-1.6.0-rc5` | Pipeline version                          |
| `eagle_version`       | `eagle-2.4`                           | Eagle version                             |
| `beagle_version`      | `beagle.18May20.d20.jar`              | Beagle version                            |
| `imputation_version`  | `minimac4-1.0.2`                      | Imputation version                        |
| `config.send_mail`    | `false`                               | Enable or disable email notifications     |
| `user.name`           | `null`                                | User's name                               |
| `user.email`          | `null`                                | User's email                              |
| `service.name`        | `nf-imputationserver`                 | Service name                              |
| `service.email`       | `null`                                | Service email                             |
| `service.url`         | `null`                                | Service URL                               |

## Reference Panel Configuration

This document describes the structure of a YAML file used to configure a reference panel for the Michigan Imputation Server. Reference panels are essential for genotype imputation, allowing the server to infer missing genotype data accurately.

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
| `id`          | An identifier for the reference panel. **TODO: needed??**                   | yes      |
| `genotypes`   | The location of the genotype files for the reference panel data.            | yes      |
| `legend`      | The location of the legend files for the reference panel data.              | yes      |
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

Here's an example YAML configuration for a reference panel. This configuration describes a reference panel named "HapMap 2" for the Michigan Imputation Server, including details about its version, data sources, and populations represented.

```yaml
name: HapMap 2
description: HapMap2 Reference Panel for Michigan Imputation Server
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
    - id: mixed
      name: Mixed
      samples: -1
```

### Note on `$chr` Variable

In the example YAML configuration provided, you may have noticed the presence of the `$chr` variable in some URLs. This variable is a placeholder for the chromosome number and will be replaced by the Nextflow pipeline.

## Legend Files

A legend file is a tab-delimited file consisting of 5 columns (`id`, `position`, `a0`, `a1`, `all.aaf`).
