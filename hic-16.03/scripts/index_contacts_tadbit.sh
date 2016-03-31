#!/bin/bash

#$ -q short-sl65
#$ -l virtual_free=50G
#$ -l h_rt=5:00:00
#$ -pe smp 1
#$ -j y

# Usage: index_contacts_tadbit.sh [input contacts file] [output compressed file]

# settings

tabix=/software/mb/bin/tabix
bgzip=/software/mb/bin/bgzip

# get arguments

contacts=$1
outfile=$2

# split contacts per chr

echo " Splitting contacts ..."

awk -F "\t" -v OFS="\t" -v file=$outfile \
	'!/^#/{print $2, $3, $4, $8, $9, $10, $1 > file"_"$2;
      print $8, $9, $10, $2, $3, $4, $1 > file"_"$8}' \
		$contacts

echo " ... done!"

# sort contacts per chr

for i in ${outfile}_*
do

	echo " Sorting file " $i

	sort -k 2,2n $i > ${i}_sorted

	echo " ... done!"

done


# merge all chrs

echo " Merging and compressing ..."

for i in $(awk '{if(!/^#/) exit; print $3}' $contacts)
do

	touch ${outfile}_${i}_sorted
	cat ${outfile}_${i}_sorted

done | \
	$bgzip -c > \
	$outfile

echo " ... done!"

# index

echo " Indexing ..."

$tabix -f -s 1 -b 2 -e 2 $outfile

echo " ... done!"

# remove files

echo " Removing temp files ..."

rm ${outfile}_*

echo " ... done!"

