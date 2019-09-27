#!/bin/bash
#$ -N merger_merge_HICHIP_Input_R30
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_merge_HICHIP_Input_R30_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_merge_HICHIP_Input_R30_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/HICHIP_Input_R30/HICHIP_Input_R30_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/9a7c4a68d_04f8bf765/results/hg38_mmtv/processed_reads/9a7c4a68d_04f8bf765_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/9a7c4a68d_22a76dcda/results/hg38_mmtv/processed_reads/9a7c4a68d_22a76dcda_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/HICHIP_Input_R30/HICHIP_Input_R30_both_map_merged.bam
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
