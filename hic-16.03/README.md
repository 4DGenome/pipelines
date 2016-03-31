# README
---------------------------------------------------------------------------------------------------

**Pipeline to process HiC data using TADbit**

## TO-DO list
- make io_metadata scripts (in utils/) and replace old ones used in the old pipeline version
- new reference genomes for hg38 (include mmtv) and mm10


## Modules

**data are only accessed from or added to the metadata if `integrate_metadata=yes`**

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




