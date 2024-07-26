library("ggplot2")
library("patchwork")
library("pdftools")
library("RColorBrewer")
library("qdap")
library("Seurat")

dir.create("/root/results", showWarnings = FALSE)
setwd("/root/results")

find_func <- function(tempdir, pattern) {
  list.files(
    path = tempdir,
    pattern = pattern,
    full.names = TRUE,
    recursive = TRUE
  )
}

args <- commandArgs(trailingOnly = TRUE)

chip    <- args[1]
tempdir <- args[2]
project <- args[3]

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

rds_path <- find_func(tempdir, "combined.rds")

combined <- readRDS(rds_path)
combined

reductions <- names(combined@reductions)
all_genes <- rownames(combined)

pt_sizes <- list("50x50" = 2.0, "96x96" = 1.0, "220x220" = 0.25)

print(paste("Chip selected:", chip))
print(paste("Figure point size:", pt_sizes[[chip]]))

inp_genes <- read.csv(args[4], header = FALSE)$V1

#=============================================================================
# check gene list

geneList <- intersect(all_genes, inp_genes)
geneList

write.csv(geneList, "Plotted_geneList.csv")

pbmc <- AddModuleScore(
  combined,
  features = list(signature = geneList),
  name = "signature"
)

scale_max <- max(pbmc@meta.data$signature1)
scale_min <- min(pbmc@meta.data$signature1)

for (reduction in reductions) {
  if (reduction == "UMAP") {
    pbmc_2 <- pbmc
  } else {
    pbmc_2 <- pbmc[, which(pbmc@meta.data$Sample == reduction)]
  }

  ggOut <- FeaturePlot(
    pbmc_2,
    reduction = reduction,
    features = c("signature1"),
    label = FALSE,
    repel = TRUE,
    pt.size = pt_sizes[[chip]]
  ) +
    scale_colour_gradientn(
      colours = rev(brewer.pal(n = 11, name = "RdBu")),
      limits = c(scale_min, scale_max)
    ) +
    ggtitle(reduction)

  pdf(paste0(reduction, "_ModuleScore.pdf"))
  print(ggOut)
  dev.off()
}

top_list <- list()

if (length(reductions) >= 4) {
  ncol <- 4
} else {
  ncol <- length(reductions)
}

for (i in seq_along(reductions)) {
  if (reductions[i] == "UMAP") {
    pbmc_2 <- pbmc
    axes <- "NoAxes()"
  } else {
    pbmc_2 <- pbmc[, which(pbmc@meta.data$Sample == reductions[i])]
    axes  <- "NoAxes() & NoLegend()"
  }

  top_list[[i]] <- FeaturePlot(
    pbmc_2,
    reduction = reductions[i],
    features = c("signature1"),
    pt.size = pt_sizes[[chip]]
  ) +
    scale_colour_gradientn(
      colours = rev(brewer.pal(n = 11, name = "RdBu")),
      limits = c(scale_min, scale_max)
    ) +
    ggtitle(reductions[i]) & eval(parse(text = axes))
}

pdf("all_scaled.pdf")
print(top_list)
dev.off()

top_list <- list()

for (i in seq_along(reductions)) {
  if (reductions[i] == "UMAP") {
    pbmc_2 <- pbmc
  } else {
    pbmc_2 <- pbmc[, which(pbmc@meta.data$Sample == reductions[i])]
  }

  top_list[[i]] <- FeaturePlot(
    pbmc_2,
    reduction = reductions[i],
    features = c("signature1"),
    pt.size = pt_sizes[[chip]]
  ) +
    scale_colour_gradientn(colours = rev(brewer.pal(n = 11, name = "RdBu"))) +
    ggtitle(reductions[i]) & NoAxes()
}

pdf("all_Notscaled.pdf")
print(top_list)
dev.off()

# merge all pdf files in one pdf
path <- "/root/results"
pdf_merged <- "All_&_individual_samples.pdf"
pdf_combine(
  list.files(path, pattern = "pdf", full.names = TRUE), output  = pdf_merged
)

# remove individuals
file.remove(
  list.files("/root/results/", pattern = "*_ModuleScore.pdf", full.names = TRUE)
)

#===============================================================================

setwd("/root")
file.rename(list.files(pattern = "results"), paste0(project, "_results"))
