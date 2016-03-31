# README
---------------------------------------------------------------------------------------------------

**Pipeline to process HiC data using TADbit**


## Modules

1. preliminary_checks
	- check that a sample with the provided SAMPLE_ID exists in the metadata
	- check FASTQ files exist
	- save a SHA checksums of the FASTQ files
	- retrieve information from the sequencer, and store it in the metadata; a warning will be produced if the sequencing index introduced in the metadata does not agree with that seen in the first read of the FASTQ
	- compare the read length as seen in the FASTQ with that introduced either in the metadata or the configuration file 
	- check the FASTQ for the reference genome sequence exists
2. raw_fastqs_quality_plots
	- generate quality plots of the raw reads (read1 and read2 separately)
	- extract the percentage of dangling-ends and ligated sites for read1 and read2
3. trim_reads_trimmomatic
	- trim sequencing adapters (by default, Illumina's TruSeq3, which are typically used for the HiSeq and NextSeq sequencers) and low-quality ends from the reads using [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)
	- extract the number of trimmed reads
4. align_and_merge
	- align reads (read1 and read2 separately) to the genome reference sequence (using [GEM](http://www.nature.com/nmeth/journal/v9/n12/full/nmeth.2221.html)), process reads according to the restriction enzyme and merge alignments from read1 and read2
	- save a SHA checksums of the alignments (MAP format) in which both reads align
5. post_mapping_statistics
	- generate plots from the alignments: decay of interaction counts with genomic distance, distribution of dangling ends lengths, genomic covarage and interaction matrix of mapped reads in 1-Mb bins and proportion of mapped reads
	- extract metrics: fraction of read1 and read2 alignments, fraction of reads in which both read1 and read2 are mapped and the counts-to-distance slope
6. reads_filtering
	- filter reads based on multiple quality parameters; as of 2016-03-31 reads that meet these filters are excluded: self-circle, dangling-end, error, duplicated and random breaks (for more info see [TADbit](http://3dgenomes.github.io/TADbit/tutorial/tutorial_0_mapping.html))
	- save a SHA checksums of the filtered alignments (*tsv file)
7. post_filtering_statistics
	- generate plots after filtering reads: genomic coverage and interaction matrix of filtered reads in 1-Mb; also, 1-Mb genomic coverage of dangling ends and self circle reads
8. index_contacts
	- index and compress contacts to enable quick generation of interaction matrices of different regions and at different resolutions
9. map_to_bam:
	- convert MAP file with the alignments to BAM format
10. downstream_bam
	- perform several downstream analysis using the generated BAM (e.g. add SAM-like flags, find TADs and A/B compartments)
11. clean_up
	- delete (relatively large) intermediate files



## Scripts and configuration file

- `hic.sh`: most of the code
- `hic_submit`: wrapper script that both:
	- retrieves configuration variables and parameter values from the `hic.config` file
	- (if applies) submits jobs (one per sample) to execute the pipeline in the CRG cluster
- `hic.config`: configuration file (see below)


Configuration file example:
```
; This configuration file follows the INI file format (https://en.wikipedia.org/wiki/INI_file)

[data_type]
data_type			= hic

[samples]
samples				=TE_S_T				; e.g.: `samples=s1 s2 s3`, use 'TE_S_T' for testing purposes

[pipeline]
pipeline_name		= hic
pipeline_version	= 16.03
pipeline_run_mode	= full

[IO mode]
io_mode				= standard									; standard = ******, custom = in and out dir specified
CUSTOM_IN			= /users/project/4DGenome/pipelines/hic-16.03/test 		; only used if pipeline_io_mode=custom
CUSTOM_OUT			= /users/project/4DGenome/pipelines/hic-16.03/test 		; only used if pipeline_io_mode=custom
sample_to_fastqs	= sample_to_fastqs.txt				; file with paths, relative to CUSTOM_IN, to read1 (and read2) FASTQs, only used if pipeline_io_mode=custom

[cluster options]
submit_to_cluster	= yes					; the following are only applied if submit_to_cluster=yes
queue				= long-sl65				; for real data = long-sl65, for test = short-sl65
memory				= 100G					; for real data = 100G, for test = 20G
max_time			= 100:00:00 				; for real data = 100:00:00, for test = 6:00:00
slots				= 10 					; for real data = 10, for test = 1
email				= javier.quilez@crg.eu	; email to which start/end/error emails are sent

[metadata]
integrate_metadata	= yes					; yes: metadata is stored into database

[genome]
species					= homo_sapiens		; required if integrate_metadata=no, otherwise, retrieved from the metadata
version					= hg38_mmtv
read_length				= 50 				; required if integrate_metadata=no, otherwise, retrieved from the metadata

[trimmomatic]
; for recommended values see http://www.broadinstitute.org/cancer/software/genepattern/modules/docs/Trimmomatic/
; and those used in the supplementary data of the Trimmomatic paper (Bolger et al. 2014)
sequencing_type			= PE					; PE=paired-end, SE=single-end
seedMismatches			= 2
palindromeClipThreshold	= 30
simpleClipThreshold		= 12
leading					= 3
trailing				= 3
minAdapterLength		= 1
keepBothReads			= true
minQual					= 3
targetLength			= 40
strictness				= 0.999
minLength				= 36

[tadbit]
restriction_enzyme		= DpnII				; required if integrate_metadata=no, otherwise, retrieved from the metadata
max_molecule_length		= 500
max_frag_size			= 10000
min_frag_size			= 50
over_represented		= 0.005
re_proximity			= 4
reads_number_qc			= 100000
genomic_coverage_resolution	= Mb
frag_map				= True

[downstream]
flag_excluded			= 775
flag_included			= 0
flag_perzero			= 99
resolution_tad			= 50000 				; in bp
resolution_ab			= 100000				; in bp
```


## Execute the pipeline

```
pipelines/hic-16.03/hic_submit.sh <your_configuration_file>
```

Notes:
- please use your configuration file
- integration with metadata (i.e. access data from or add data to the metadata database only happens if `integrate_metadata=yes`
- if metadata are integrated, these will be used to set some parameters values; otherwise, such values are used from the configuration file
- the pipeline can be run in differents modes: `mode=full` executes all steps while `mode=<module_name> runs only that module`; note that running the *i*th step assumes the *i-n*th step has been already run


## Test datasets

### `TE_S_T`

Sample to test the `io_mode=standard` and/or `integrate_metadata=yes`. 

It consists of 1000 reads of the `MB_1_1` sample, generated with:
```
zcat sequencing/2015-04-28/MB_1_1_10082_CGATGT_read1.fastq.gz |head -n 4000 |gzip > sequencing/2015-01-01/TE_S_T_10082_CGATGT_read1.fastq.gz
zcat sequencing/2015-04-28/MB_1_1_10082_CGATGT_read2.fastq.gz |head -n 4000 |gzip > sequencing/2015-01-01/TE_S_T_10082_CGATGT_read2.fastq.gz
```

### `test1` and `test2`

Samples to test the `io_mode=custom` with `integrate_metadata=no`. 

It consists of 1000 reads of the `MB_1_1` and `MB_1_2` samples, generated with:
```
zcat sequencing/2015-04-28/MB_1_1_10082_CGATGT_read1.fastq.gz |head -n 4000 |gzip > pipelines/hic-16.03/test/test1_read1.fastq.gz
zcat sequencing/2015-04-28/MB_1_1_10082_CGATGT_read2.fastq.gz |head -n 4000 |gzip > pipelines/hic-16.03/test/test1_read2.fastq.gz
zcat sequencing/2015-04-28/MB_1_2_10083_TGACCA_read1.fastq.gz |head -n 4000 |gzip > pipelines/hic-16.03/test/test2_read1.fastq.gz
zcat sequencing/2015-04-28/MB_1_2_10083_TGACCA_read2.fastq.gz |head -n 4000 |gzip > pipelines/hic-16.03/test/test2_read2.fastq.gz
```


## TO-DO list
- ...