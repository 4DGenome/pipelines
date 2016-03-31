# README
---------------------------------------------------------------------------------------------------

**Pipeline to process HiC data using TADbit**

## TO-DO list
- make io_metadata scripts (in utils/) and replace old ones used in the old pipeline version
- new reference genomes for hg38 (include mmtv) and mm10


## Modules
1. `preliminary_checks`


### `preliminary_checks`
trim sequencing adapters and low-quality ends from the reads using [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)
