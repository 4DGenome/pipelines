#!/bin/bash
#$ -N merger_full_D6_rep2
#$ -q long-sl65
#$ -l virtual_free=100G
#$ -l h_rt=24:00:00
#$ -o /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_D6_rep2_$JOB_ID.out
#$ -e /users/project/4DGenome/pipelines/hic-16.05/job_out/merger_full_D6_rep2_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 10
export PATH="/software/mb/el6.3/Conda/bin:$PATH"
python=`which python`
time0=$(date +"%s")
/software/mb/bin/samtools merge -rf -@ 10 /users/project/4DGenome_no_backup/data/hic/merged/D6_rep2/D6_rep2_both_map_merged.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_ae7e2295e/results/mm10/processed_reads/b742f3789_ae7e2295e_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_80eedabee/results/mm10/processed_reads/b742f3789_80eedabee_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_e7bdfae99/results/mm10/processed_reads/b742f3789_e7bdfae99_both_map.bam /users/project/4DGenome_no_backup/data/hic/samples/b742f3789_4e6781c38/results/mm10/processed_reads/b742f3789_4e6781c38_both_map.bam
/software/mb/bin/samtools index /users/project/4DGenome_no_backup/data/hic/merged/D6_rep2/D6_rep2_both_map_merged.bam
$python /users/project/4DGenome/pipelines/hic-16.05/scripts/tadbit_after_bam_v2_bigbam_include_chromosome.py /users/project/4DGenome_no_backup/data/hic/merged/D6_rep2/D6_rep2_both_map_merged.bam 783 0 99 /users/project/4DGenome_no_backup/data/hic/merged/D6_rep2/D6_rep2_ 10 50000 50000
time1=$(date +"%s")
echo "job length was $(($time1-$time0)) seconds"
