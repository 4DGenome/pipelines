#!/bin/bash
#$ -N merger_full_BLAER
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_BLAER_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_BLAER_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/BLAER/BLAER_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/9cecf0755_ac9f54f0a/results/hg38_mmtv/processed_reads/9cecf0755_ac9f54f0a_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/9cecf0755_7a34e3605/results/hg38_mmtv/processed_reads/9cecf0755_7a34e3605_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/BLAER/BLAER_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/BLAER/BLAER_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/BLAER/BLAER_ 10 100000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
