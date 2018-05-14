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
samples="9a7c4a68d_49deac2f0 GM_HindIII_NcoIGM_MboI_AseI GM_MboI_H20 GM_MboI_only HIC034 HIC036 HIC037 HIC070 K562_HindIII_NcoI K562_MboI_AseI K562_MboI_only e22e868a9_78d40f073"


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
	rm $job_file
	bam_file=/users/project/4DGenome_no_backup/data/hic/samples/$s/results/$assembly/processed_reads/$s\_both_map.bam
	echo "#!/bin/bash
	#$ -N $job_name
	#$ -q short-sl7
	#$ -l virtual_free=10G
	#$ -o $m_out/${job_name}.out
	#$ -e $m_out/${job_name}.err
	#$ -j y
	#$ -M $email
	#$ -m abe" > $job_file

	sed -i 's/^\t//g' $job_file

	# Add sample ID
	echo "sample=$s" >> $job_file
	echo "samtools sort -n $bam_file | samtools view | sed 's,#,~,g' | cut -f 1 | cut -d \"~\" -f 1 | uniq | wc -l > /users/project/4DGenome_no_backup/data/hic/samples/$s/results/$assembly/processed_reads/$s\\_per_mapped_reads.text" >> $job_file

	# Submit
	chmod a+x $job_file
	qsub < $job_file
	#fi
	sleep 0.5

done
