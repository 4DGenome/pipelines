#==================================================================================================
# Created on: 2016-04-04
# Usage: in R: shinyApp(ui, server)
# Author: Javier Quilez (GitHub: jaquol)
# Goal: launches hisee-XX.XX --a visualisation tool for the Hi-C data generated with the hic-XX.XX pipeline
#==================================================================================================


#==================================================================================================
# CONFIGURATION
#==================================================================================================

# Load R packages 
require('gtools')
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library("RSQLite")

# Paths
DATA <- '/Volumes/users-project-4DGenome_no_backup/data/hic/samples'
metadata <- '/Volumes/users-project-4DGenome/data/4DGenome_metadata.db'

# Samples
samples <- mixedsort(dir(DATA))

# Types of reads
reads_types <- c("Mapped" = "mapped",
					"Filtered" = "filtered",
					 "Dangling-end" = "dangling_end",
					 "Self-circle end" = "self_circle")

# Load metadata
db <- src_sqlite(metadata)
input_metadata <- tbl(db, "input_metadata")
quality_control_raw_reads <- tbl(db, 'quality_control_raw_reads')
hic <- tbl(db, "hic")
jobs <- tbl(db, "jobs")



#==================================================================================================
# USER INTERFACE (UI)
#==================================================================================================

# Header
header <- dashboardHeader(title = "hisee-16.04 (4DGenome visualisation tool)")


# Side bar
sidebar <-  dashboardSidebar(
	sidebarMenu(
		menuItem("Sample summary", tabName = "sample_summary"),
#		menuItem("Coverage", tabName = "coverage"),
#		menuItem("Interaction matrices", tabName = "interaction_matrices"),
#		menuItem("Replicability", tabName = "replicability"),
#		menuItem("Metrics", tabName = "metrics"),
#		menuItem("Project progress", tabName = "project_progress"),
		menuItem("Performance", tabName = "performance")	
	)
)


# Body
body <- dashboardBody(

	tabItems(

		# Sample summary
		tabItem(tabName = "sample_summary",

			# Select sample
			fluidRow(column(3, selectInput("sample", label = h2("Select sample"), choices = samples, selected = "TE_S_T"))),

			# Summary of input metadata
			fluidRow(column(12, h2("Input metadata"))),
			fluidRow(column(12, box(tableOutput("input_metadata"), width = 12))),

			# Pre-mapping quality control
			fluidRow(column(12, h2("Pre-mapping quality control"))),
			# FastQC reports of raw reads, and number of raw/processed reads
			fluidRow(column(12, box(title = "FastQC flags", tableOutput("fastqc_flags"), width = 12))),
			# Quality metrics and plots
			fluidRow(column(12, box(title = "Quality metrics and plots", width = 12,
						h4("Read1"), imageOutput("read1"),
						h4("Read2"), imageOutput("read2")))),

			# Post-mapping Statistics
			fluidRow(column(12, h2("Post-mapping statistics"))),
			fluidRow(column(12, box(title = "Mapping efficiency", width = 6, imageOutput("proportion_mapped_reads")),
								box(title = "Dangling-ends", width = 6, imageOutput("distribution_dangling_ends_lengths")))),
			fluidRow(column(12, box(title = "Decay of interactions with distance", width = 6, imageOutput("decay_interaction_counts_genomic_distance")),
								box(title = "Interaction matrix of mapped reads", width = 6, imageOutput("matrix_mapped")))),

			# Post-filtering statistics
			fluidRow(column(12, h2("Post-filtering statistics"))),
			fluidRow(column(12, box(title = "Summary of excluded reads", width = 8, tableOutput("excluded_reads")))),
			fluidRow(column(12, box(title = "Interaction matrix of filtered reads", width = 12, imageOutput("matrix_filtered", height = 750)))),

			# Overall sequencing coverage distribution
			fluidRow(column(9, box(title = "1-Mb coverage distribution", plotOutput("overall_coverage"), width = 12)),
					column(3, checkboxGroupInput("overall_coverage_read_type", label = h3("Select read type"), choices = reads_types, selected =reads_types[1]),
						h3("Display options"),
						sliderInput("overall_coverage_xlim", label = h5("X-axis range"), min = 0, max = 1000, value = 100),
						sliderInput("overall_coverage_ylim", label = h5("Y-axis range"), min = 0, max = 1500, value = 150))),

			# Scatter plot of coverage
			fluidRow(column(9, box(title = "Scatter plot of 1-Mb coverages", plotOutput("scatter_coverage"), width = 12)),
					column(3, checkboxGroupInput("scatter_coverage_read_type", label = h3("Selec read type"), choices = reads_types, selected = c(reads_types[1], reads_types[2])),
						h3("Display options"),
						sliderInput("scatter_coverage_xlim", label = h5("X-axis range"), min = 0, max = 1500, value = 150),
						sliderInput("scatter_coverage_ylim", label = h5("Y-axis range"), min = 0, max = 1500, value = 150))),

			# Chromosome plots of coverage
			fluidRow(column(9, box(title = "Chromosome plots of coverage", plotOutput("chromosome_coverage", height = 1250), width = 12, height = 1500)),
					column(3, h3("Display options"), sliderInput("chromosome_coverage_ylim", label = h5("Y-axis range"), min = 0, max = 500, value = 150)))

		),

		# Performance
		tabItem(tabName = "performance")

	)

)

ui <- dashboardPage(header, sidebar, body)



#==================================================================================================
# SERVER
#==================================================================================================

# Plotting parameters
read_type_to_color <- list('mapped' = rgb(190/255, 190/255, 190/255, 0.5),
							'filtered' = rgb(0, 128/255, 1, 0.5),
							'dangling_end' = rgb(1, 102/255, 102/255, 0.5),
							'self_circle' = rgb(1, 102/255, 178/255, 0.5))

# Load existing images/plots
call_renderImage <- function(name, my_session = session, my_input = input){
	renderImage({
        width  <- my_session$clientData[[paste0("output_", name, "_width")]]
        height <- my_session$clientData[[paste0("output_", name, "_height")]]
		filename <- normalizePath(Sys.glob(file.path(DATA, my_input$sample, "*", "*", "*",
			paste0("*", name, "*.png"))))
		print(filename)
		list(src = filename, alt = "image number", width = width, height = height)
	}, deleteFile = FALSE)
}

server <- function(input, output, session, plot) {

	# Summary of input metadata
	output$input_metadata <- renderTable({
		df <- data.frame(t(data.frame(filter(input_metadata, SAMPLE_ID == input$sample))))
		names(df) <- c("Value")
	df$field <- rownames(df)
	my_order <- c("Timestamp", "SAMPLE_ID", "CELL_TYPE", "PRE_TREATMENT", "PRE_TREATMENT_TIME", "TREATMENT", "TREATMENT_TIME",
					"CONTROL", "EXPERIMENT_ID", "HIC", "SEQUENCING_PRE_LIBRARY", "SEQUENCING_LIBRARY", "SEQUENCING_CORE",
					"SEND_FOR_SEQUENCING_ON", "USER", "SAMPLE_NAME", "EXPERIMENT", "SPECIES", "DNA_CONCENTRATION", "SEQUENCING_INDEX",
					"ILLUMINA_MACHINE", "APPLICATION", "READ_LENGTH", "RESTRICTION_ENZYME", "SEQUENCING_TYPE", "NOTES")
	df[match(my_order, df$field), 1:2]
	})

	# FastQC reports of raw reads
	output$fastqc_flags <- renderTable({
		read1 <- data.frame(filter(select(quality_control_raw_reads, starts_with("READ1_")), SAMPLE_ID == input$sample))
		read2 <- data.frame(filter(select(quality_control_raw_reads, starts_with("READ2_")), SAMPLE_ID == input$sample))
		names(read1) <- gsub('READ1_', '', names(read1))
		names(read2) <- gsub('READ2_', '', names(read2))
		df <- data.frame(t(read1), t(read2))
		names(df) <- c("READ1", "READ2")
		df <- df[-c(1), ]
		df
	})

	# Quality metrics
	output$quality_metrics <- renderTable({
		df1 <- data.frame(hic %>%
			filter(SAMPLE_ID == input$sample) %>%
			select(starts_with("PERCENTAGE_")) %>%
			select(contains("READ1"))
			)
		df2 <- data.frame(hic %>%
			filter(SAMPLE_ID == input$sample) %>%
			select(starts_with("PERCENTAGE_")) %>%
			select(contains("READ2"))
			)
		names(df1) <- gsub('_READ1', '', names(df1))
		names(df2) <- gsub('_READ2', '', names(df2))
		df <- data.frame(t(df1), t(df2))
		names(df) <- c("READ1", "READ2")
		df		
	})

	# Load existing images/plots
	output$read1 <- call_renderImage("read1", session, input)
	output$read2 <- call_renderImage("read2", session, input)
	output$proportion_mapped_reads <- call_renderImage("proportion_mapped_reads", session, input)
	output$distribution_dangling_ends_lengths <- call_renderImage("distribution_dangling_ends_lengths", session, input)
	output$decay_interaction_counts_genomic_distance <- call_renderImage("decay_interaction_counts_genomic_distance", session, input)
	output$matrix_mapped <- call_renderImage("matrix_mapped", session, input)
	output$matrix_filtered <- call_renderImage("matrix_filtered", session, input)

	# Summary of exclude reads
	output$excluded_reads <- renderTable({
		df <- data.frame(t(data.frame(hic %>%
				filter(SAMPLE_ID == input$sample) %>%
				select(starts_with("EXCLUDED_"))
				)))
		names(df) <- 'values'
	n <- c()
	f <- c()
	for (i in df$values) {
		nc <- strsplit(i, ";")
		n <- c(n, as.integer((nc[[1]][1])))
		f <- c(f, as.numeric((nc[[1]][2])))
	}
	df$N_EXCLUDED_READS <- n
	df$FRACTION_EXCLUDED_READS <- f
	df$IS_APPLIED <- 'no'
	df["EXCLUDED_SELF_CIRCLE", "IS_APPLIED"] <- 'yes'
	df["EXCLUDED_DANGLING_END", "IS_APPLIED"] <- 'yes'
	df["EXCLUDED_ERROR", "IS_APPLIED"] <- 'yes'
	df["EXCLUDED_DUPLICATED", "IS_APPLIED"] <- 'yes'
	df["EXCLUDED_RANDOM_BREAKS", "IS_APPLIED"] <- 'yes'	
	df[, 2:4]
	})

	# Overall coverage distribution for different types of reads
	output$overall_coverage <- renderPlot({
		a = 0
		for (r in input$overall_coverage_read_type) {
			infile <- Sys.glob(file.path(DATA, input$sample, "*/*/genomic_coverages", paste0("*", r, "*.bed")))
			df <- read.delim(infile)
			bins <- seq(0, 2e3)
			my_colors = c()
			hist(df$read_counts/1e3,
					col = read_type_to_color[[r]],
					add = ifelse(a == 0, F, T),
					breaks = bins,
					border = F,
					xlim = c(0, input$overall_coverage_xlim),
					ylim = c(0, input$overall_coverage_ylim),
					main = input$sample,
					xlab = "No. reads x 1,000 / Mb",
					ylab = "Number of 1-Mb bins")
			my_colors = c(my_colors, read_type_to_color[[r]])
			a = a + 1
		}
		legend(input$overall_coverage_xlim * 0.8, input$overall_coverage_ylim * 0.8,
				names(read_type_to_color),
				fill = unlist(read_type_to_color, use.names=F),
				bty = "n")
	})

	# 2-way scatter plot of coverage (e.g. mapped vs filtered reads)
	output$scatter_coverage <- renderPlot({
		infile1 <- Sys.glob(file.path(DATA, input$sample, "*/*/genomic_coverages", paste0("*", input$scatter_coverage_read_type[[1]], "*.bed")))
		infile2 <- Sys.glob(file.path(DATA, input$sample, "*/*/genomic_coverages", paste0("*", input$scatter_coverage_read_type[[2]], "*.bed")))
		df1 <- read.delim(infile1)
		df2 <- read.delim(infile2)
		df1$read_counts <- df1$read_counts / 1e3
		df2$read_counts <- df2$read_counts / 1e3
		label1 <- input$scatter_coverage_read_type[[1]]
		label2 <- input$scatter_coverage_read_type[[2]]
		dat <- merge(df1, df2, by = names(df1)[1:3])
		names(dat) <- c("chrom", "start", "end", label1, label2)
		ggplot(dat, aes_string(x = label1, y = label2)) + 
				geom_point(shape = 1) +	
				geom_smooth(method = lm) +
				xlab(paste(label1, "(No. reads x1,000 / Mb)")) + xlim(0, input$scatter_coverage_xlim) +
				ylab(paste(label2, "(No. reads x1,000 / Mb)")) + ylim(0, input$scatter_coverage_ylim) +
				ggtitle(input$sample)
	})

	# Chromosome plots of coverage
	output$chromosome_coverage <- renderPlot({
		df_combined <- data.frame()
		for (r in reads_types) {
			infile <- Sys.glob(file.path(DATA, input$sample, "*/*/genomic_coverages", paste0("*", r, "*.bed")))
			df <- read.delim(infile)
			df$read_type <- r
			df_combined <- rbind(df_combined, df)
		}
		#df_combined$start_mb <- df_combined$start / 1e6
		df_combined$chrom <- factor(df_combined$chrom, levels = unique(as.vector(df_combined$chrom)))
		ggplot(df_combined, aes(x = start/1e6, y = read_counts/1e3, group = read_type, colour = read_type)) +
		geom_line() +
		facet_grid(chrom ~ .) +
		xlab("Position on chromosome (Mb)") +
		ylab("No. reads x1,000 / Mb") + ylim(0, input$chromosome_coverage_ylim) +
		ggtitle(input$sample)
	})


}






shinyApp(ui, server)

