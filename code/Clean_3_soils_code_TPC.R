rm(list=ls())

#legend.position = "right",
library("funrar")
library("vegan")
library("ape")
library("reshape2")
library("DESeq2")
library("preprocessCore")
library("ggplot2")
library("dplyr")

theme_kp <- function() {  # this for all the elements common across plots
  theme_bw() %+replace%
    theme(
      legend.key=element_blank(),
      legend.title = element_blank(),
      legend.text = element_text(size = 12),
      legend.key.size = unit(1.5, 'lines'),
      panel.border = element_rect(color="black",size=1.5, fill = NA),
      
      plot.title = element_text(hjust = 0.05, size = 14),
      axis.text = element_text(size = 14,  color = "black"),
      axis.title = element_text(size = 14, face = "bold", color = "black"),
      
      # formatting for facets
      panel.background = element_blank(),
      strip.background = element_rect(colour="white", fill="white"), #facet formatting
      panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
      panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
      strip.text.x = element_text(size=12, face="bold"), #facet labels
      strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
    )
}




###################
######MetaG PCA Analysis
###################
###################

setwd("~/Documents/3_soils/metaT_drought_analysis/")
g_tab = read.table("metaG_combined_0.001perc.txt", sep="\t", header=TRUE, row.names=1)

#####Convert all the na's to zeros
g_tab[is.na(g_tab)] = 0

#####Remove all ribosomal genes
g_tab = subset(g_tab, select = -c(TIGR00001,	TIGR00002,	TIGR00009,		
                                  TIGR00030,	TIGR00059,	TIGR00060,	TIGR00061,	TIGR00062,	TIGR00105,	TIGR00158,	
                                  TIGR00165,	TIGR00717,	
                                  TIGR00731,	TIGR00855,	TIGR00952,	TIGR00981,	TIGR01009,	
                                  TIGR01011,	TIGR01017,	TIGR01021,	TIGR01022,	
                                  TIGR01023,	TIGR01024,	TIGR01029,	TIGR01030,	TIGR01031,	
                                  TIGR01032,	TIGR01044,	TIGR01049,	TIGR01050,	TIGR01066,	
                                  TIGR01067,	TIGR01071,	TIGR01079,	TIGR01125,	TIGR01164,	
                                  TIGR01169,	TIGR01171,	TIGR01632,	
                                  TIGR03631,	TIGR03632,	
                                  TIGR03635,	TIGR03654,	TIGR03953))

#####Make a matrix that excludes all the metadata and is just numbers with the sample numbers as the row names
NAMES = rownames(g_tab)
g_matrix = g_tab[,6:1537]
rownames(g_matrix) = NAMES
g_matrix = as.matrix(g_matrix)
quantile(g_matrix)

NAMES = rownames(g_tab)
g_sample = g_tab[,1:2]
rownames(g_sample) = NAMES

#####relative abundance normalization

g_rel = make_relative(g_matrix)
merged = merge(g_sample, g_rel, by="row.names")


#calculate edistances

e_distance = vegdist(g_rel, method="euclidean")
principal_coordinates = pcoa(e_distance)

pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, g_sample, by="row.names")

# 3. Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))

# 4. Plot PCoA

pcoa_plot_merged$Treatment = factor(pcoa_plot_merged$Treatment, levels = c("Drought","Field_Moist","Sat_II","Sat_I"))
ggplot(data=pcoa_plot_merged,aes(x=Axis.1,y=Axis.2)) + geom_point(aes(fill=factor(Treatment),shape=factor(Site)),  size=6,alpha=0.95) + theme_bw()  +
  theme_kp() + 
  labs(x = paste("PC1 - Variation Explained", round(PC1,2),"%"), y = paste("PC2 - Variation Explained", round(PC2,2),"%")) +
  scale_fill_manual(values=c("Sat_II"= "#443a83ff","Field_Moist"="#35b779ff","Drought"="#fde725ff","Sat_I"="grey70"),
                    labels=c("Drought"="drought","Field_Moist"="field moist","Sat_II"="flood","Sat_I"="time zero saturation"))+
  scale_color_manual(values=c("Sat_II"="#35b779ff","Field_Moist"="#fde725ff","Drought"="#443a83ff","Sat_I"="grey70"))+
  scale_shape_manual(values=c(21,22,24),labels=c("CPCRW"="Alaska","DWP"="Florida","SR"="Washington"))+
  guides(fill=guide_legend(override.aes=list(shape=21)))

adonis(g_matrix ~ g_tab$Site+g_tab$Treatment+g_tab$Site*g_tab$Treatment, method="euclidean", permutations=999)

########################################
#######baseline vs drought MetaT #######
########################################
rm(list=ls())

g_tab_bld = read.table("metaT_combined_0.001perc_bld.txt",sep="\t",header=TRUE,row.names=1)

#####Convert all the na's to zeros
g_tab_bld[is.na(g_tab_bld)] = 0





g_tab_bld = subset(g_tab_bld, select = -c(TIGR00001,	TIGR00002,	TIGR00009,	TIGR00012,	TIGR00029,
                                          TIGR00030,	TIGR00059,	TIGR00060,	TIGR00061,	TIGR00062,	TIGR00105,	TIGR00158,	
                                          TIGR00165,	TIGR00166,	TIGR00279,  TIGR00717,	
                                          TIGR00731,	TIGR00855,	TIGR00952,	TIGR00981,	TIGR00982,	TIGR01008,	TIGR01009,	
                                          TIGR01011,	TIGR01012,	TIGR01017,	TIGR01018,	TIGR01020,	TIGR01021,	TIGR01022,	
                                          TIGR01023,	TIGR01024,	TIGR01025,	TIGR01028,	TIGR01029,	TIGR01030,	TIGR01031,	
                                          TIGR01032,	TIGR01038,	TIGR01044,	TIGR01046,	TIGR01049,	TIGR01050,	TIGR01066,	
                                          TIGR01067,	TIGR01071,	TIGR01079,	TIGR01080,	TIGR01125,	TIGR01164,	
                                          TIGR01169,	TIGR01170,	TIGR01171,	TIGR01308,	TIGR01632,	
                                          TIGR03626,	TIGR03627,	TIGR03628,	TIGR03629,	TIGR03631,	TIGR03632,	
                                          TIGR03635,	TIGR03654,	TIGR03953))


#####Make a matrix that excludes all the metadata and is just numbers with the sample numbers as the row names
NAMES = rownames(g_tab_bld)
g_matrix_bld = g_tab_bld[,7:1146]
rownames(g_matrix_bld) = NAMES
g_matrix_bld = as.matrix(g_matrix_bld)
quantile(g_matrix_bld)

NAMES = rownames(g_tab_bld)
g_sample_bld = g_tab_bld[,1:2]
rownames(g_sample_bld) = NAMES

############################
###########################
#####relative abundance normalization

g_rel_bld = make_relative(g_matrix_bld)
merged = merge(g_sample_bld, g_rel_bld, by="row.names")
merged =merge(g_sample_bld,g_matrix_bld,by="row.names")


transposed_g_matrix_bld = t(g_matrix_bld)
dds_bld = DESeqDataSetFromMatrix(countData = transposed_g_matrix_bld,
                                 colData = g_sample_bld,
                                 design = ~Treatment)
dds_bld = estimateSizeFactors(dds_bld)
dds_bld = DESeq(dds_bld)
res_bld = results(dds_bld)
resultsNames(dds_bld)


############Coloring and normalization
library("viridis")
library("pheatmap")
npgpal=viridis_pal(option="viridis")(85)
ntd_bld = normTransform(dds_bld)

#########LDA heatmap based on all treatments
long_combined_bld = c("TIGR02907",	"TIGR01925",	"TIGR02844",	"TIGR01442",	"TIGR02836",	"TIGR03417",	"TIGR02886",	"TIGR03414",	"TIGR00117",	"TIGR01837",	"TIGR03824",	"TIGR02851",	"TIGR01433",	"TIGR01345",	"TIGR01320",	"TIGR01879",	"TIGR01096",	"TIGR01108",	"TIGR02136",	"TIGR00741",	"TIGR02061",	"TIGR02176",	"TIGR03478",	"TIGR04246",	"TIGR03513",	"TIGR01580",	"TIGR03404",	"TIGR02376",	"TIGR03078",	"TIGR03544",	"TIGR01660",	"TIGR02943",	"TIGR00538",	"TIGR02162",	"TIGR03508",	"TIGR02161",	"TIGR02260",	"TIGR01152",	"TIGR03080",	"TIGR01151")

kd_3soil_colors = list(
  Treatment = c("base line"="grey70","drought"="#fde725ff"),
  Site = c("Alaska" = "#b84634","Florida"="#e6ab00","Washington"="#008cff"))

levels(g_sample_bld$Treatment)
levels(g_sample_bld$Treatment) = c("base line","drought")
levels(g_sample_bld$Site)
levels(g_sample_bld$Site) = c("Alaska","Florida","Washington")


pheatmap(assay(ntd_bld)[long_combined_bld,],cluster_cols=FALSE,cluster_rows=FALSE,annotation_col = g_sample_bld,show_colnames=FALSE,color=cividis(99),
         annotation_colors=kd_3soil_colors,
         labels_row = c("TIGR02907 spoVID",	"TIGR01925 spoIIAB",	"TIGR02844 spoIIID",	"TIGR01442 Spore Protein",	
                        "TIGR02836 spoIVA",	"TIGR03417 Choline Sulfatase",	"TIGR02886 spoIIAA",	
                        "TIGR03414 Choline ABC Transporter",	"TIGR00117 2-Methylisocitrate Dehydratase",	
                        "TIGR01837 Polyhydroxyalkanoate Granule",	"TIGR03824 Flagellar Biosynthesis",	"TIGR02851 spoVT",	
                        "TIGR01433 Cytochrome O Ubiquinol Oxidase",	"TIGR01345 Malate Synthase",	
                        "TIGR01320 Malate:Quinone Oxidoreductase",	"TIGR01879 Hydantoinase/Carbamoylase Amidase",	
                        "TIGR01096 K-R-O-Binding Periplasmic Protein",	"TIGR01108 Oxaloacetate Decarboxylase",	
                        "TIGR02136 Phosphate Binding Protein",	"TIGR00741 Ribosomal Subunit Interface Protein",
                        "TIGR02061 Adenosine Phosphosulphate Reductase",	"TIGR02176 Pyruvate: Ferredoxin Oxidoreductase",	
                        "TIGR03478 DMSO Reductase",	"TIGR04246 Nitrous-Oxide Reductase",	"TIGR03513 GldL Gliding Motility Protein",	
                        "TIGR01580 Respiratory Nitrate Reductase",	"TIGR03404 Bicupin Oxalate Decarboxylase Family",	
                        "TIGR02376 Nitrite Reductase",	"TIGR03078 Methane/Ammonia Monooxygenase",	"TIGR03544 DivIVA Domain",
                        "TIGR01660 Nitrate Reductase",	"TIGR02943 RNA Polymerase",	"TIGR00538 hemN",	"TIGR02162 Cytochrome TorC",
                        "TIGR03508 Decaheme D-Type Cytochrome","TIGR02161 Periplasmic Nitrate Reductase","TIGR02260 Benzoyl CoA Reductase",
                        "TIGR01152 Photosystem II","TIGR03080 Methane Monooxygenase","TIGR01151 Photosystem II"))


##########
##########
####MetaT PCA

rm(list=ls())
library("devtools")
library("ggplot2")
library("funrar")
library("vegan")
library("ape")
library("reshape2")
library("DESeq2")
library("preprocessCore")
library("ggbiplot")

theme_kp <- function() {  # this for all the elements common across plots
  theme_bw() %+replace%
    theme(
      legend.key=element_blank(),
      legend.title = element_blank(),
      legend.text = element_text(size = 12),
      legend.key.size = unit(1.5, 'lines'),
      panel.border = element_rect(color="black",size=1.5, fill = NA),
      
      plot.title = element_text(hjust = 0.05, size = 14),
      axis.text = element_text(size = 14,  color = "black"),
      axis.title = element_text(size = 14, face = "bold", color = "black"),
      
      # formatting for facets
      panel.background = element_blank(),
      strip.background = element_rect(colour="white", fill="white"), #facet formatting
      panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
      panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
      strip.text.x = element_text(size=12, face="bold"), #facet labels
      strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
    )
}


###################
######PCOA Analysis
###################
###################
setwd("~/Documents/3_soils/metaT_drought_analysis/")
g_tab = read.table("metaT_combined_0.001perc_removed.txt", sep="\t", header=TRUE, row.names=1)

#####Convert all the na's to zeros
g_tab[is.na(g_tab)] = 0

###Remove base_line samples
g_tab = subset(g_tab, Treatment!="Base_Line")

###Remove ribosomal genes
g_tab = subset(g_tab, select = -c(TIGR00001,	TIGR00002,	TIGR00009,	TIGR00012,	TIGR00029,
                                  TIGR00030,	TIGR00059,	TIGR00060,	TIGR00061,	TIGR00062,	TIGR00105,	TIGR00158,	
                                  TIGR00165,	TIGR00166,	TIGR00279,	TIGR00717,	
                                  TIGR00731,	TIGR00855,	TIGR00952,	TIGR00981,	TIGR00982,	TIGR01008,	TIGR01009,	
                                  TIGR01011,	TIGR01012,	TIGR01017,	TIGR01018,	TIGR01020,	TIGR01021,	TIGR01022,	
                                  TIGR01023,	TIGR01024,	TIGR01025,	TIGR01028,	TIGR01029,	TIGR01030,	TIGR01031,	
                                  TIGR01032,	TIGR01038,	TIGR01044,	TIGR01046,	TIGR01049,	TIGR01050,	TIGR01066,	
                                  TIGR01067,	TIGR01071,TIGR01079,	TIGR01080,	TIGR01125,	TIGR01164,	
                                  TIGR01169,	TIGR01170,	TIGR01171,	TIGR01308,TIGR01632,	
                                  TIGR03626,	TIGR03627,	TIGR03628,	TIGR03629,TIGR03631,	TIGR03632,	
                                  TIGR03635,	TIGR03654,	TIGR03953,  TIGR03673))

#####Make a matrix that excludes all the metadata and is just numbers with the sample numbers as the row names
NAMES = rownames(g_tab)
g_matrix = g_tab[,7:1145]
rownames(g_matrix) = NAMES
g_matrix = as.matrix(g_matrix)
quantile(g_matrix)

NAMES = rownames(g_tab)
g_sample = g_tab[,1:6]
rownames(g_sample) = NAMES

############################
###########################
#####relative abundance normalization
g_rel = make_relative(g_matrix)
merged = merge(g_sample, g_rel, by="row.names")

###########################
###########################
###########################

e_distance = vegdist(g_rel, method="euclidean")
principal_coordinates = pcoa(e_distance)

pcoa_plot = data.frame(principal_coordinates$vectors[,])
pcoa_plot_merged = merge(pcoa_plot, g_sample, by="row.names")

# 3. Calculate percent variation explained by PC1, PC2

PC1 <- 100*(principal_coordinates$values$Eigenvalues[1]/sum(principal_coordinates$values$Eigenvalues))
PC2 <- 100*(principal_coordinates$values$Eigenvalues[2]/sum(principal_coordinates$values$Eigenvalues))
PC3 <- 100*(principal_coordinates$values$Eigenvalues[3]/sum(principal_coordinates$values$Eigenvalues))

# 4. Plot PCoA
pcoa_plot_merged$Treatment = factor(pcoa_plot_merged$Treatment, levels = c("Drought","Field_Moist","Sat_II","Sat_I"))
ggplot(data=pcoa_plot_merged,aes(x=Axis.1,y=Axis.2)) + geom_point(aes(fill=factor(Treatment),shape=factor(Site)),size=6,alpha=0.95) + theme_bw()  +
  theme_kp() + 
  stat_ellipse(aes(color=Treatment),size=1.5)+
  labs(x = paste("PC1 - Variation Explained", round(PC1,2),"%"), y = paste("PC2 - Variation Explained", round(PC2,2),"%"))+
  scale_fill_manual(values=c("Sat_II"= "#443a83ff","Field_Moist"="#35b779ff","Drought"="#fde725ff","Sat_I"="grey70"),
                    labels=c("Drought"="drought","Field_Moist"="field moist","Sat_II"="flood","Sat_I"="time zero saturation"))+
  scale_color_manual(values=c("Sat_II"="#443a83ff","Field_Moist"="#35b779ff","Drought"="#fde725ff","Sat_I"="grey70"),
                     labels=c("Drought"="drought","Field_Moist"="field moist","Sat_II"="flood","Sat_I"="time zero saturation"))+
  scale_shape_manual(values=c(21,22,24),labels=c("CPCRW"="Alaska","DWP"="Florida","SR"="Washington"))+
  guides(fill=guide_legend(override.aes=list(shape=21)),color=FALSE)

adonis(g_matrix ~ g_tab$Site+g_tab$Treatment+g_tab$Site*g_tab$Treatment, method="euclidean", permutations=999)

#############
###MetaT distance boxplot
#############

#####Create distance matrix
names = rownames(g_sample)
rownames(g_sample) = NULL
g_sample = cbind(names,g_sample)

matrix = as.matrix(e_distance)

e_matrix = as.matrix(e_distance)

e_matrix[lower.tri(e_matrix)] = NA


e_summary = melt(e_matrix)

e_summary = na.omit(e_summary)

e_summary = e_summary %>%
  filter(as.character(Var1) != as.character(Var2)) %>%
  mutate_if(is.factor,as.character)

#g_sample[1] = NULL

sd = g_sample %>%
  select(names,Treatment) %>%
  mutate_if(is.factor,as.character)


colnames(sd) = c("Var1","Category")
e_summary$Var1 = as.character(e_summary$Var1)
e_summary$Var2 = as.character(e_summary$Var2)

e_summarySD = left_join(e_summary, sd, by = "Var1")

colnames(sd) = c("Var2","Category")
e_summarySD = left_join(e_summarySD, sd, by = "Var2")


e_summarySD$comparison = paste(e_summarySD$Category.x,e_summarySD$Category.y,sep="_")
e_summarySD

kruskal.test(value~comparison, data=e_summarySD)


pairwise.wilcox.test(e_summarySD$value, e_summarySD$comparison, p.adjust.method="BH")
output = pairwise.wilcox.test(e_summarySD$value, e_summarySD$comparison, p.adjust.method="BH")
View(output[[3]])

melted = melt(output[[3]])


##############################
##############################
##############################
# e Distance Boxplots #####
##############################
##############################

e_matrix = as.matrix(e_distance)

e_summary = melt(e_matrix)

e_summary = na.omit(e_summary)

e_summary = e_summary %>%
  filter(as.character(Var1) != as.character(Var2)) %>%
  mutate_if(is.factor,as.character)



sd = g_sample %>%
  select(names,Treatment) %>%
  mutate_if(is.factor,as.character)

colnames(sd) = c("Var1","Category")
e_summary$Var1 = as.character(e_summary$Var1)
e_summary$Var2 = as.character(e_summary$Var2)
e_summarySD = left_join(e_summary, sd, by = "Var1")

colnames(sd) = c("Var2","Category")
e_summarySD = left_join(e_summarySD, sd, by = "Var2")


e_summarySD$comparison = paste(e_summarySD$Category.x,e_summarySD$Category.y,sep="_")
e_summarySD

e_summarySD = subset(e_summarySD, comparison == "Drought_Drought"| comparison == "Field_Moist_Field_Moist"| comparison == "Sat_II_Sat_II"| comparison == "Sat_I_Sat_I")
e_summarySD$comparison = factor(e_summarySD$comparison, levels = c("Drought_Drought","Field_Moist_Field_Moist","Sat_II_Sat_II","Sat_I_Sat_I"))


ggplot(e_summarySD, aes(comparison, value,fill=comparison)) + 
  geom_boxplot(outlier.color= "black",alpha = 0.9) +
  theme_kp() +
  labs(y="Distance",x="") + ylim(0,0.105)+
  theme(axis.text.x = element_text(angle = 90,hjust=1,vjust=0.5),legend.position="none")+
  scale_fill_manual(values=c("Sat_II_Sat_II"= "#443a83ff","Field_Moist_Field_Moist"="#35b779ff","Drought_Drought"="#fde725ff","Sat_I_Sat_I"="grey70"),
                    labels=c("Drought_Drought"="drought","Field_Moist_Field_Moist"="field moist","Sat_II_Sat_II"="flood","Sat_I_Sat_I"="time zero saturation"))+
  scale_color_manual(values=c("Sat_II_Sat_II"="#443a83ff","Field_Moist_Field_Moist"="#35b779ff","Drought_Drought"="#fde725ff","Sat_I_Sat_I"="grey70"),
                     labels=c("Drought_Drought"="drought","Field_Moist_Field_Moist"="field moist","Sat_II_Sat_II"="flood","Sat_I_Sat_I"="time zero saturation"))+
  scale_x_discrete(labels=c("Drought_Drought"="drought","Field_Moist_Field_Moist"="field moist","Sat_II_Sat_II"="flood","Sat_I_Sat_I"="time zero saturation"))





################
####### metaT top ten genes per site heatmap
################
rm(list=ls())
library("ggplot2")
library("funrar")
library("vegan")
library("ape")
library("reshape2")
library("DESeq2")
library("preprocessCore")
library("pheatmap")
library("dplyr")



setwd("~/Documents/3_soils/metaT_drought_analysis/")
g_tab = read.table("metaT_combined_0.001perc_removed.txt",sep="\t",header=TRUE,row.names=1)


#####Convert all the na's to zeros
g_tab[is.na(g_tab)] = 0

#####Remove ribosome genes

g_tab = subset(g_tab, select = -c(TIGR00001,	TIGR00002,	TIGR00009,	TIGR00012,	TIGR00029,
                                  TIGR00030,	TIGR00059,	TIGR00060,	TIGR00061,	TIGR00062,	TIGR00105,	TIGR00158,	
                                  TIGR00165,	TIGR00166,	TIGR00279,  TIGR00717,	
                                  TIGR00731,	TIGR00855,	TIGR00952,	TIGR00981,	TIGR00982,	TIGR01008,	TIGR01009,	
                                  TIGR01011,	TIGR01012,	TIGR01017,	TIGR01018,	TIGR01020,	TIGR01021,	TIGR01022,	
                                  TIGR01023,	TIGR01024,	TIGR01025,	TIGR01028,	TIGR01029,	TIGR01030,	TIGR01031,	
                                  TIGR01032,	TIGR01038,	TIGR01044,	TIGR01046,	TIGR01049,	TIGR01050,	TIGR01066,	
                                  TIGR01067,	TIGR01071,	TIGR01079,	TIGR01080,	TIGR01125,	TIGR01164,	
                                  TIGR01169,	TIGR01170,	TIGR01171,	TIGR01308,	TIGR01632,	
                                  TIGR03626,	TIGR03627,	TIGR03628,	TIGR03629,	TIGR03631,	TIGR03632,	
                                  TIGR03635,	TIGR03654,	TIGR03953))

#####Make a matrix that excludes all the metadata and is just numbers with the sample numbers as the row names
NAMES = rownames(g_tab)
g_matrix = g_tab[,7:1146]
rownames(g_matrix) = NAMES
g_matrix = as.matrix(g_matrix)
quantile(g_matrix)

NAMES = rownames(g_tab)
g_sample = g_tab[,1:2]
rownames(g_sample) = NAMES


############################
###########################
#####relative abundance normalization

g_rel = make_relative(g_matrix)



transposed_g_matrix = t(g_matrix)
dds = DESeqDataSetFromMatrix(countData = transposed_g_matrix,
                             colData = g_sample,
                             design = ~Treatment)
dds = estimateSizeFactors(dds)
dds = DESeq(dds)
res = results(dds)
resultsNames(dds)


############Coloring
library("viridis")
library("pheatmap")
npgpal=viridis_pal(option="viridis")(85)
ntd = normTransform(dds)

#########LDA heatmap based on all treatments

site_combined=c("TIGR03319","TIGR01703","TIGR04246","TIGR02339","TIGR02225","TIGR02224","TIGR01580","TIGR04244","TIGR03648","TIGR02376",
                "TIGR02891","TIGR03544","TIGR03450","TIGR02843","TIGR01974","TIGR00691","TIGR02947","TIGR02456","TIGR03619","TIGR02753",
                "TIGR02027","TIGR00915","TIGR03470","TIGR00239","TIGR02154","TIGR00998","TIGR02415","TIGR00127","TIGR03524","TIGR03525")

levels(g_sample$Treatment)
levels(g_sample$Treatment) = c("base line","drought","field moist","time zero saturation","flood")
levels(g_sample$Site)
levels(g_sample$Site) = c("Alaska","Florida","Washington")

kd_3soil_colors = list(
  Treatment = c("base line"="black","drought"="#fde725ff","field moist"="#35b779ff","flood"="#443a83ff",
                "time zero saturation"="grey70"),
  Site = c("Alaska" = "#b84634","Florida"="#e6ab00","Washington"="#008cff"))


pheatmap(assay(ntd)[site_combined,],cluster_cols=FALSE,cluster_rows=FALSE,annotation_col = g_sample,show_colnames=FALSE,color=cividis(99),
         annotation_colors=kd_3soil_colors,
         labels_row = c("TIGR03319 Endoribonuclease Y","TIGR01703 Hydroxylamine Reductase","TIGR04246 Nitrous-Oxide Reductase","TIGR02339 Archaeal Thermosome",
                        "TIGR02225 Tyrosine Recombinase XerD","TIGR02224 Tyrosine Recombinase XerC","TIGR01580 Respiratory Nitrate Reductase",
                        "TIGR04244 Nitrous-Oxide Reductase","TIGR03648 Sodium:Solute Symporter","TIGR02376 Nitrite Reductase, Cu Containing",
                        "TIGR02891 Cytochrome C Oxidase","TIGR03544 DivIVA domain","TIGR03450 Inositol 1-Phosphate Synthase","TIGR02843 Cytochrome O Ubiquinol Oxidase",
                        "TIGR01974 NADH-Quinone Oxidoreductase","TIGR00691 ppGpp Synthetase","TIGR02947 RNA Polymerase Sigma-70 Factor",
                        "TIGR02456 Trehalose Synthase","TIGR03619 F420-Dependent Oxidoreductase","TIGR02753 Superoxide Dismutase",
                        "TIGR02027 DNA-Directed RNA Polymerase","TIGR00915 HAE1 Efflux Family","TIGR03470 Hopanoid Biosynthesis",
                        "TIGR00239 2-Oxoglutarate Dehydrogenase","TIGR02154 Transcriptional Regulator","TIGR00998 Antibiotic Efflux Pump",
                        "TIGR02415 Acetoin Reductase","TIGR00127 Isocitrate Dehydrogenase","TIGR03524 Gliding Associated Lipoprotein",
                        "TIGR03525 Gliding Associated Lipoprotein"))



###########################################
#                                         #
#    metaG top ten heatmap per site       #
#                                         #
###########################################

rm(list=ls())


library("funrar")
library("vegan")
library("ape")
library("reshape2")
library("DESeq2")
library("preprocessCore")
library("ggplot2")
library("cividis")


setwd("~/Documents/3_soils/metaT_drought_analysis/")

g_tab = read.table("metaG_combined_0.001perc.txt", sep="\t", header=TRUE, row.names=1)


#####Convert all the na's to zeros
g_tab[is.na(g_tab)] = 0

###Remove base_line samples
g_tab = subset(g_tab, Treatment!="Base_Line")

#####Remove ribosomal proteins
g_tab = subset(g_tab, select = -c(TIGR03533,  TIGR00001,	TIGR00002,	TIGR00009,	
                                  TIGR00030,	TIGR00059,	TIGR00060,	TIGR00061,	TIGR00062,	TIGR00105,	TIGR00158,	
                                  TIGR00165,	TIGR00406,	TIGR00717,	
                                  TIGR00731,	TIGR00855,	TIGR00952,	TIGR00981,	TIGR01009,	
                                  TIGR01011,	TIGR01017,	TIGR01021,	TIGR01022,	
                                  TIGR01023,	TIGR01024,	TIGR01029,	TIGR01030,	TIGR01031,	
                                  TIGR01032,	TIGR01044,	TIGR01049,	TIGR01050,	TIGR01066,	
                                  TIGR01067,	TIGR01071,	TIGR01079,	TIGR01125,	TIGR01164,	
                                  TIGR01169,	TIGR01171,	TIGR01575,	TIGR01632,	
                                  TIGR03631,	TIGR03632,	
                                  TIGR03635,	TIGR03654,	TIGR03953))


#####Make a matrix that excludes all the metadata and is just numbers with the sample numbers as the row names
NAMES = rownames(g_tab)
g_matrix = g_tab[,6:1534]
rownames(g_matrix) = NAMES
g_matrix = as.matrix(g_matrix)
quantile(g_matrix)

NAMES = rownames(g_tab)
g_sample = g_tab[,1:2]
rownames(g_sample) = NAMES

############################
###########################
#####relative abundance normalization

g_rel = make_relative(g_matrix)

###########################
###########################
###########################

transposed_g_matrix = t(g_matrix)
dds = DESeqDataSetFromMatrix(countData = transposed_g_matrix,
                             colData = g_sample,
                             design = ~Site)
dds = estimateSizeFactors(dds)
dds = DESeq(dds)
res = results(dds)
resultsNames(dds)
res


############Coloring
library("viridis")
library("pheatmap")
npgpal=viridis_pal(option="viridis")(85)
ntd = normTransform(dds)

#########LDA heatmap based on all treatments --- Top ten genes per site
draw_colnames_90 <- function (coln, gaps, ...){
  coord = pheatmap:::find_coordinates(length(coln), gaps)
  x = coord$coord - 0.5 * coord$size
  res = textGrob(coln, x=x, y = unit(1, "npc") - unit(3,"bigpts"), vjust = 0.5, hjust = 1, rot =90, gp=gpar(...))
  return(res)}

assignInNamespace(x="draw_colnames", value="draw_colnames_90",
                  ns=asNamespace("pheatmap"))


map_colors = colorRampPalette(cividis(99))

####
combined_site = c("TIGR01818",	"TIGR01817",	"TIGR02915",	"TIGR02329",	"TIGR02974",	"TIGR02533",	"TIGR02538",	"TIGR01420",	"TIGR00786",	"TIGR02348",	"TIGR01804",	"TIGR00711",	"TIGR02299",	"TIGR02100",	"TIGR01780",	"TIGR03971",	"TIGR04284",	"TIGR03216",	"TIGR02891",	"TIGR02882",	"TIGR02956",	"TIGR03265",	"TIGR01187",	"TIGR04056",	"TIGR01184",	"TIGR02142",	"TIGR02314",	"TIGR02966",	"TIGR02073",	"TIGR02211")


levels(g_sample$Treatment)
levels(g_sample$Treatment) = c("drought", "field moist", "time zero saturation","flood")
levels(g_sample$Site)
levels(g_sample$Site) = c("Alaska","Florida","Washington")


kd_3soil_colors = list(
  Treatment = c("drought"="#fde725ff","field moist"="#35b779ff","flood"="#443a83ff","time zero saturation"="grey70"),
  Site = c("Alaska" = "#b84634","Florida"="#e6ab00","Washington"="#008cff"))


pheatmap(assay(ntd)[combined_site,],cluster_cols=FALSE,cluster_rows=FALSE,annotation_col = g_sample, color=cividis(99),
         annotation_colors=kd_3soil_colors, show_colnames = FALSE,
         labels_row = c("TIGR01818 Glutamine Synthase Regulator",	"TIGR01817 Nitrogen Fixation Regulation",	"TIGR02915 Transcription Factor",	"TIGR02329 Propionate Catabolism",	"TIGR02974 Phage Shock Protein Activator",	"TIGR02533 Type II Secretion System",	
                        "TIGR02538 Type IV-A Pilus",	"TIGR01420 Pilus Retraction Protein PilT",	"TIGR00786 TRAP Transporter",	"TIGR02348 Chaperonin GroL",	"TIGR01804 Betaine-Aldehyde Dehydrogenase",	"TIGR00711 EmrB Efflux Transporter",	"TIGR02299 5-carboxymethyl-2-hydroxymuconate semialdehyde dehyrogenase",
                        "TIGR02100 Glycogen Debranching Enzyme",	"TIGR01780 Succinate-Semialdehyde Dehydrogenase",	"TIGR03971 Mycofactocin-Dependent Oxidoreductase",	"TIGR04284 Aldehyde Dehydrogenase",	"TIGR03216 2-Hydroxymuconic Semialdehyde Dehydrogenase",	"TIGR02891 Cytochrome C oxidase",	
                        "TIGR02882 Cytochrome aa3 Quinol Oxidase",	"TIGR02956 TMAO Reductase System Sensor TorS",	"TIGR03265 2-Aminoethylphosphonate ABC Transporter",	"TIGR01187 Spermidine/Putrescine ABC Transporter",	"TIGR04056 Outer Member Protein",	"TIGR01184 Nitrate Transporter",	"TIGR02142 Molybdenum ABC Transporter",	
                        "TIGR02314 D-methionine ABC Transporter",	"TIGR02966 Phosphate Regulon Sensor Kinase PhoR",	"TIGR02073 Penicillin-Binding Protein 1C",	"TIGR02211 Lipoprotein Releasing System"))
######################################
#                                    #
#                                    #
#    base line vs sat II (flood)     #
#                                    #
#                                    #
#                                    #
######################################

rm(list=ls())

g_tab_blsat2 = read.table("metaT_combined_0.001perc_removed_blsat2.txt",sep="\t",header=TRUE,row.names=1)

#####Convert all the na's to zeros
g_tab_blsat2[is.na(g_tab_blsat2)] = 0

#####Remove ribosome genes

g_tab_blsat2 = subset(g_tab_blsat2, select = -c(TIGR00001,	TIGR00002,	TIGR00009,	TIGR00012,	TIGR00029,
                                                TIGR00030,	TIGR00059,	TIGR00060,	TIGR00061,	TIGR00062,	TIGR00105,	TIGR00158,	
                                                TIGR00165,	TIGR00166,	TIGR00279,  TIGR00717,	
                                                TIGR00731,	TIGR00855,	TIGR00952,	TIGR00981,	TIGR00982,	TIGR01008,	TIGR01009,	
                                                TIGR01011,	TIGR01012,	TIGR01017,	TIGR01018,	TIGR01020,	TIGR01021,	TIGR01022,	
                                                TIGR01023,	TIGR01024,	TIGR01025,	TIGR01028,	TIGR01029,	TIGR01030,	TIGR01031,	
                                                TIGR01032,	TIGR01038,	TIGR01044,	TIGR01046,	TIGR01049,	TIGR01050,	TIGR01066,	
                                                TIGR01067,	TIGR01071,	TIGR01079,	TIGR01080,	TIGR01125,	TIGR01164,	
                                                TIGR01169,	TIGR01170,	TIGR01171,	TIGR01308,	TIGR01632,	
                                                TIGR03626,	TIGR03627,	TIGR03628,	TIGR03629,	TIGR03631,	TIGR03632,	
                                                TIGR03635,	TIGR03654,	TIGR03953))

#####Make a matrix that excludes all the metadata and is just numbers with the sample numbers as the row names
NAMES = rownames(g_tab_blsat2)
g_matrix_blsat2 = g_tab_blsat2[,7:1146]
rownames(g_matrix_blsat2) = NAMES
g_matrix_blsat2 = as.matrix(g_matrix_blsat2)
quantile(g_matrix_blsat2)

NAMES = rownames(g_tab_blsat2)
g_sample_blsat2 = g_tab_blsat2[,1:2]
rownames(g_sample_blsat2) = NAMES


############################
###########################
#####relative abundance normalization

g_rel_blsat2 = make_relative(g_matrix_blsat2)



transposed_g_matrix_blsat2 = t(g_matrix_blsat2)
dds_blsat2 = DESeqDataSetFromMatrix(countData = transposed_g_matrix_blsat2,
                                    colData = g_sample_blsat2,
                                    design = ~Treatment)
dds_blsat2 = estimateSizeFactors(dds_blsat2)
dds_blsat2 = DESeq(dds_blsat2)
res_blsat2 = results(dds_blsat2)
resultsNames(dds_blsat2)
#write.table(res,file="log2fold_change_combined_0.001_bld.txt",sep="\t")

############Coloring
library("viridis")
library("pheatmap")
npgpal=viridis_pal(option="viridis")(85)
ntd_blsat2 = normTransform(dds_blsat2)

#########LDA heatmap based on all treatments

site_combined_blsat2=c("TIGR02006",	"TIGR03402",	"TIGR03235",	"TIGR02383",	"TIGR02638",	"TIGR02851",	"TIGR01139",	"TIGR01978",	"TIGR01136",	"TIGR00975",	"TIGR03458",	"TIGR00437",	"TIGR02729",	"TIGR03412",	"TIGR01361",	"TIGR01745",	"TIGR03904",	"TIGR00244",	"TIGR03997",	"TIGR02414",	"TIGR00198",	"TIGR01034",	"TIGR01963",	"TIGR01812",	"TIGR00089",	"TIGR00979",	"TIGR01971",	"TIGR03358",	"TIGR00505",	"TIGR02033",	"TIGR03181",	"TIGR02440",	"TIGR00132",	"TIGR02418",	"TIGR02441",	"TIGR02303",	"TIGR02169",	"TIGR01216",	"TIGR00680",	"TIGR02965")

levels(g_sample_blsat2$Treatment)
levels(g_sample_blsat2$Treatment) = c("base line","flood")
levels(g_sample_blsat2$Site)
levels(g_sample_blsat2$Site) = c("Alaska","Florida","Washington")

kd_3soil_colors = list(
  Treatment = c("base line"="grey70","flood"="#443a83ff"),
  Site = c("Alaska" = "#b84634","Florida"="#e6ab00","Washington"="#008cff"))

pheatmap(assay(vsd_blsat2)[site_combined_blsat2,],cluster_cols=FALSE,cluster_rows=FALSE,annotation_col = g_sample_blsat2,show_colnames=FALSE,color=cividis(99),
         annotation_colors=kd_3soil_colors,
         labels_row = c("TIGR02006 IscS Cysteine Desulfurase",	"TIGR03402 NifS Cysteine Desulfurase",	"TIGR03235 DndA Cysteine Desulfurase ",	"TIGR02383 Hfq RNA Chaperone",	"TIGR02638 Lactaldehyde Reductase",	"TIGR02851 spoVT",	"TIGR01139 cysK Cysteine Synthase A",	"TIGR01978 SufC FeS Assembly ATPase",	"TIGR01136 cysKM Cysteine Synthase",	"TIGR00975 pstS Phosphate ABC Transporter",	"TIGR03458 Succinate CoA Transferase",	"TIGR00437 FeoB Ferrous Iron Transporter",	"TIGR02729 CgtA GTPase",	"TIGR03412 IscX FeS Assembly Protein",	"TIGR01361 3-deoxy-7-phosphoheptulonate Synthase",	"TIGR01745 Aspartate-Semialdehyde Dehydrogenase",	"TIGR03904 YgiQ Uncharacterized Radical SAM Protein",	"TIGR00244 NrdR Transcriptional Regulator",	"TIGR03997 Mycofactocin System FadH/OYE Family Oxidoreductase 2",	"TIGR02414 pepN Aminopeptidase N",	"TIGR00198 katG Catalase/Peroxidase HPI",	"TIGR01034 metK S-adenosylmethionine Synthetase",	"TIGR01963 3-Hydroxybutyrate Dehydrogenase",	"TIGR01812 Succinate Dehydrogenase or Fumarate Reductase",	"TIGR00089 Radical SAM Methylthiotransferase",	"TIGR00979 fumC Fumarate Hydratase",	"TIGR01971 NADH-Quinone Oxidoreductase",	"TIGR03358 Type VI Secretion Protein",	"TIGR00505 GTP Cyclohydrolase II",	"TIGR02033 D-Hydantoinase",	"TIGR03181 Pyruvate Dehydrogenase",	"TIGR02440 fadJ Fatty Oxidation Complex",	"TIGR00132 gatA Aspartyl/Glutamyl-tRNA Amidotransferase",	"TIGR02418 alsS Acetolactate Synthase",	"TIGR02441 Fatty Oxidation Complex",	"TIGR02303 4-Hydroxyphenylacetate Degradation",	"TIGR02169 Chromosome Segregation Protein",	"TIGR01216 ATP Synthase",	"TIGR00680 kdpA K+-Transporting ATPase",	"TIGR02965 Xanthine Dehydrogenase"))

