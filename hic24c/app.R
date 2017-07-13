#!/usr/bin/env Rscript

# dependencies

library("magrittr")
library("dplyr")
library("hicutils")
library("Matrix")
library("tidyr")
library("ggplot2"); theme_set(theme_minimal())
library("scales")
library("ggrepel")
library("zoo")
library("shiny")

theme_update(axis.text=element_text(size=12),
             axis.title=element_text(size=14, face="bold"),
             axis.line=element_line(size=1))

options(stringsAsFactors = F, scipen = 999)

# function to create download content

make_download_content <- function(dat, file) {

    zz <- paste("gzip -c >", file) %>%
        pipe("w")
    
    on.exit(close(zz))
    
    write.table(dat,
                zz, row.names = F,
                sep = "\t", quote = F)
    
}


# get file names

filenames <- read.delim("/mnt/cluster_4DGenome/data/hic/samples/merged_dryhic/file_names.tsv",
                        head = F) %>%
    setNames(c("name", "bamfile", "reso", "biasfile")) %>%
    filter(reso <= 10)

# UI

ui <- shinyUI(fluidPage(

    titlePanel("hic24c on merged datasets"),

    sidebarLayout(
        sidebarPanel(

            selectInput("insample",
                        label = "Select sample",
                        choices = filenames$name),
            br(),

            textInput("inregion",
                      "Bait region (chr:start-end)",
                      value = "chr6:151500000-152500000"),

            br(),

            numericInput("inw", "Size of the region of interest",
                         4e6, min = 2e5, max = 10e7),

            br(),
            
            numericInput("insmobin", "# of bins used to smooth",
                         5, min = 1, max = 20),

            br(),

            checkboxInput('printraw', 'Show raw data?', TRUE),

            br(),
            
            fileInput('featurefile', 'Choose feature file',
                      accept=c('text/csv',
                               'text/comma-separated-values,text/plain',
                               '.csv',
                               '.tsv')),

            helpText("The feature file should be a headerless TAB delimited file with the following fields:\nchromosome position id"),
            
            checkboxInput('printfeatures', 'Show features?', TRUE),
            
            br(),
            
            actionButton("fetch", "Fetch data")
            
        ),

        mainPanel(
            tabsetPanel(type = "tabs",
                        tabPanel("Raw", uiOutput("button_down_raw"), plotOutput("plotraw")),
                        tabPanel("Dryhic", uiOutput("button_down_dry"), plotOutput("plotdry")),
                        tabPanel("Scaled", numericInput("sca_ylim",
                                                        "Upper limit for the Y-scale",
                                                        -1),
                                 uiOutput("button_down_sca"),
                                 plotOutput("plotsca"))
                        )
        )
    )
))

# server

server <- shinyServer(function(input, output) {

    # stop until fetch pushed
    
    size <- eventReactive(input$fetch, input$inw / 2)
    thesample <- eventReactive(input$fetch, input$insample)
    theregion <- eventReactive(input$fetch, input$inregion)
    thesmobin <- eventReactive(input$fetch, input$insmobin)
    
    # do the magic

    dat <- reactive({

        # identify selection
    
        i <- which(filenames$name == thesample())
        
        inbam <- filenames$bamfile[i]
        inbias <- filenames$biasfile[i]
        inreso <- filenames$reso[i] * 1e3

        inregion <- theregion()
        inw <- size()

        coords <- gsub("^.*:", "", inregion) %>% strsplit("-") %>% unlist %>% as.numeric
        chrom <- gsub(":.*$", "", inregion)
        borders <- coords + c(-1, 1) * inw
        binborders <- c(floor(borders[1] / inreso) * inreso,
                        ceiling(borders[2] / inreso) * inreso)
        
        # get bins

        bins <- make_bins(inbam, inreso) %>%
            filter(chr == chrom,
                   pos >= binborders[1],
                   pos <= binborders[2]) %>%
            dplyr::select(pos)

        # get bias

        bias <- paste0("tabix ", inbias,
                       " ", chrom, ":",
                       binborders[1], "-",
                       binborders[2]) %>%
            pipe %>%
            read.delim(head = F) %>%
            setNames(c("chr", "pos", "tot", "fit"))

        bias <- setNames(bias$tot / bias$fit,
                         bias$pos)
        
        # get contacts
        
        raw4c <- system.file("src", "bam_to_4c.sh", package = "hicutils") %>%
            paste("-s", inw, inbam, inregion) %>%
            pipe %>%
            read.delim(head = F) %>%
            setNames(c("pos", "n")) %>%
            right_join(bins) %>%
            mutate(n = ifelse(is.na(n), 0, n),
                   dry = n / sqrt(bias[as.character(pos)])) %>%
            mutate(sca = dry / sum(dry, na.rm = T)) %>%
            mutate(dry = dry / sum(dry, na.rm = T) * sum(n, na.rm = T))

        dry4c <- with(raw4c, zoo(dry, pos))
        sca4c <- with(raw4c, zoo(sca, pos))
        raw4c <- with(raw4c, zoo(n, pos))

        rawmean4c <- rollmean(raw4c, thesmobin())
        drymean4c <- rollapply(dry4c, thesmobin(), mean, na.rm = T)
        scamean4c <- rollapply(sca4c, thesmobin(), mean, na.rm = T)
        
        down_raw <- rbind(data.frame(pos = index(raw4c),
                                    n = coredata(raw4c),
                                    type = "raw"),
                         data.frame(pos = index(rawmean4c),
                                    n = coredata(rawmean4c),
                                    type = "mean")) %>%
            as.data.frame %>%
            spread(type, n)

        down_dry <- rbind(data.frame(pos = index(dry4c),
                                    n = coredata(dry4c),
                                    type = "dry"),
                         data.frame(pos = index(drymean4c),
                                    n = coredata(drymean4c),
                                    type = "mean")) %>%
            as.data.frame %>%
            spread(type, n)

        down_sca <- rbind(data.frame(pos = index(sca4c),
                                     n = coredata(sca4c),
                                     type = "sca"),
                          data.frame(pos = index(scamean4c),
                                     n = coredata(scamean4c),
                                     type = "mean")) %>%
            as.data.frame %>%
            spread(type, n)

        baitbins <- which((index(raw4c) >= round(coords[1] / inreso) * inreso) &
                          (index(raw4c) <= round(coords[2] / inreso) * inreso)) +
            c(-1, 0, 1)

        raw4c[baitbins] <- NA
        rawmean4c[baitbins] <- NA
        dry4c[baitbins] <- NA
        drymean4c[baitbins] <- NA
        sca4c[baitbins] <- NA
        scamean4c[baitbins] <- NA

        print("hola")
        
        ggdat_raw <- rbind(data.frame(pos = index(raw4c),
                                      n = coredata(raw4c),
                                      type = "raw"),
                           data.frame(pos = index(rawmean4c),
                                      n = coredata(rawmean4c),
                                      type = "mean"))

        ggdat_dry <- rbind(data.frame(pos = index(dry4c),
                                      n = coredata(dry4c),
                                      type = "dry"),
                           data.frame(pos = index(drymean4c),
                                      n = coredata(drymean4c),
                                      type = "mean"))

        ggdat_sca <- rbind(data.frame(pos = index(sca4c),
                                      n = coredata(sca4c),
                                      type = "sca"),
                           data.frame(pos = index(scamean4c),
                                      n = coredata(scamean4c),
                                      type = "mean"))

        limy <- max(ggdat_raw$n,
                    ggdat_dry$n,
                    na.rm = T)

        features <- NULL
        
        if(!is.null(input$featurefile)){

            features <- read.delim(input$featurefile$datapath, head = F) %>%
                setNames(c("chr", "pos", "id")) %>%
                mutate(y = limy) %>%
                filter(chr == chrom)

        }
        
        
        list(ggdat_raw = ggdat_raw, ggdat_dry = ggdat_dry, ggdat_sca = ggdat_sca,
             features = features,
             down_raw = down_raw, down_dry = down_dry, down_sca = down_sca,
             limy = limy)
        
    })


    # plots

    output$plotraw <- renderPlot({

        ggdat <- dat()$ggdat_raw

        features <- dat()$features

        colraw <- ifelse(input$printraw, "black", NA)
        
        outplot <- ggplot(ggdat) +
            geom_line(aes(x = pos / 1e6,
                          y = n,
                          col = type,
                          alpha = type,
                          size = type)) +
            scale_x_continuous("Genomic positon / Mbp") +
            scale_y_continuous("# contacts") +
            scale_color_manual(values = c(raw = colraw, mean = "red")) +
            scale_alpha_manual(values = c(raw = .5, mean = 1)) +
            scale_size_manual(values = c(raw = .5, mean = 1)) +
            coord_cartesian(xlim = range(ggdat$pos) / 1e6, ylim = c(0, dat()$limy)) +
            guides(col = F, alpha = F, size = F)

        if(input$printfeatures & !is.null(features)){
            
            outplot <- outplot +
                geom_segment(data = features, aes(x = pos / 1e6, xend = pos / 1e6,
                                                  y = 0, yend = y,
                                                  label = id), col = "blue") +
                geom_label_repel(data = features, aes(x = pos / 1e6, y = y, label = id), col = "blue")
            
        }
        
        print(outplot)
        
    }, width = 600, height = 600)

    output$plotdry <- renderPlot({

        ggdat <- dat()$ggdat_dry

        features <- dat()$features

        colraw <- ifelse(input$printraw, "black", NA)
        
        outplot <- ggplot(ggdat) +
            geom_line(aes(x = pos / 1e6,
                          y = n,
                          col = type,
                          alpha = type,
                          size = type)) +
            scale_x_continuous("Genomic positon / Mbp") +
            scale_y_continuous("# contacts") +
            scale_color_manual(values = c(dry = colraw, mean = "red")) +
            scale_alpha_manual(values = c(dry = .5, mean = 1)) +
            scale_size_manual(values = c(dry = .5, mean = 1)) +
            coord_cartesian(xlim = range(ggdat$pos) / 1e6, ylim = c(0, dat()$limy)) +
            guides(col = F, alpha = F, size = F)

        if(input$printfeatures & !is.null(features)){
            
            outplot <- outplot +
                geom_segment(data = features, aes(x = pos / 1e6, xend = pos / 1e6,
                                                  y = 0, yend = y,
                                                  label = id), col = "blue") +
                geom_label_repel(data = features, aes(x = pos / 1e6, y = y, label = id), col = "blue")
            
        }
        
        print(outplot)
        
    }, width = 600, height = 600)

    output$plotsca <- renderPlot({

        ggdat <- dat()$ggdat_sca

        features <- dat()$features

        colraw <- ifelse(input$printraw, "black", NA)
        
        if(input$sca_ylim < 0){
            
            coords <- coord_cartesian(xlim = range(ggdat$pos) / 1e6)
            ymax <- max(ggdat$sca)

        }else{

            coords <- coord_cartesian(xlim = range(ggdat$pos) / 1e6,
                                      ylim = c(0, input$sca_ylim))
            ymax <- input$sca_ylim

        }

        outplot <- ggplot(ggdat) +
            geom_line(aes(x = pos / 1e6,
                          y = n,
                          col = type,
                          alpha = type,
                          size = type)) +
            scale_x_continuous("Genomic positon / Mbp") +
            scale_y_continuous("corrected contact score") +
            scale_color_manual(values = c(sca = colraw, mean = "red")) +
            scale_alpha_manual(values = c(sca = .5, mean = 1)) +
            scale_size_manual(values = c(sca = .5, mean = 1)) +
            guides(col = F, alpha = F, size = F) +
            coords

        if(input$printfeatures & !is.null(features)){
            
            outplot <- outplot +
                geom_segment(data = mutate(features, y = max(ggdat$sca)),
                             aes(x = pos / 1e6, xend = pos / 1e6,
                                                  y = 0, yend = ymax,
                                                  label = id), col = "blue") +
                geom_label_repel(data = mutate(features, y = ymax),
                                 aes(x = pos / 1e6, y = y, label = id), col = "blue")
            
        }
        
        print(outplot)
        
    }, width = 600, height = 600)

    # downloads

    output$button_down_raw <- renderUI({
        
        rr <- dat()
        
        downloadButton("down_raw", "Download")
        
    })
    

    filename_raw <- reactive(paste0(input$insample, "_",
                                    input$inregion %>% gsub(":-", "_", .),
                                    "_raw.tsv.gz"))
    

    content_raw <- function(filename) make_download_content(dat()$down_raw,
                                                            filename)
    
    output$down_raw <- downloadHandler(filename = function() filename_raw(),
                                       content = function(filename) content_raw(filename))

    output$button_down_dry <- renderUI({
        
        rr <- dat()
        
        downloadButton("down_dry", "Download")
        
    })
    

    filename_dry <- reactive(paste0(input$insample, "_",
                                    input$inregion %>% gsub(":-", "_", .),
                                    "_dry.tsv.gz"))
    

    content_dry <- function(filename) make_download_content(dat()$down_dry,
                                                            filename)
    
    output$down_dry <- downloadHandler(filename = function() filename_dry(),
                                       content = function(filename) content_dry(filename))

    output$button_down_sca <- renderUI({
        
        rr <- dat()
        
        downloadButton("down_sca", "Download")
        
    })
    

    filename_sca <- reactive(paste0(input$insample, "_",
                                    input$inregion %>% gsub(":-", "_", .),
                                    "_sca.tsv.gz"))
    

    content_sca <- function(filename) make_download_content(dat()$down_sca,
                                                            filename)
    
    output$down_sca <- downloadHandler(filename = function() filename_sca(),
                                       content = function(filename) content_sca(filename))

            
})

# put together

shinyApp(ui, server)

