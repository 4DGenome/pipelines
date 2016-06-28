#!/bin/bash
#$ -N TE_S_T_2016_03_29_post_mapping_statistics_hic-16.03
#$ -q short-sl65
#$ -l virtual_free=10G
#$ -l h_rt=6:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.03/job_out/TE_S_T_2016_03_29_post_mapping_statistics_hic-16.03_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.03/job_out/TE_S_T_2016_03_29_post_mapping_statistics_hic-16.03_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 1

submitted_on=2016_03_29
pipeline_version=16.03
sample_id=TE_S_T
data_type=hic
pipeline_name=hic
pipeline_version=16.03
pipeline_run_mode=post_mapping_statistics
io_mode=standard
CUSTOM_IN=/users/project/4DGenome/pipelines/hic-16.03/test
CUSTOM_OUT=/users/project/4DGenome/pipelines/hic-16.03/test
sample_to_fastqs=sample_to_fastqs.txt
submit_to_cluster=no
queue=short-sl65
memory=10G
max_time=6:00:00
slots=1
email=javier.quilez@crg.eu
integrate_metadata=no
species=homo_sapiens
version=hg38_mmtv
read_length=50
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
restriction_enzyme=DpnII
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
path_job_file=/users/project/4DGenome/pipelines/hic-16.03/job_cmd/TE_S_T_2016_03_29_post_mapping_statistics_hic-16.03.sh
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
metadata=/users/project/4DGenome/data/4DGenome_metadata.db

# pipeline scripts
SCRIPTS=$PIPELINE/scripts

# Primary output directory
if [[ $io_mode == "custom" ]]; then
	SAMPLE=$CUSTOM_OUT/$sample_id
	echo $SAMPLE
else
	SAMPLE=/users/project/4DGenome_no_backup/data/$data_type/samples/$sample_id
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

# plots
QUALITY_PLOTS=$SAMPLE/plots/processed_fastqs_quality_plots

# aligned, processed and merged reads
PROCESSED=$SAMPLE/results/processed_reads
POSTMAPPING_PLOTS=$SAMPLE/plots/post_mapping_statistics
COVERAGES=$SAMPLE/results/genomic_coverages


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
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PATH_JOB_FILE -v $path_job_file		
	fi

	if [[ $pipeline_run_mode == 'full' ]]; then
		preliminary_checks
		raw_fastqs_quality_plots
		trim_reads_trimmomatic
		align_and_merge
	elif [[ $pipeline_run_mode == 'preliminary_checks' ]]; then preliminary_checks
	elif [[ $pipeline_run_mode == 'raw_fastqs_quality_plots' ]]; then raw_fastqs_quality_plots
	elif [[ $pipeline_run_mode == 'trim_reads_trimmomatic' ]]; then trim_reads_trimmomatic
	elif [[ $pipeline_run_mode == 'align_and_merge' ]]; then align_and_merge
	elif [[ $pipeline_run_mode == 'post_mapping_statistics' ]]; then post_mapping_statistics
	elif [[ $pipeline_run_mode == 'reads_filtering' ]]; then reads_filtering
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
		message_error $step "$sample_id not found in $metadata. Exiting..."
	elif [[ $sample_check == "multiple_samples" ]]; then
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
			else
				message_info $step "read length added as part of the metadata agrees with that observed in the FASTQ file"
			fi
		fi
		# Check that FASTQ for the reference sequence exists
		fasta=/users/GR/mb/jquilez/assemblies/$species/$version/ucsc/$version.fa
		if ! [[ -f "$fasta" ]]; then
			message_error $step "FASTA file $fasta does not exist! Exiting..."
		else
			message_info $step "genome reference FASTA file found at $fasta"
			shasum $fasta >> $checksums
			if [[ $integrate_metadata == "yes" ]]; then
				$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PATH_REFERENCE_FASTA -v $fasta
				message_info $step "paths to reference FASTA saved to metadata database"
			fi
		fi
	else
		message_error $step "$ifq1 and/or $ifq2 not found. Exiting..."
	fi

	message_time_step $step $time0

}


# ========================================================================================
# Quality plots of the raw reads
# ========================================================================================

raw_fastqs_quality_plots() {

	step="raw_fastqs_quality_plots"
	time0=$(date +"%s")

	# Get metadata
	if [[ $integrate_metadata == "yes" ]]; then
		restriction_enzyme=`$io_metadata -m get_from_metadata -s $sample_id -t input_metadata -a RESTRICTION_ENZYME`
	fi
	message_info $step "restriction enzyme = $restriction_enzyme"
	message_info $step "a subset of $reads_number_qc reds will be used to generate the quality plots"
	
	# Make plots
	mkdir -p $QUALITY_PLOTS
	message_info $step "making quality plots of the raw FASTQ files... plots saved at $QUALITY_PLOTS"
	returned_values=`$python $SCRIPTS/fastqs_quality_plots.py $QUALITY_PLOTS \
  											$ifq1 \
  											$ifq2 \
  											$reads_number_qc \
  											$restriction_enzyme`

 	# Extract the percentage of dangling-ends and ligated sites for each read
  	percentage_dangling_ends_read1=`echo $returned_values |cut -f1 -d';'`
  	percentage_ligated_sites_read1=`echo $returned_values |cut -f2 -d';'`
  	percentage_dangling_ends_read2=`echo $returned_values |cut -f3 -d';'`
  	percentage_ligated_sites_read2=`echo $returned_values |cut -f4 -d';'`

  	# update metadata
	if [[ $integrate_metadata == "yes" ]]; then
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PERCENTAGE_DANGLING_ENDS_READ1 -v $percentage_dangling_ends_read1
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PERCENTAGE_LIGATED_SITES_READ1 -v $percentage_ligated_sites_read1
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PERCENTAGE_DANGLING_ENDS_READ2 -v $percentage_dangling_ends_read2
		$io_metadata -m add_to_metadata -t 'hic' -s $sample_id -u $run_date -a PERCENTAGE_LIGATED_SITES_READ2 -v $percentage_ligated_sites_read2
		message_info $step "percentages of dangling ends and ligated sites in read1 and read2 saved to metadata database"
	fi
 
	message_time_step $step $time0

}


# =================================================================================================
# Trim adapter and low-quality ends
# =================================================================================================

trim_reads_trimmomatic() {

	step="trim_reads_trimmomatic"
	time0=$(date +"%s")

	# paths
	mkdir -p $PAIRED
	mkdir -p $UNPAIRED
	mkdir -p $LOGS
	step_log=$SAMPLE/logs/${sample_id}_${step}_paired_end.log
	paired1=$PAIRED/${sample_id}_read1.fastq.gz
	paired2=$PAIRED/${sample_id}_read2.fastq.gz
	unpaired1=$UNPAIRED/${sample_id}_read1.fastq.gz
	unpaired2=$UNPAIRED/${sample_id}_read2.fastq.gz
	params="$ifq1 $ifq2 $paired1 $unpaired1 $paired2 $unpaired2"
	ODIR=$PAIRED

	# adapter trimming: the trimmomatic program directory contains a folder with the adapter sequences for
	# the Illumina sequencers in use. 'TruSeq3-PE.fa' is used, which contains the adapter sequences for the HiSeq
	message_info $step "sequencing type = $sequencing_type" 
	message_info $step "trimming TruSeq3 adapter sequences for HiSeq, NextSeq or HiSeq"
	message_info $step "trimming low-quality reads ends using trimmomatic's recommended practices"
	seqs=$ADAPTERS/TruSeq3-$sequencing_type.fa
	$trimmomatic $sequencing_type \
 					$params \
 					ILLUMINACLIP:$seqs:$seedMismatches:$palindromeClipThreshold:$simpleClipThreshold:$minAdapterLength:$keepBothReads \
 					LEADING:$leading \
 					TRAILING:$trailing \
 					MAXINFO:$targetLength:$strictness \
 					MINLEN:$minLength >$step_log 2>&1

	# parse step log to extract generated metadata
	message_info $step "parse step log to extract generated metadata"
 	n_reads_trimmed=`grep Surviving $step_log | cut -f3 -d':' | cut -f1 -d'(' | sed "s/ //g"`
	message_info $step "reads after trimming = $n_reads_trimmed"

	# update metadata
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a ADAPTERS_SEQS -v $seqs
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a SEED_MISMATCHES -v $seedMismatches
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a PALINDROME_CLIP_THRESHOLD -v $palindromeClipThreshold
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a SIMPLE_CLIP_THRESHOLD -v $simpleClipThreshold
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a MIN_ADAPTER_LENGTH -v $minAdapterLength
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a KEEP_BOTH_READS -v $keepBothReads
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a LEADING -v $leading
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a TRAILING -v $trailing
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a TARGET_LENGTH -v $targetLength
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a STRICTNESS -v $strictness
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a MIN_LENGTH -v $minLength
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a N_READS_TRIMMED -v $n_reads_trimmed
		message_info $step "trimmomatic parameters and numbe of trimmed reads added to metadata"
	fi

	# delete intermediate files
	message_info $step "trimmed reads are in $ODIR"
	if [[ $sequencing_type == "PE" ]]; then
		message_info $step "unpaired reads are deleted"
		rm -fr $UNPAIRED
	fi

	message_time_step $step $time0

}


# ========================================================================================
# align with GEM, process mapped reads according to restriction enzyme fragments and Merge mapped "read1" and "read2"
# ========================================================================================

align_and_merge() {

	step="align_and_merge"
	time0=$(date +"%s")

	# Get metadata
	if [[ $integrate_metadata == "yes" ]]; then
		restriction_enzyme=`$io_metadata -m get_from_metadata -s $sample_id -t input_metadata -a RESTRICTION_ENZYME`
		species=`$io_metadata -m get_from_metadata -s $sample_id -t input_metadata -a SPECIES`
		read_length=`$io_metadata -m get_from_metadata -s $sample_id -t input_metadata -a READ_LENGTH`
	fi
	message_info $step "species = $species"
	message_info $step "assembly version = $version"
	message_info $step "restriction enzyme = $restriction_enzyme"
	message_info $step "read length = $read_length"

	# genome reference FASTA
	fasta=/users/GR/mb/jquilez/assemblies/$species/$version/ucsc/$version.fa
	if ! [[ -f "$fasta" ]]; then
		message_error $step "FASTA file $fasta does not exist! Exiting..."
	else
		message_info $step "genome reference FASTA file found at $fasta"
	fi

	# processed FASTQs (i.e. after `trim_reads_trimmomatic`)
	paired1=$PAIRED/$sample_id*read1.fastq.gz
	paired2=$PAIRED/$sample_id*read2.fastq.gz

	# Added to overcome en error when running TADbit 'get_intersection' function
	export LC_ALL=en_US.UTF-8
	export LANG=en_US.UTF-8

	# Prevent overriding existing processed reads
	step_log=$LOGS/${sample_id}_${step}_paired_end.log
	if [ -f $step_log ]; then
   		message_error $step "processed reads already mapped (see $step_log). Exiting..."
	fi

	# Mapping
	message_info $step "mapping, processing reads according to restriction enzyme fragments and merging aligments for read1 and read2..."
	gem_index=`echo $fasta | sed "s/\.fa/\.gem/g"`
	$python $SCRIPTS/map_process_merge.py $gem_index \
 			$SAMPLE \
 			$species \
 			$read_length \
 			$paired1 \
 			$paired2 \
 			$restriction_enzyme \
			$fasta \
			$slots \
			$frag_map > $step_log
	rm -fr $SAMPLE/mapped_reads/tmp_dir*
	rm -fr $SAMPLE/results/processed_reads/tmp*
	message_info $step "output saved in $step_log"

	# data integrity
	shasum $SAMPLE/results/processed_reads/${sample_id}*both_map.tsv >> $checksums

	message_time_step $step $time0

}


# ========================================================================================
# Post-mapping descriptive statistics
# ========================================================================================

post_mapping_statistics() {

	step="post_mapping_statistics"
	time0=$(date +"%s")

	# paths
	maps1=$PROCESSED/$sample_id*read1*map.tsv
	maps2=$PROCESSED/$sample_id*read2*map.tsv
	mkdir -p $POSTMAPPING_PLOTS
	mkdir -p $COVERAGES

	# get metadata
	step_log_trim_reads_trimmomatic=$SAMPLE/logs/${sample_id}_trim_reads_trimmomatic_paired_end.log
 	n_reads_trimmed=`grep Surviving $step_log_trim_reads_trimmomatic | cut -f3 -d':' | cut -f1 -d'(' | sed "s/ //g"`

	# Generate plots
	message_info $step "generating post mapping descriptive statistics plots..."
	returned_values=`$python $SCRIPTS/mappings_descriptive_statistics.py $PROCESSED \
														$POSTMAPPING_PLOTS \
 														$COVERAGES \
 														$maps1 \
 														$maps2 \
 														$n_reads_trimmed \
 														$genomic_coverage_resolution`

	# parse metadata
	fraction_mapped_read1=`echo $returned_values | cut -f1 -d';' | cut -f1 -d','`
	fraction_mapped_read2=`echo $returned_values | cut -f1 -d';' | cut -f2 -d','`
	counts_to_distance_slope=`echo $returned_values | cut -f2 -d';'`
	both_reads_mapped=`cat $PROCESSED/*both* | grep -v "#" | wc -l`
	message_info $step "fraction of reads mapped read1 = $fraction_mapped_read1"
	message_info $step "fraction of reads mapped read2 = $fraction_mapped_read2"
	message_info $step "number of pairs in which both read1 and read2 are mapped = $both_reads_mapped"
	message_info $step "counts-to-distance slope = $counts_to_distance_slope"

	# update metadata
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a FRACTION_MAPPED_READ1 -v $fraction_mapped_read1
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a FRACTION_MAPPED_READ2 -v $fraction_mapped_read2
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a COUNTS_TO_DISTANCE_SLOPE -v $counts_to_distance_slope
	 	$io_metadata -m add_to_metadata -t 'chipseq' -s $sample_id -u $run_date -a BOTH_READS_MAPPED -v $both_reads_mapped
	fi

	message_time_step $step $time0

}


# ========================================================================================
# Filtering of reads
# ========================================================================================

reads_filtering() {

	step="reads_filtering"
	time0=$(date +"%s")

	# Paths
	FILTERED=$SAMPLE/results/filtered_reads
	DANGLING=$SAMPLE/results/excluded_reads/dangling_ends
	SELF_CIRCLE=$SAMPLE/results/excluded_reads/self_circle
	SUMMARY_EXCLUDED=$SAMPLE/results/excluded_reads/summary_excluded_per_filter
	both_reads_mapped=`cat $PROCESSED/*both_map.tsv | grep -v "#" | wc -l`
	mkdir -p $FILTERED $DANGLING $SELF_CIRCLE $SUMMARY_EXCLUDED

	# Filter reads based on multiple quality parameters
	message_info $step "filtering reads based on multiple quality parameters..."
	message_info $step "filtered reads to be used for subsequent analyses are at $FILTERED"
	message_info $step "excluded reads due to dangling ends are at $DANGLING"
	message_info $step "excluded reads due to self circle are at $SELF_CIRCLE"
	message_info $step "summary of excluded reads at $SUMMARY_EXCLUDED"
	# n_filtered_reads=`$python $SCRIPTS/filter_reads.py $PROCESSED \
	# 								$FILTERED \
	# 								$DANGLING \
	# 								$SELF_CIRCLE \
	# 								$SUMMARY_EXCLUDED \
	# 								$max_molecule_length \
	# 								$over_represented \
	# 								$min_frag_size \
	# 								$max_frag_size \
	# 								$re_proximity \
	# 								$both_reads_mapped`
	$python $SCRIPTS/filter_reads.py $PROCESSED \
									$FILTERED \
									$DANGLING \
									$SELF_CIRCLE \
									$SUMMARY_EXCLUDED \
									$max_molecule_length \
									$over_represented \
									$min_frag_size \
									$max_frag_size \
									$re_proximity \
									$both_reads_mapped
	exit

	# Update metadata
	# Filtered reads
	python $SCRIPTS/update_and_get_samples_metadata.py $metadata update_metrics $sample_id 'N_FILTERED_READS' $n_filtered_reads
	message_update_metadata $step 'N_FILTERED_READS' $metadata	
	# Excluded reads
	infile=$SUMMARY_EXCLUDED/*_summary_excluded_per_filter.txt
	for filter in `cut -f2 -d$'\t' $infile | grep -v exclusion`; do
		reads_number=`cat $infile | grep -P "\t$filter\t" | cut -f3`
		reads_fraction=`cat $infile | grep -P "\t$filter\t" | cut -f4`
		filter=`echo ${filter^^} | sed 's/-/_/g'`
		filter="EXCLUDED_$filter"
		python $SCRIPTS/update_and_get_samples_metadata.py $metadata update_metrics $sample_id $filter "$reads_number;$reads_fraction"
		message_update_metadata $step $filter $metadata
	done

	message_time_step $step $time0

}


# execute main function
main