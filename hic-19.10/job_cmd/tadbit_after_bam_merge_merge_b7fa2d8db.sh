#!/bin/bash
#$ -N tadbit_after_bam_merge_merge_b7fa2d8db
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/tadbit_after_bam_merge_merge_b7fa2d8db_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/tadbit_after_bam_merge_merge_b7fa2d8db_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/b7fa2d8db/b7fa2d8db_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/b7fa2d8db_bfac48760/results/mm10/processed_reads/b7fa2d8db_bfac48760_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b7fa2d8db_58e812fc2/results/mm10/processed_reads/b7fa2d8db_58e812fc2_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b7fa2d8db_4c96b48a9/results/mm10/processed_reads/b7fa2d8db_4c96b48a9_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b7fa2d8db_2c1678055/results/mm10/processed_reads/b7fa2d8db_2c1678055_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/b7fa2d8db/b7fa2d8db_both_map_merged.bam
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
