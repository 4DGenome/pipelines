#!/bin/bash
#$ -N merger_full_T47D_DRB_0_0
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_T47D_DRB_0_0_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_T47D_DRB_0_0_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/T47D_DRB_0_0/T47D_DRB_0_0_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/d7fd92b4c_95a8cd511/results/hg38_mmtv/processed_reads/d7fd92b4c_95a8cd511_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/d7fd92b4c_0e31e17c7/results/hg38_mmtv/processed_reads/d7fd92b4c_0e31e17c7_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/T47D_DRB_0_0/T47D_DRB_0_0_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/T47D_DRB_0_0/T47D_DRB_0_0_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/T47D_DRB_0_0/T47D_DRB_0_0_ 10 100000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
