#!/bin/bash
#$ -N merger_full_MCF7_0_E2_60
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_MCF7_0_E2_60_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_MCF7_0_E2_60_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/MCF7_0_E2_60/MCF7_0_E2_60_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/ad1a9f5b0_c478f1d09/results/hg38_mmtv/processed_reads/ad1a9f5b0_c478f1d09_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/ad1a9f5b0_b362a771d/results/hg38_mmtv/processed_reads/ad1a9f5b0_b362a771d_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/MCF7_0_E2_60/MCF7_0_E2_60_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/MCF7_0_E2_60/MCF7_0_E2_60_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/MCF7_0_E2_60/MCF7_0_E2_60_ 10 100000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
