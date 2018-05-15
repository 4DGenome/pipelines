
#!/bin/bash

#==================================================================================================
# Created on: 2018-05-15
# Usage: ./fix_count_percentage_mapped.sh
# Authors: joseluis.villanueva@crg.eu (GitHub: egenomics)
# Goal: run a small script on all samples in the CRG cluster
# * Run the ONED normalization script for all samples
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
#samples="TE_S_T"


for s in $samples; do
	metadata_db=/users/project/4DGenome/data/4DGenome_metadata.db
	query="select ASSEMBLY_VERSION from hic WHERE SAMPLE_ID='$s';"
	assembly=$(sqlite3 $metadata_db "$query")
	# Build job: parameters
	submitted_on=`date +"%Y_%m_%d"`
	job_name=job_${s}_oned_norm
	job_file=$JOB_CMD/$job_name.sh
	m_out=$JOB_OUT
	rm $job_file
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
	echo "/users/mbeato/projects/utils_backup/oned_model.r $s ${s}_oned.RData > /users/project/4DGenome_no_backup/data/hic/samples/$s/downstream/$assembly/${s}_oned.RData" >> $job_file

	# Submit
	chmod a+x $job_file
	qsub < $job_file
	#fi
	sleep 0.1

done
