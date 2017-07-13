#!/user/bin/env Rscript

# dependencies

library("magrittr")
library("dplyr")

options(stringsAsFactors = F)

# get data

files <- list.files("~/Downloads/test", full = T)

dat <- lapply(files, gzfile) %>% lapply(read.delim, row.names = 1, skip = 1, head = F)

lapply(dat, nrow)

lapply(dat, sum)

identical(dat[[2]], dat[[4]])

hola <- gzfile("~/Downloads/chr6_500Kbp.tsv.gz") %>%
    read.delim(row.names = 1, skip = 1, head = F)

identical(hola, dat[[1]])
