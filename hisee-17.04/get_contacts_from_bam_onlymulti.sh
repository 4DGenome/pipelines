#!/bin/bash

#$ -q short-sl65
#$ -l virtual_free=2G
#$ -l h_rt=2:00:00
#$ -pe smp 1
#$ -j y

# get arguments

inbam=$1
region=$2
filterin=$3
filterex=$4
w=$5

# do the magic 

samtools view \
	-f $filterin \
	-F $filterex \
	$inbam \
	$region | \
	awk -v w=$w -v OFS='\t' \
		'$12 == "TC:i:2"{a = int($4 / w) * w; b = int($8 / w) * w; out[a OFS b] += 1}
         END{for(i in out) print i, out[i]}'




