#!/bin/bash
#$ -N test_2016_03_24_full_hic-16.03
#$ -q short-sl65
#$ -l virtual_free=40G
#$ -l h_rt=6:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.03/job_out/test_2016_03_24_full_hic-16.03_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.03/job_out/test_2016_03_24_full_hic-16.03_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 1

submitted_on=2016_03_24
pipeline_version=16.03
sample_id=test
data_type=hic
pipeline_name=hic
pipeline_version=16.03
pipeline_run_mode=full
io_mode=standard
CUSTOM_IN=/users/project/4DGenome/pipelines/hic-16.03/test
CUSTOM_OUT=/users/project/4DGenome/pipelines/hic-16.03/test
sample_to_fastqs=sample_to_fastqs.txt
submit_to_cluster=no
queue=short-sl65
memory=40G
max_time=6:00:00
slots=1
email=javier.quilez@crg.eu
integrate_metadata=no
sequencing_type=PE
seedMismatches=2
palindromeClipThreshold=30
simpleClipThreshold=12
leading=3
trailing=3
minAdapterLength=1
keepBothReads=true
minQual=3
targetLength=40
strictness=0.999
minLength=36
species=homo_sapiens
version=hg38
max_molecule_length=500
max_frag_size=10000
min_frag_size=50
over_represented=0.005
re_proximity=4
reads_number_qc=100000
genomic_coverage_resolution=Mb
frag_map=True
CUSTOM_OUT=/users/project/4DGenome/pipelines/hic-16.03/test
PIPELINE=/users/project/4DGenome/pipelines/hic-16.03
config=pipelines/hic-16.03/hic.config
path_job_file=/users/project/4DGenome/pipelines/hic-16.03/job_cmd/test_2016_03_24_full_hic-16.03.sh
