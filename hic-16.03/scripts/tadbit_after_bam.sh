#!/bin/bash

#$ -q short-sl65
#$ -l virtual_free=40G
#$ -l h_rt=6:00:00
#$ -pe smp 8
#$ -j y

#  include Conda in path

export PATH=/software/mb/el6.3/Conda/bin:$PATH

# get arguments

inbam=$1
excluded=$2
included=$3
perzero=$4
outdir=$5
ncpus=$6
shift 6
res="$@"

# do the magic!

# python \
# 	~/scripts/fdg_pipeline/tadbit_from_bam_to_AB.py \
# 	$inbam \
# 	$excluded \
# 	$included \
# 	$perzero \
# 	$outdir \
# 	$res


python \
	~/scripts/fdg_pipeline/tadbit_after_bam.py \
	$inbam \
	$excluded \
	$included \
	$perzero \
	$outdir \
	$ncpus \
	$res
