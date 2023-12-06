library(qdap)
library('Seurat')
library(ggplot2)
library(RColorBrewer)
library(pdftools)
library(patchwork)


dir.create("/root/results", showWarnings = FALSE)
setwd("/root/results")



find_func <- function(tempdir,pattern){
    
  list.files(
  path = tempdir, # replace with the directory you want
  pattern = pattern, # has "test", followed by 0 or more characters,
                             # then ".csv", and then nothing else ($)
  full.names = TRUE # include the directory in the result
        , recursive = TRUE
)
    
}


args <- commandArgs(trailingOnly=TRUE)
tempdir <- args[1]


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
tempdir <- args[1]

rds_path <- find_func(tempdir, "combined.rds")

combined <- readRDS(rds_path)
combined

reductions <- names(combined@reductions)
all_genes <- rownames(combined)

project <- args[2]


inp_genes <- read.csv(args[3], header = F)$V1
# inp_genes
#=============================================================================
# check gene list

geneList <- intersect(all_genes,inp_genes)
geneList

write.csv(geneList,'Plotted_geneList.csv')


pbmc <- AddModuleScore(combined,
                       features = list(signature = geneList),
                       name="signature")


scale_max <- max(pbmc@meta.data$signature1)
scale_min <- min(pbmc@meta.data$signature1)

for (reduction in reductions){
  if(reduction=='UMAP'){ 
    pbmc_2 <- pbmc
  }else{
    pbmc_2 <- pbmc[,which(pbmc@meta.data$Sample==reduction)]
  }

ggOut <- FeaturePlot(pbmc_2, reduction = reduction,
                     features = c("signature1"), label = FALSE, repel = TRUE, pt.size = 2) +
  scale_colour_gradientn(colours = rev(brewer.pal(n = 11, name = "RdBu")),limits = c(scale_min, scale_max))+
  ggtitle(reduction)

pdf(paste0(reduction,'_ModuleScore.pdf'))
print(ggOut)
dev.off()

}

top_list <- list()

for (i in seq_along(reductions)) {
  if(reductions[i]=='UMAP'){ 
    pbmc_2 <- pbmc
    axes <- 'NoAxes()'
  }else{
    pbmc_2 <- pbmc[,which(pbmc@meta.data$Sample==reductions[i])]
    axes  <- 'NoAxes() & NoLegend()'
  }
  
  top_list[[i]] <- FeaturePlot(pbmc_2, reduction = reductions[i], features = c("signature1"))+ 
    scale_colour_gradientn(colours = rev(brewer.pal(n = 11, name = "RdBu")),
                           limits = c(scale_min, scale_max)
                           )+
    ggtitle(reductions[i]) & eval(parse(text=axes))
}

pdf('all_scaled.pdf',height = 6, width = 12)
print(
  top_spatial_plots <- wrap_plots(top_list, ncol = 4) 
  
)
dev.off()


top_list <- list()

for (i in seq_along(reductions)) {
  if(reductions[i]=='UMAP'){ 
    pbmc_2 <- pbmc
    
  }else{
    pbmc_2 <- pbmc[,which(pbmc@meta.data$Sample==reductions[i])]
   
  }
  
  top_list[[i]] <- FeaturePlot(pbmc_2, reduction = reductions[i], features = c("signature1"))+ 
    scale_colour_gradientn(colours = rev(brewer.pal(n = 11, name = "RdBu"))
                           # ,limits = c(scale_min, scale_max)
                           )+
    ggtitle(reductions[i]) & NoAxes()
}

pdf('all_Notscaled.pdf',height = 6, width = 15)
print(
  top_spatial_plots <- wrap_plots(top_list, ncol = 4) 
  
)
dev.off()

# merge all pdf files in one pdf

path <- '/root/results'
pdf_merged <- 'All_&_individual_samples.pdf'
pdf_combine(list.files(path, pattern="pdf", full.names=TRUE), output  = pdf_merged)

# remove individuals

file.remove(list.files('/root/results/', pattern="*_ModuleScore.pdf", full.names=TRUE))
#===============================================================================


setwd("/root")

system("ls -a |grep -v 'results' | xargs rm -r")


file.rename(list.files(pattern="results"), paste0(project,"_results"))


