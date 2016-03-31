# README
---------------------------------------------------------------------------------------------------

Pipelines for the analysis of Hi-C data. Old versions of the pipelines are in `archived`. 


## GitHub repository
---------------------------------------------------------------------------------------------------

This GitHub repository was created with:
- created repository named `pipelines` at [https://github.com/4DGenome](https://github.com/4DGenome)
- move to the `/Volumes/users-project-4DGenome/pipelines` directory in my computer
- in the terminal:
```
git init
git remote add origin https://github.com/4DGenome/pipelines.git
git add "*"
git commit -m "create repo"
git push -u origin master
```

## Log
---------------------------------------------------------------------------------------------------

**2016-03-04**
- `chipseq-16.03` includes:
	- both single- (`SE`) and paired-end (`PE`) data are accepted in `sequencing_type`
	- when `io_mode=custom`, multiple samples are accepted in `samples`
	- input metadata (e.g. `SAMPLE_ID`, `READ_LENGTH`) and output metrics from the pipeline (e.g. `N_UNIQUE_READS`, `N_PEAKS`) can be added to the `beato_lab_metadata.db` database if `integrate_metadata=yes`
- `chipseq-16.02` is moved to `archived`

