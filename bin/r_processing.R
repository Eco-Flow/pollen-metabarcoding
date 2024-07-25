#!/usr/bin/Rscript
library(dplyr)
library(hash)

args <- commandArgs(trailingOnly = TRUE)
small<- strsplit(args[1], "[.]")[[1]][2]

data <- read.table(args[1], header=F, sep="\t")
data <- data %>% mutate_all(na_if,"")

id <- data.frame(do.call('rbind', strsplit(as.character(data$V1), ';', fixed=TRUE)))[1]

size <- data.frame(do.call('rbind', strsplit(as.character(data$V1), '=', fixed=TRUE)))[2]
size$X2 <- as.numeric(size$X2)

classif <- data.frame(do.call('rbind', strsplit(as.character(data$V2),',',fixed=TRUE)))

h <- hash(k="kingdom", p="phylum", c="class", o="order", f="family", g="genus", s="species")

tax_vars = c()
outdf = c()
outdf <- cbind(id)
tablecolnames <- c("sample")

for (x in 1:length(classif) ) {
	tvar=paste0("X", x)
	my_res<-data.frame(do.call('rbind', strsplit(gsub(")", "",classif[[tvar]] ),'(',fixed=TRUE)))
	my_tax <- strsplit(my_res$X1[1],':')[[1]][1]
	full_name<- h[[paste0(strsplit(my_res$X1[1],':')[[1]][1])]]
	my_res$X1 <- strsplit(my_res$X1[1],':')[[1]][2]
	my_res$X2 <- as.numeric(my_res$X2)
	tax_vars <- c(tax_vars, my_tax)
	outdf <- cbind(outdf, my_res)
	tablecolnames <- c(tablecolnames, full_name )
	prob_name=paste0("prob_", full_name)
	tablecolnames <- c(tablecolnames, prob_name )
}

outdf <- cbind(outdf, size)
tablecolnames <- c(tablecolnames, "size" )
colnames(outdf)<-tablecolnames

write.table(outdf, file=paste(small, ".classified.tsv", sep=""), quote=FALSE, sep='\t', row.names = FALSE)

#Function for making pie charts
pie_plots <- function(r){
    sums <- aggregate(size ~ outdf[[r]], outdf, sum)
    colnames(sums) <- c("tax", "size")
    sums <- sums[order(sums$size, decreasing = TRUE),]
    sums <- sums %>% mutate(perc = size/sum(size))
    cutoff <- sum(sums$perc > 0.03)
    top_val <- head(sums$tax, n = cutoff)
    sums <- sums %>% mutate(legend_value = case_when(tax %in% top_val ~ tax, !(tax %in% top_val) ~ "OTHER" ))
    pie_table <- aggregate(size~legend_value,sums,sum)
    pdf (paste(small, ".", r, ".pdf", sep = ""), width=6, height=6)
    pie(pie_table$size, pie_table$legend_value, clockwise = T)
    dev.off()
}

#Make pie charts for order, family and genus
for (tax in c("family", "order", "genus")) {
    pie_plots(tax)
}

#Generate summary stats
total_mapped_reads <- sum(aggregate(size~genus, outdf, sum)[2]) #just need total so does not matter which column used
unique_samples= nrow(outdf)
output <- cbind(unique_samples, total_mapped_reads)
write.table(output,"summary.tsv", quote=F, sep="\t", row.names = FALSE)