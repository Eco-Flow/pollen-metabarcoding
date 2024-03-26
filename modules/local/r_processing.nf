process R_PROCESSING {
    tag "${meta.id}"
    label 'process_low'

    container = 'ecoflowucl/rocker-r_base:r-4.3.3_dplyr-1.1.4'

    input:
    tuple val(meta), path(sintax_tsv)

    //Only process files that have taxonomy predictions 
    when:
    sintax_tsv.size() > 0

    output:
    tuple val(meta), path('*.classified.tsv')   , emit: fasta
    tuple val(meta), path('*.pdf')   , emit: pie

    script:
    """
    #!/usr/bin/Rscript
    library(dplyr)

    data <- read.table("${sintax_tsv}", header=F, sep="\t")
    data <- data %>% mutate_all(na_if,"")

    id <- data.frame(do.call('rbind', strsplit(as.character(data\$V1), ';', fixed=TRUE)))[1]

    size <- gsub(";", "", data\$V1)
    size <- data.frame(do.call('rbind', strsplit(size,'=',fixed=TRUE)))[2]
    size\$X2 <- as.numeric(size\$X2)

    classif <- data.frame(do.call('rbind', strsplit(as.character(data\$V2),',',fixed=TRUE)))

    k <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X1),'(',fixed=TRUE)))
    k\$X1 <- gsub("k:", "", k\$X1)
    k\$X2 <- as.numeric(as.character(k\$X2))

    p <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X2),'(',fixed=TRUE)))
    p\$X1 <- gsub("p:", "", p\$X1)
    p\$X2 <- as.numeric(as.character(p\$X2))

    c <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X3),'(',fixed=TRUE)))
    c\$X1 <- gsub("c:", "", c\$X1)
    c\$X2 <- as.numeric(as.character(c\$X2))

    o <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X4),'(',fixed=TRUE)))
    o\$X1 <- gsub("o:", "", o\$X1)
    o\$X2 <- as.numeric(as.character(o\$X2))

    f <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X5),'(',fixed=TRUE)))
    f\$X1 <- gsub("f:", "", f\$X1)
    f\$X2 <- as.numeric(as.character(f\$X2))

    g <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X6),'(',fixed=TRUE)))
    g\$X1 <- gsub("g:", "", g\$X1)
    g\$X2 <- as.numeric(as.character(g\$X2))

    s <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif\$X7),'(',fixed=TRUE)))
    s\$X1 <- gsub("s:", "", s\$X1)
    s\$X2 <- as.numeric(as.character(s\$X2))

    classif <- cbind(id, k, p, c, o, f, g, s, size)
    colnames(classif)[c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)] <- c("sample", "kingdom", "prob_kingdom", "division", "prob_division", "clade", "prob_clade", "order", "prob_order", "family", "prob_family", "genus", "prob_genus", "species", "prob_species", "size")

    write.table(classif, file=paste("${meta.id}", ".classified.tsv", sep=""), quote=FALSE, sep='\t', row.names = FALSE)

    #Plot some wee pie charts (by order, family or genus)

    sums <- aggregate(size~order,classif,sum)
    sums <- sums[order(sums\$size, decreasing = TRUE),]
    sums <- sums %>% mutate(perc = size/sum(size))
    cutoff <- sum(sums\$perc > 0.03)
    top_val <- head(sums\$order, n = cutoff)
    sums <- sums %>% mutate(legend_value = case_when(order %in% top_val ~ order, !(order %in% top_val) ~ "OTHER" ))
    pie_table <- aggregate(size~legend_value,sums,sum)
    pdf ("${meta.id}.order.pdf", width=6, height=6)
    pie(pie_table\$size, pie_table\$legend_value, clockwise = T)
    dev.off()

    sums <- aggregate(size~family,classif,sum)
    sums <- sums[order(sums\$size, decreasing = TRUE),]
    sums <- sums %>% mutate(perc = size/sum(size))
    cutoff <- sum(sums\$perc > 0.03)
    top_val <- head(sums\$family, n = cutoff)
    sums <- sums %>% mutate(legend_value = case_when(family %in% top_val ~ family, !(family %in% top_val) ~ "OTHER" ))
    pie_table <- aggregate(size~legend_value,sums,sum)
    pdf ("${meta.id}.family.pdf", width=6, height=6)
    pie(pie_table\$size, pie_table\$legend_value, clockwise = T)
    dev.off()

    sums <- aggregate(size~genus,classif,sum)
    sums <- sums[order(sums\$size, decreasing = TRUE),]
    sums <- sums %>% mutate(perc = size/sum(size))
    cutoff <- sum(sums\$perc > 0.03)
    top_val <- head(sums\$genus, n = cutoff)
    sums <- sums %>% mutate(legend_value = case_when(genus %in% top_val ~ genus, !(genus %in% top_val) ~ "OTHER" ))
    pie_table <- aggregate(size~legend_value,sums,sum)
    pdf ("${meta.id}.genus.pdf", width=6, height=6)
    pie(pie_table\$size, pie_table\$legend_value, clockwise = T)
    dev.off()


    """
}
