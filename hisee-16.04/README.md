# README
----------------------------------------------------------------------------------------------------

**objective: app for the visualisation of Hi-C data generated with the hic-XX.XX pipeline**


## Development
----------------------------------------------------------------------------------------------------

To make changes/tests and quickly see output, in my computer:
```
cd /Volumes/users-project-4DGenome/pipelines/hisee-16.04
R
source("app.R")
shinyApp(ui, server)
```


## Permanent
----------------------------------------------------------------------------------------------------

The permanent version is hosted in the 4DGenome workstation and accessed through an URL.
```
# Connect to 4DGenome workstation
ssh -X four-d@172.17.133.110
# Make destination directory
sudo mkdir /srv/shiny-server/hisee-16.04
# Copy the app there
sudo scp jquilez@ant-login.linux.crg.es:/users/project/4DGenome/pipelines/hisee-16.04/app.R /srv/shiny-server/hisee-16.04
```

Modify paths in `app.R` so that it reads:
```
# Paths
DATA <- '/mnt/cluster_4DGenome_no_backupdata/data/hic/samples'
metadata <- '/mnt/cluster_4DGenome/data/4DGenome_metadata.db'
```

[this URL](http://172.17.133.110:3838/hisee-16.04/)