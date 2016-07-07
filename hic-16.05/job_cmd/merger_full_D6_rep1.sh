#!/bin/bash
#$ -N merger_full_D6_rep1
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_D6_rep1_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_D6_rep1_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/D6_rep1/D6_rep1_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_be0425d2d/results/mm10/processed_reads/b742f3789_be0425d2d_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_37b77d82a/results/mm10/processed_reads/b742f3789_37b77d82a_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_6f48b6b45/results/mm10/processed_reads/b742f3789_6f48b6b45_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_b84d076d6/results/mm10/processed_reads/b742f3789_b84d076d6_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/D6_rep1/D6_rep1_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/D6_rep1/D6_rep1_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/D6_rep1/D6_rep1_ 10 50000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
