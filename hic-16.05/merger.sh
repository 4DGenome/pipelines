#!/bin/bash


#==================================================================================================
# Created on: 2016-06-30
# Usage: ./merger.sh
# Author: Javier Quilez (GitHub: jaquol)
# Goal: merges multiple BAM files into one, indexes it and finds TADs and A/B compartments
#==================================================================================================


#==================================================================================================
# CONFIGURATION VARIABLES AND PATHS
#==================================================================================================

# possible modes
# merge: merges multiple BAM files into one and indexes it
# tadbit: on the merged/indexed BAM file, TADs and A/B compartments are inferred
# full: performs the 2 steps above

# variables
itab=$1
mode=full
project=4DGenome
analysis=2016-06-21_develop_merger
process=merger
min_n_replicates=2
pipeline_version=hic-16.05
flag_excluded=783
flag_included=0
flag_perzero=99
resolution_tad=50000 			# in bp
resolution_ab=50000				# in bp

# Paths
PROJECT=/users/project/$project
DATA=/users/project/4DGenome_no_backup/data/hic
JOB_CMD=$PROJECT/pipelines/$pipeline_version/job_cmd 
JOB_OUT=$PROJECT/pipelines/$pipeline_version/job_out 
mkdir -p $JOB_CMD
mkdir -p $JOB_OUT
samtools=`which samtools`
tadbit_after_bam_v2_bigbam_include_chromosome=$PROJECT/pipelines/$pipeline_version/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py

# Cluster parameters
queue=long-sl65
memory=100G
max_time=24:00:00
slots=10


#==================================================================================================
# COMMANDS
#==================================================================================================

while read line ;do 

	samples=$line

	merged_name=`echo $line | awk '{OFS="\t"; print $1}'`
	samples_ids=`echo $line | awk '{OFS="\t"; for (i=2; i<=NF; i++) printf $i" "}'`

	#echo $merged_name
	#echo $samples_ids

 	# check the number of replicates and that we are merging sequencing replicates from the same biological sample
 	n_replicates=0
 	names=""
 	ibams=""
 	for s in $samples_ids; do
 		n_replicates=`expr $n_replicates + 1`
 		names="$names `echo $s |cut -f1 -d'_'`"
 		ibam="$DATA/samples/${s}/results/*/processed_reads/${s}_both_map.bam"
 		ibams="$ibams $ibam"
 	done
 	#echo $names
 	#echo $ibams
 	#echo $n_replicates
 	#echo

 	# stop if not enough replicates
 	if [[ $n_replicates -lt $min_n_replicates ]]; then
 		echo "$n_replicates is smaller than $min_n_replicates; continue..."
 		continue
 	fi

 	# stop if sequencing replicates do not come from the same biological sample
 	bio_name=`echo $names |tr ' ' '\n' |sort |uniq`
 	if [[ `echo $bio_name |wc -l` -gt 1 ]]; then
 		echo "sequencing replicates do not come from the same biological sample; continue..."
 		continue
 	fi

 	# output directory
	ODIR=$DATA/merged/$merged_name
	if [ -d $ODIR ]; then
		echo "$merged_name already exists ($ODIR); continue..."
		continue
	fi		
	mkdir -p $ODIR

  	# make a record of the samples and files merged
  	echo -e "samples merged: \n$samples\n" > $ODIR/README.md
  	echo -e "BAMs merged: \n`ls $ibams`" >> $ODIR/README.md

  	# Build job: parameters
  	job_name=${process}_${mode}_${merged_name}
  	job_file=$JOB_CMD/$job_name.sh
  	m_out=$JOB_OUT
  	echo "#!/bin/bash
	#$ -N $job_name
	#$ -q $queue
	#$ -l virtual_free=$memory
	#$ -l h_rt=$max_time
	#$ -o $m_out/${job_name}_\$JOB_ID.out
	#$ -e $m_out/${job_name}_\$JOB_ID.err
	#$ -j y
	#$ -M javier.quilez@crg.eu
	#$ -m abe
	#$ -pe smp $slots" > $job_file	
  	sed -i 's/^\t//g' $job_file

 	# makes that the job uses this python/tadbit
  	echo 'export PATH="/software/mb/el6.3/Conda/bin:$PATH"' >> $job_file
  	echo 'python=`which python`' >> $job_file

 	# start timing job
  	echo 'time0=$(date +"%s")' >> $job_file

 	# merge BAMs
  	obam=$ODIR/${merged_name}_both_map_merged.bam
  	obai=$ODIR/${merged_name}_both_map_merged.bam.bai		
  	job_cmd_merge="$samtools merge -rf -@ $slots $obam $ibams"
  	job_cmd_index="$samtools index $obam"

	# apply TADbit after merging BAM
 	job_cmd_tadbit="\$python $tadbit_after_bam_v2_bigbam_include_chromosome \
 								$obam \
 								$flag_excluded \
 								$flag_included \
 								$flag_perzero \
 								$ODIR/${merged_name}_ \
 								$slots \
 								$resolution_ab \
 								$resolution_tad"

 	# add job commands depending on the mode
  	if [[ $mode == "full" ]]; then
  		echo $job_cmd_merge >> $job_file
  		echo $job_cmd_index >> $job_file
  		echo $job_cmd_tadbit >> $job_file
  	elif [[ $mode == "merge" ]]; then
  		echo $job_cmd_merge >> $job_file
  		echo $job_cmd_index >> $job_file
 	elif [[ $mode == "tadbit" ]]; then
  		echo $job_cmd_tadbit >> $job_file
  	fi

  	# end timing job and calculate time running
  	echo 'time1=$(date +"%s")' >> $job_file
  	echo 'echo "job length was $(($time1-$time0)) seconds"' >> $job_file

  	# submit job
  	chmod a+x $job_file
  	qsub < $job_file

done<$itab
