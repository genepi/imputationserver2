# nf-imputationserver


## Build Docker image

```
docker build -t genepi/nf-imputationserver:latest . --platform linux/amd64
```


## Run with test data

```
nextflow run main.nf -profile development -c tests/test_single_vcf.config
```


## Run testcases


```
nf-test test
```