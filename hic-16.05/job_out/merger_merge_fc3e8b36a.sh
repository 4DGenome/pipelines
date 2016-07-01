#!/bin/bash
#$ -N merger_merge_fc3e8b36a
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /merger_merge_fc3e8b36a_$JOB_ID.out
#$ -e /merger_merge_fc3e8b36a_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/fc3e8b36a/fc3e8b36a_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/fc3e8b36a_7bf1bf374/results/mm10/processed_reads/fc3e8b36a_7bf1bf374_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/fc3e8b36a_c990a254e/results/mm10/processed_reads/fc3e8b36a_c990a254e_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/fc3e8b36a_4ff2182a3/results/mm10/processed_reads/fc3e8b36a_4ff2182a3_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/fc3e8b36a_b33d5ef43/results/mm10/processed_reads/fc3e8b36a_b33d5ef43_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/fc3e8b36a/fc3e8b36a_both_map_merged.bam
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
