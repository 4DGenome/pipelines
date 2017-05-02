#!/bin/bash
#$ -N merger_full_siSA1
#$ -q long-sl7
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_siSA1_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_siSA1_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/el7.2/anaconda2/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/siSA1/siSA1_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/ALA_5/results/hg38_mmtv/processed_reads/ALA_5_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/ALA_8_2/results/hg38_mmtv/processed_reads/ALA_8_2_both_map.bam
/software/mb/el7.2/anaconda2/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/siSA1/siSA1_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/siSA1/siSA1_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/siSA1/siSA1_ 10 100000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
