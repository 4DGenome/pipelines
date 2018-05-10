#!/bin/bash

#==================================================================================================
# Created on: 2018-05-03
# Usage: ./fix_count_percentage_mapped.sh
# Authors: joseluis.villanueva@crg.eu (GitHub: egenomics)
# Goal: run a small script on all samples in the CRG cluster
# * get values for the number of reads mapped, counting only once quimeric reads
# * generate a job script for each sample
# * submit jobs to the cluster
#==================================================================================================



#==================================================================================================
# CONFIGURATION VARIABLES AND PATHS
#==================================================================================================

#variables and paths
metadata_db=/users/project/4DGenome/data/4DGenome_metadata.db
query="select SAMPLE_ID from input_metadata" #generate query for DB
samples=$(sqlite3 $metadata_db "$query" | tr "\n" " " | sort | uniq | sed 's, $,,1') #Get all sample IDs
email=joseluis.villanueva@crg.eu

PIPELINE=/users/project/4DGenome/pipelines/hic-16.05
JOB_CMD=$PIPELINE/job_cmd
JOB_OUT=$PIPELINE/job_out

#==================================================================================================
# CODE EXECUTION
#==================================================================================================
# Run pipeline for each sample
samples="CAR_501 LDC_12 LDC_5 LDC_6 LDC_7 a7c643d27_4ed08f4eb a7c643d27_29726bc8f b742f3789_55a06ab10 a7c643d27_15f152106 b742f3789_37b77d82a auxin_rep1c b742f3789_0c582f35f b742f3789_43b4d3493 a7c643d27_ed0f2b6ec b742f3789_128e263fa b742f3789_4e6781c38 b742f3789_01d7fe832 b742f3789_20b0c0e8d"

for s in $samples; do
	metadata_db=/users/project/4DGenome/data/4DGenome_metadata.db
	query="select ASSEMBLY_VERSION from hic WHERE SAMPLE_ID='$s';"
	assembly=$(sqlite3 $metadata_db "$query")
	#if [ $assembly != 'hg38_mmtv' ];
	#then
	#echo $assembly, $s
	# Build job: parameters
	submitted_on=`date +"%Y_%m_%d"`
	job_name=job_${s}_per_mapped_reads
	job_file=$JOB_CMD/$job_name.sh
	m_out=$JOB_OUT
	#rm $job_file
	bam_file=/users/project/4DGenome_no_backup/data/hic/samples/$s/results/$assembly/processed_reads/$s\_both_map.bam

	echo "#!/bin/bash
	#$ -N $job_name
	#$ -q long-sl7
	#$ -l virtual_free=10G
	#$ -o $m_out/${job_name}.out
	#$ -e $m_out/${job_name}.err
	#$ -j y
	#$ -M $email
	#$ -m abe" > $job_file

	sed -i 's/^\t//g' $job_file

	# Add sample ID
	echo "sample=$s" >> $job_file
	echo "samtools sort -n $bam_file | sed 's,#,~,g' | cut -f 1 | cut -d \"~\" -f 1 | uniq | wc -l > /users/project/4DGenome_no_backup/data/hic/samples/$s/results/$assembly/processed_reads/$s\\_per_mapped_reads.text" >> $job_file

	# Submit
	chmod a+x $job_file
	qsub < $job_file
	#fi
	sleep 0.5

done
