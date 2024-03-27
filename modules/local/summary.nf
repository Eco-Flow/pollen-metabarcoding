process SUMMARY {
    tag "All"
    label 'process_low'

    container = 'ecoflowucl/rocker-r_base:r-4.3.3_dplyr-1.1.4'

    input:
    path '*'

    output:
    path("All_combined_summary.tsv")   , emit: summary
    path('*.pdf')   , emit: pie

    script:
    """
    #!/usr/bin/Rscript
    library(dplyr)
    files <- list.files(pattern="*.tsv", full.names=TRUE)
    classif <- read.csv(files[1], h=T, sep="\t")
    for (f in files[-1]){
        df <- read.csv(f, h=T, sep="\t")      # read the file
        classif <- rbind(classif, df)    # append the current file
    }
    write.csv(classif, "All_combined_summary.tsv", row.names=FALSE, quote=FALSE)

    #Function for making pie charts
    pie_plots <- function(r){
      classif2<-as.data.frame(group_by(classif, paste("prob_", r, sep = "")) %>% filter(paste("prob_", r, sep = "") >= 0.95))
      sums <- aggregate(size ~ classif[[r]], classif2, sum)
      colnames(sums) <- c("tax", "size")
      sums <- sums[order(sums\$size, decreasing = TRUE),]
      sums <- sums %>% mutate(perc = size/sum(size))
      cutoff <- sum(sums\$perc > 0.03)
      top_val <- head(sums\$tax, n = cutoff)
      sums <- sums %>% mutate(legend_value = case_when(tax %in% top_val ~ tax, !(tax %in% top_val) ~ "OTHER" ))
      pie_table <- aggregate(size~legend_value,sums,sum)
      pdf (paste("All", ".", r, ".pdf", sep = ""), width=6, height=6)
      pie(pie_table\$size, pie_table\$legend_value, clockwise = T)
      dev.off()
    }

    #Make pie charts for order, family and genus
    for (tax in c("family", "order", "genus")) {
      pie_plots(tax)
    }
    #Plot some wee pie charts (by order, family or genus)

    """

}