library(dplyr)

theargs <- R.utils::commandArgs(asValues=TRUE)
input_path <- theargs$input
output_id <- theargs$output

data <- read.table(input_path, header=F, sep="\t")
data <- data %>% mutate_all(na_if,"")

id <- data.frame(do.call('rbind', strsplit(as.character(data$V1), ';', fixed=TRUE)))[1]

size <- gsub(";", "", data$V1)
size <- data.frame(do.call('rbind', strsplit(size,'=',fixed=TRUE)))[2]
size$X2 <- as.numeric(size$X2)

classif <- data.frame(do.call('rbind', strsplit(as.character(data$V2),',',fixed=TRUE)))

k <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X1),'(',fixed=TRUE)))
k$X1 <- gsub("k:", "", k$X1)
k$X2 <- as.numeric(as.character(k$X2))

p <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X2),'(',fixed=TRUE)))
p$X1 <- gsub("p:", "", p$X1)
p$X2 <- as.numeric(as.character(p$X2))

c <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X3),'(',fixed=TRUE)))
c$X1 <- gsub("c:", "", c$X1)
c$X2 <- as.numeric(as.character(c$X2))

o <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X4),'(',fixed=TRUE)))
o$X1 <- gsub("o:", "", o$X1)
o$X2 <- as.numeric(as.character(o$X2))

f <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X5),'(',fixed=TRUE)))
f$X1 <- gsub("f:", "", f$X1)
f$X2 <- as.numeric(as.character(f$X2))

g <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X6),'(',fixed=TRUE)))
g$X1 <- gsub("g:", "", g$X1)
g$X2 <- as.numeric(as.character(g$X2))

s <- data.frame(do.call('rbind', strsplit(gsub(")", "",classif$X7),'(',fixed=TRUE)))
s$X1 <- gsub("s:", "", s$X1)
s$X2 <- as.numeric(as.character(s$X2))

classif <- cbind(id, k, p, c, o, f, g, s, size)
colnames(classif)[c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)] <- c("sample", "kingdom", "prob_kingdom", "division", "prob_division", "clade", "prob_clade", "order", "prob_order", "family", "prob_family", "genus", "prob_genus", "species", "prob_species", "size")

write.table(classif, file=paste(output_id, ".classified.tsv", sep=""), quote=FALSE, sep='\t', row.names = FALSE)
