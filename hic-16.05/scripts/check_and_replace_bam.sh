#!/bin/bash

# get arguments

oldbam=$1
newbam=$2

tmp=$(mktemp)

# getting differences

echo "Checking bams"

bam diff \
	--in1 $newbam \
	--in2 $oldbam \
	--out $tmp \
	--noPhoneHome \
	2> /dev/null

if [ ! -s "$tmp" ]
then
	echo "Replacing $oldbam by $newbam"
	mv $newbam $oldbam
	mv $newbam.bai $oldbam.bai
	echo "Done!"
else
	echo "Bams do not match! Doing nothing ..."
	exit
fi

