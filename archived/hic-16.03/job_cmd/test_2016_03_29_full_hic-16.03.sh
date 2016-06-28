#!/bin/bash
#$ -N test_2016_03_29_full_hic-16.03
#$ -q short-sl65
#$ -l virtual_free=40G
#$ -l h_rt=6:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.03/job_out/test_2016_03_29_full_hic-16.03_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.03/job_out/test_2016_03_29_full_hic-16.03_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 1

submitted_on=2016_03_29
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
path_job_file=/users/project/4DGenome/pipelines/hic-16.03/job_cmd/test_2016_03_29_full_hic-16.03.sh
# additional variables
time_start=$(date +"%s")
run_date=`date +"%Y-%m-%d-%H-%M"`
job_name=$pipeline_name-$pipeline_version

# makes that the job uses this python/tadbit
export PATH="/software/mb/el6.3/Conda/bin:$PATH"



#==================================================================================================
# PATHS
#==================================================================================================


# (1) Directories

# script to in/out data from metadata
io_metadata=/users/project/4DGenome/utils/io_metadata.sh

# pipeline scripts
SCRIPTS=$PIPELINE/scripts

# Primary output directory
if [[ $io_mode == "custom" ]]; then
	SAMPLE=$CUSTOM_OUT/$sample_id
	echo $SAMPLE
else
	SAMPLE=/users/project/4DGenome_no_backup/data/$data_type/$sample_id
fi

# sequencing data
SEQ_DATA=/users/project/4DGenome/sequencing

# Logs
LOGS=$SAMPLE/logs/$version

# Trim reads
TRIMMED=$SAMPLE/fastqs_processed/trimmomatic
PAIRED=$TRIMMED/paired_end
UNPAIRED=$TRIMMED/unpaired_reads
ADAPTERS=/software/mb/el6.3/Trimmomatic-0.33/adapters

# SHA cheksums
CHECKSUMS=$SAMPLE/checksums/$version/$run_date
checksums=$CHECKSUMS/files_checksums.sha


# (2) Files

# input FASTQ
if [[ $io_mode == "custom" ]]; then
	ifq1_name=`grep $sample_id $CUSTOM_IN/sample_to_fastqs.txt |cut -f2`
	ifq2_name=`grep $sample_id $CUSTOM_IN/sample_to_fastqs.txt |cut -f3`
	ifq1=$CUSTOM_IN/$ifq1_name
	ifq2=$CUSTOM_IN/$ifq2_name
else
	ifq1=$SEQ_DATA/*/${sample_id}*read1.fastq.gz
	ifq2=$SEQ_DATA/*/${sample_id}*read2.fastq.gz
fi

# tools
python=`which python`
trimmomatic=`which trimmomatic`



# =================================================================================================
# CODE EXECUTION
# =================================================================================================

main() {

	echo
	# store general parameters into the metadata
	if [[ $integrate_metadata == "yes" ]]; then
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PIPELINE_RUN_MODE -v $pipeline_run_mode
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a QUEUE -v $queue
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a MEMORY -v $memory
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a MAX_TIME -v $max_time
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a SLOTS -v $slots
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a ASSEMBLY_VERSION -v $version
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a JOB_NAME -v $job_name		
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PATH_JOB_FILE -v $job_file		
	fi

	if [[ $pipeline_run_mode == 'full' ]]; then
		preliminary_checks
#	elif [[ $pipeline_run_mode == 'trim_reads_trimmomatic' ]]; then trim_reads_trimmomatic
#	elif [[ $pipeline_run_mode == 'align_bwa' ]]; then align_bwa
#	elif [[ $pipeline_run_mode == 'make_tag_directory' ]]; then make_tag_directory
#	elif [[ $pipeline_run_mode == 'make_bigbed' ]]; then make_bigbed
#	elif [[ $pipeline_run_mode == 'calculate_rpms' ]]; then calculate_rpms
#	elif [[ $pipeline_run_mode == 'call_peaks' ]]; then call_peaks
	fi
	echo

}



#==================================================================================================
# FUNCTIONS DEFINITIONS
#==================================================================================================


# =================================================================================================
# Pipeline progress functions
# =================================================================================================

# Outputs a message about the task being done
message_info() {
	step_name=$1
	message=$2
	echo -e "INFO \t`date +"%Y-%m-%d %T"` \t[$step_name] \t$message"
}

# Outputs a message about the error found and exits
message_error() {
	step_name=$1
	message=$2
	echo -e "ERROR \t`date +"%Y-%m-%d %T"` \t[$step_name] \t$message"
	exit	
}

# Outputs a warning message about the task being done
message_warn() {
	step_name=$1
	message=$2
	echo -e "WARN \t`date +"%Y-%m-%d %T"` \t[$step_name] \t$message"
}

# Outputs a message with the time in seconds spent in a given step
message_time_step() {
	step_name=$1
	field_name="TIME_${step_name^^}"
	time0=$2
	time1=$(date +"%s")
	length=$(($time1-$time0))
	echo -e "TIME \t`date +"%Y-%m-%d %T"` \t[$step_name] \tstep time for completion (seconds) = $length"
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a $field_name -v $length
	fi
	echo
}

# Outputs the total time in seconds for the pipeline to run
message_time_pipeline() {
	field_name="TIME_COMPLETE_PIPELINE"
	time0=$time_start
	time1=$(date +"%s")
	length=$(($time1-$time0))
	echo -e "TIME \t`date +"%Y-%m-%d %T"` \t[pipeline] \ttotal time for completion (seconds) = $length"
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a $field_name -v $length
	fi
	echo
}


# ========================================================================================
# Checks that the selected sample(s) is in the database
# Gets analysis parameters (for Trimmomatic and TADbit) from the configuration file
# Gets FASTQ files and additional metadata
# ========================================================================================

preliminary_checks() {

	step="preliminary_checks"
	time0=$(date +"%s")

	# Check that a sample with the provided SAMPLE_ID exists
	sample_check=`$io_metadata -m check_sample -s $sample_id`
	if [[ $sample_check == "no_sample" ]]; then
		#rm -fR $SAMPLE
		message_error $step "$sample_id not found in $metadata. Exiting..."
	elif [[ $sample_check == "multiple_samples" ]]; then
		#rm -fR $SAMPLE
		message_error $step "$sample_id has multiple entries in $metadata. Exiting..."
	else
		message_info $step "$sample_id found in $metadata"
	fi
	message_info $step "data for $sample_id will be stored at $SAMPLE"

	# check FASTQ files exist
	if [ -f $ifq1 ] && [ -f $ifq2 ]; then
		mkdir -p $SAMPLE
		mkdir -p $CHECKSUMS
		# data integrity
		shasum $ifq1 >> $checksums
		shasum $ifq2 >> $checksums
		# Get sequencing information from the header of the FASTQ reads (some fields should be shared across all reads)
		fq_header=`zcat $ifq1 | head -n 1 | sed s'/ /:/g'`
		sequencing_instrument_name=`echo $fq_header | cut -f1 -d':'`
		sequencing_run_id=`echo $fq_header | cut -f2 -d':'`
		sequencing_flowcell_id=`echo $fq_header | cut -f3 -d':'`
		sequencing_flowcell_lane=`echo $fq_header | cut -f4 -d':'`
		sequencing_index_fq=`echo $fq_header | cut -f11 -d':'`
		# update metadata
		if [[ $integrate_metadata == "yes" ]]; then
			$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PATH_FASTQ_READ1 -v $ifq1
			$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PATH_FASTQ_READ2 -v $ifq2
			$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a 'SEQUENCING_INSTRUMENT_NAME' -v $sequencing_instrument_name
			$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a 'SEQUENCING_RUN_ID' -v $sequencing_run_id
			$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a 'SEQUENCING_FLOWCELL_ID' -v $sequencing_flowcell_id
			$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a 'SEQUENCING_FLOWCELL_LANE' -v $sequencing_flowcell_lane
			message_info $step "paths to read1 and read2 saved to metadata database"
			# Check that the sequencing index introduced as part of the metadata agrees with that found in the FASTQ reads
			sequencing_index=`$io_metadata -m get_from_metadata -s $sample_id -t input_metadata -a SEQUENCING_INDEX`
			if [[ $sequencing_index == $sequencing_index_fq ]]; then
		 		message_info $step "Sequencing index added as part of the metadata agrees with that observed in the FASTQ file"
			else
				message_warn $step "Sequencing index added as part of the metadata does not agree with that observed in the FASTQ file"
			fi
			# Determine read length and update metadata if necessary
			# Read length from the first read of the FASTQ files (it assumes all reads in the file have the same lenght!)
			first_read=`zcat $ifq1 | head -2 | tail -n 1`	
			read_length_fq=${#first_read}
			# Read length from the metadata
			read_length_metadata=`$io_metadata -m get_from_metadata -s $sample_id -t input_metadata -a 'READ_LENGTH'`
			if [[ "$read_length_fq" != "$read_length_metadata" ]]; then
				message_warn $step "read length obtained from the metadata ($read_length_metadata bp) differs from that seen in the FASTQ ($read_length_fq bp)"
				message_warn $step "the latter will be kept"
				$io_metadata -m update_input_metadata -s $sample_id -a 'READ_LENGTH' -v $read_length_fq
			fi
		fi
	fi
}




# execute main function
main