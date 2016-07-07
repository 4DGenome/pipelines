#!/bin/bash
 	#$ -N merger_tadbit_a7c643d27_rep959
 	#$ -q long-sl65
 	#$ -l virtual_free=100G
 	#$ -l h_rt=24:00:00
 	#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_tadbit_a7c643d27_rep959_$JOB_ID.out
 	#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_tadbit_a7c643d27_rep959_$JOB_ID.err
 	#$ -j y
 	#$ -M javier.quilez@crg.eu
 	#$ -m abe
 	#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/a7c643d27_rep959/a7c643d27_rep959_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/a7c643d27_rep959/a7c643d27_rep959_ 10 50000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
