#!/bin/bash
#$ -N merger_full_Ba_rep1
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_Ba_rep1_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_Ba_rep1_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/Ba_rep1/Ba_rep1_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/a7c643d27_29726bc8f/results/mm10/processed_reads/a7c643d27_29726bc8f_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/a7c643d27_ed0f2b6ec/results/mm10/processed_reads/a7c643d27_ed0f2b6ec_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/a7c643d27_0a5e1eceb/results/mm10/processed_reads/a7c643d27_0a5e1eceb_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/a7c643d27_bf1e6102c/results/mm10/processed_reads/a7c643d27_bf1e6102c_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/Ba_rep1/Ba_rep1_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/Ba_rep1/Ba_rep1_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/Ba_rep1/Ba_rep1_ 10 50000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
