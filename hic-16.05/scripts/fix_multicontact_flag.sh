#!/bin/bash

# get arguments

oldbam=$1
newbam=$2

# do the magic

echo "Changing multicontac tag"

samtools view -h $oldbam | \
	awk -F "\t" -v OFS="\t" \
		'{n = gsub("#", "#", $1); if(n > 0){$12 = "TC:i:2"}else{$12 = "TC:i:1"} print}' |
	samtools view -Sb - > \
			 $newbam

echo "Indexing bam"

samtools index $newbam

echo "Done!"
