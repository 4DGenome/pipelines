#!/usr/bin/env Rscript

# dependencies

library('dplyr')
library('magrittr')
library('Matrix')
library('viridis')
library('shiny')

options(stringsAsFactors = F, scipen = 999)

# ICE norm

ICE <- function(mat, itermax = 1, maxdev = .1){

    b <- attr(mat, "b")
    
    if(is.null(b)){
           
        b <- rep(1, ncol(mat))

    }

    bads <- attr(mat, "bads")

    if(is.null(bads)){
           
        bads <- rep(FALSE, ncol(mat))

    }
    
    for(i in 1:itermax){
    
        s <- colSums(mat, na.rm = T)
        s[bads] <- NA
        sm <- sum(s, na.rm = T) / sum(!is.na(s))
        
        delta_b <- (s / sm)
        
        B <- Diagonal(x = 1 / delta_b)
        
        b <- b * delta_b
        
        mat <- B %*% (mat %*% B)
        
        dev <- abs((s / sm - 1)) %>% max(na.rm = T)
        
        paste(i,
              min(s, na.rm = T) %>% format(digits = 2),
              sm %>% format(digits = 2),
              max(s, na.rm = T) %>% format(digits = 2),
              dev %>% format(digits = 5),
              "\n",
              sep = "\t") %>%
            cat

        if(dev < maxdev) break

    }

    attr(mat, "b") <- b
   
    mat

}

# raw counts

counts <- function(inbam, region, progress, filterin = 0, filterex = 1799, resolution, pos){

    progress$inc(progress$getValue() + 1,
                 detail = basename(inbam) %>% gsub("_both_map.bam", "", .) %>% paste("Processing sample", .))
    
    paste("./get_contacts_from_bam.sh",
          inbam, region, filterin, filterex, resolution) %>%
        pipe %>%
        read.delim(head = F) %>%
        mutate(b1 = factor(V1, levels = pos),
               b2 = factor(V2, levels = pos)) %>%
        xtabs(V3 ~ b1 + b2, ., sparse = T)
    
}


# distance decay

get_decay <- function(mat){

    pos <- rownames(mat) %>% as.numeric
    
    dis <- abs(rep(pos, diff(mat@p)) - pos[mat@i + 1])
    
    avg <- data.frame(d = dis,
                      x = mat@x) %>%
        group_by(d) %>%
        summarize(mean = mean(x, na.rm = T)) %>%
        with(setNames(mean, d))

    avg
    
}

apply_decay <- function(mat, avg){

    pos <- rownames(mat) %>% as.numeric
    
    dis <- abs(rep(pos, diff(mat@p)) - pos[mat@i + 1])
    
    mat@x <- mat@x / avg[as.character(dis)]

    mat
    
}

# correlation of sparse matrix

sparse_cor <- function(x){

    n <- nrow(x)

    cMeans <- colMeans(x)
    cSums <- colSums(x)

    # Calculate the population covariance matrix.
    # There's no need to divide by (n-1) as the std. dev is also calculated the same way.
    # The code is optimized to minize use of memory and expensive operations
    covmat <- tcrossprod(cMeans, (-2 * cSums + n * cMeans))
    crossp <- as.matrix(crossprod(x))
    covmat <- covmat + crossp

    sdvec <- sqrt(diag(covmat)) # standard deviations of columns
    covmat / crossprod(t(sdvec)) # correlation matrix
}

# wrap it all

wrap <- function(inbam, chrom, resolution, filterin, filterex, progress,
                 pzero = .999, itermax =  1, maxdev = .1, wei_total = F){

    # prepare data

    progress$inc(progress$getValue() + 1, detail = "Getting bins")

    size <- paste("samtools view -H", inbam[1]) %>%
        pipe %>%
        read.delim(head = F) %>%
        mutate(V2 = gsub("^SN:", "", V2),
               V3 = gsub("^LN:", "", V3)) %>%
        filter(V2 == chrom) %$%
        V3 %>%
        as.numeric

    pos <- seq(0, floor(size / resolution) * resolution, by = resolution)

    # get data

    cat("getting counts ...\n\n")

    dat <- parallel::mclapply(inbam, counts,
                              region = chrom, filterin = filterin, filterex = filterex,
                              resolution = resolution, pos = pos, progress = progress,
                              mc.cores = 4)
    
    if(wei_total){
        
        avg_total<- sapply(dat, sum) %>% mean

        dat <- lapply(dat, function(x) x / sum(x) * avg_total)

        }

    progress$inc(progress$getValue() + 1, detail = "Adding samples")

    dat <- Reduce("+", dat)

    # filter

    progress$inc(progress$getValue() + 1, detail = "Filtering zeros")

    paste("filtering bins with more than",
          round(nrow(dat) * pzero),
          "zeros ...\n\n") %>%
        cat

    dat0 <- dat
    
    bads <- colSums(dat == 0) > (nrow(dat) * pzero)

    attr(dat, "bads") <- bads
    attr(dat0, "bads") <- bads

    paste(sum(bads),
          "bins removed\n\n") %>%
        cat
    
    # normalize

    progress$inc(progress$getValue() + 1, detail = "Normalizing")
   
    cat("normalizing ...\n\n")
    paste("i", "min", "avg", "max", "dev\n", sep = "\t") %>%
        cat
    
    dat_norm <- ICE(dat, itermax = itermax, maxdev = maxdev)
   
    # get decay

    progress$inc(progress$getValue() + 1, detail = "Getting decay")

    cat("\ncomputing distance decay ...\n\n")

    decay <- get_decay(dat_norm)
    
    dat_norm_decay <- apply_decay(dat_norm, decay)

    # get correlation

    progress$inc(progress$getValue() + 1, detail = "Computing correlation")
    
    cat("computing correlation ...\n\n")

    dat_cor <- sparse_cor(dat_norm_decay)
    diag(dat_cor) <- NA
    
    # output

    cat("DONE: Matrices are ready!\n\n")

    out <- list(raw = dat0,
                nor = dat_norm,
                cor = dat_cor)

    attr(out, "size") <- size

    out

}

# plot

plot_matrix <- function(mat, coord, resolution, m1 = NULL, m2 = NULL,
                        transformation = function(x) log10(x + min(x[x>0], na.rm = TRUE)/2),
                        color = viridis(100), sym = FALSE, trim = .01,
                        unit_x_axis = 1e6,
                        label_x_axis = "Genomic Position / Mbp",
                        ...){
    
    # prepare matrix

    lims <- seq(floor(coord[1] / resolution),
                ceiling(coord[2] / resolution)) * resolution
    
    i <- rownames(mat) %in% lims
    
    mat <- as.matrix(mat[i, i])
    mat <- mat[match(lims, rownames(mat)), match(lims, rownames(mat))]
    rownames(mat) <- colnames(mat) <- lims

    # prepare axis info and parameters

    guides <- pretty(x = rownames(mat) %>% as.numeric)
    par(mar = c(4, 0, 0, 0), pty = "s")

    # trimm

    if(trim > 0){

        trim <- as.matrix(mat) %>% c %>% quantile(c(trim / 2, 1 - trim / 2), na.rm = T)
        mat[mat < trim[1]] <- trim[1]
        mat[mat > trim[2]] <- trim[2]

    }
    
    # prepare range of colors

    x <- as.matrix(mat) %>% transformation %>% as.matrix
    if(sym){

        upper <- max(abs(x), na.rm = T)
        lower <- - upper
        
    }else{
        
        lower <- min(x, na.rm = T)
        upper <- max(x, na.rm = T)
        
    }

    # transform scores into colors

    if(max(x, na.rm = T) == min(x, na.rm = T)){
        x[] <- color[round(length(color) / 2)]
    }else{
        x[] <- color[cut(c(x), seq(lower, upper,
                                   len = length(color) + 1), include = T)]
    }
    
    # get limits of genomic region

    range_pos <- as.numeric(rownames(x)) %>% range

    # get matrix dimensions
    
    nr <- nrow(x)
    nc <- ncol(x)
    d <- sqrt(nr^2 + nc^2)
    d2 <- 0.5 * d

    # plot void region

    plot(NA, type="n",
         xlim=c(0, d), ylim=c(-nc / 2, nc / 2),
         xlab=label_x_axis
        ,
         ylab="",
         asp=1, axes = F, cex.lab = 1.5, ...)

    # add heatmap

    rasterImage(as.raster(unclass(x)),
                xleft = d2, xright = d2 + nc, ybottom = -d2, ytop = -d2 + nr,
                interpolate = FALSE, angle = 45)
    axis(1, at = d * (guides - range_pos[1]) / (range_pos[2] - range_pos[1]),
         labels = guides / unit_x_axis, cex.axis = 1.5)
    if(!is.null(m1) & !is.null(m2)) axis(2, at = c(-nc / 2, nc / 2) / 2, labels = c(m1, m2))
    
    invisible()
    
}


# get only raw contacts

wrap_raw <- function(inbam, chrom, resolution, filterin = 0, filterex = 1799, wei_total = F){

    # prepare data

    size <- paste("samtools view -H", inbam[1]) %>%
        pipe %>%
        read.delim(head = F) %>%
        mutate(V2 = gsub("^SN:", "", V2),
               V3 = gsub("^LN:", "", V3)) %>%
        filter(V2 == chrom) %$%
        V3 %>%
        as.numeric

    pos <- seq(0, floor(size / resolution) * resolution, by = resolution)

    # get data

    cat("getting counts ...\n\n")
    
    dat <- parallel::mclapply(inbam, counts,
                              region = chrom, filterin = filterin, filterex = filterex,
                              resolution = resolution, pos = pos,
                              mc.cores = 4)

    if(wei_total){
        
        avg_total<- sapply(dat, sum) %>% mean

        dat <- lapply(dat, function(x) x / sum(x) * avg_total)

        }

    dat

}

# process from raw contacts on

wrap_from_raw <- function(mat, pzero = .999, itermax = 1, maxdev = .1, wei_total = F){

    # prepare mata

    pos <- rownames(mat) %>% as.numeric

    # filter

    paste("filtering bins with more than",
          round(nrow(mat) * pzero),
          "zeros ...\n\n") %>%
        cat

    mat0 <- mat
    
    bads <- colSums(mat == 0) > nrow(mat) * pzero

    mat <- mat[!bads, !bads]
    
    pos <- pos[!bads]

    paste(sum(bads),
          "bins removed\n\n") %>%
        cat
    
    # normalize

    cat("normalizing ...\n\n")
    paste("i", "min", "avg", "max", "dev\n", sep = "\t") %>%
        cat
    
    mat_norm <- ICE(mat, itermax = itermax, maxdev = maxdev)

    # get decay

    cat("\ncomputing distance decay ...\n\n")

    decay <- get_decay(mat_norm)
    
    mat_norm_decay <- apply_decay(mat_norm, decay)

    # get correlation

    cat("computing correlation ...\n\n")

    mat_cor <- sparse_cor(mat_norm_decay)

    # output

    cat("DONE: Matrices are ready!\n\n")

    list(nor = mat_norm,
         cor = mat_cor)

}

# get bam paths

get_bam_path <- function(sampleid){

    paste0("/mnt/cluster_4DGenome/data/hic/samples/",
           sampleid,
           "/results/") %>%
        list.files(patt = ".bam$", rec = TRUE, full = TRUE)

}

# strip region

strip_region <- function(region){

    strsplit(region, "[:-]") %>% unlist

}

# function to combine 2 contact matrices

combine_contacts <- function (x1, x2, common.scale = F, diag.value = NA) {

    if(is.null(x1)) return(x2)
    if(is.null(x2)) return(x1)
    
    ## pos1 <- rownames(x1)
    ## pos2 <- rownames(x2)
    ## pos <- c(pos1, pos2) %>% unique %>% as.numeric %>% sort %>% 
    ##     format
    ## x1 <- x1[pos, pos]
    ## x2 <- x2[pos, pos]
    ## x1[is.na(x1)] <- 0
    ## x2[is.na(x2)] <- 0
    if (common.scale) {
        m1 <- max(x1)
        m2 <- max(x2)
        m <- max(m1, m2)
        x1 <- x1/m1 * m
        x2 <- x2/m1 * m
    }
    xboth <- x1
    xboth[upper.tri(xboth)] <- x2[upper.tri(xboth)]
    if (!is.null(diag.value)) 
        diag(xboth) <- diag.value
    xboth
}

# get matrix

get_matrix <- function(mat, resolution, coord = NULL){
    
    if(!is.null(coord)){
        
        lims <- seq(floor(coord[1] / resolution),
                    ceiling(coord[2] / resolution)) * resolution
        
        i <- rownames(mat) %in% lims
        
        mat <- as.matrix(mat[i, i])
        mat <- mat[match(lims, rownames(mat)), match(lims, rownames(mat))]
        rownames(mat) <- colnames(mat) <- lims

    }else{

        mat <- as.matrix(mat)

    }

    mat

}

# produce download handler

make_download_content <- function(mat, file, resolution, region = NULL) {

    zz <- paste("gzip -c >", file) %>%
        pipe("w")
    
    on.exit(close(zz))
    
    if(is.null(region)){
        
        write.table(get_matrix(mat, resolution) %>% format(digits = 6),
                    zz, col.names = NA, row.names = T,
                    sep = "\t", quote = F)
        
    }else{
        
        write.table(get_matrix(mat, resolution, region) %>% format(digits = 6),
                    zz, col.names = NA, row.names = T, sep = "\t", quote = F)
        
    }

}

make_download_filename <- function(chromosome, resolution, region = NULL){
    
    if(is.null(region)){
        
        paste0(chromosome, "_", resolution, "Kbp.tsv.gz")
        
    }else{
        
        paste0(chromosome, ":", region[1], "-", region[2], "_", resolution, "Kbp.tsv.gz")
        
    }
}
