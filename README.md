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
