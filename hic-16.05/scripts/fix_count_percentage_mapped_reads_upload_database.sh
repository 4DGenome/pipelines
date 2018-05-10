#==================================================================================================
# CONFIGURATION VARIABLES AND PATHS
#==================================================================================================

#variables and paths
metadata_db=/users/project/4DGenome/data/4DGenome_metadata_backup.db
query="select SAMPLE_ID from input_metadata" #generate query for DB
samples=$(sqlite3 $metadata_db "$query" | tr "\n" " " | sort | uniq | sed 's, $,,1') #Get all sample IDs

for s in $samples; do
  query="select ASSEMBLY_VERSION from hic WHERE SAMPLE_ID='$s';"
  assembly=$(sqlite3 $metadata_db "$query")
  if [ $assembly != '' ];
  then
    mapped_file=/users/project/4DGenome_no_backup/data/hic/samples/$s/results/$assembly/processed_reads/$s\_per_mapped_reads.text
    if [ -s $mapped_file ];
    then
      mapped_reads=$(</users/project/4DGenome_no_backup/data/hic/samples/$s/results/$assembly/processed_reads/$s\_per_mapped_reads.text)
      query="UPDATE hic SET TOTAL_UNIQUE_MAPPED_READS = '$mapped_reads' WHERE SAMPLE_ID = '$s';" #generate query for DB
      sqlite3 $metadata_db "$query" #Assign the value to the database field
    else
      echo $s >> failed_mappings.txt
    fi
  fi

done
