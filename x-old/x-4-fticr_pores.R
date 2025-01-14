### FTICR soil data
### this script is for cleaning and processing and creating the smaller, separate files that can then be used for analysis and graphing

### Kaizad F. Patel
### August 2019

source("0-packages.R")

## step 1: load the files ----

fticr_porewater = read_csv("data/FTICR_INPUT_SOILPORE.csv.zip")
corekey = read.csv("data/COREKEY.csv")

# this is the link to the google drive file
# https://drive.google.com/file/d/1dMjnCnMUYa5XY2ypVjz2HBQKx7E0YJY1/view?usp=sharing
# use report sn3

# write_csv(fticr_porewater, path = "fticr/fticr_porewater.csv")

#
## step 2: clean and process ----

## 2a: remove unnecessary columns. LOTS of unnecessary columns. fml. #### 
# This uses a seemingly arbitrary list that's experiment-specific. Kind of sucky

# Create a file with the list of columns to drop. 
# use the sample meta file for this. retain SampleType `sample` and `as`. (I don't know what `as` is.)

pore_sample_meta = read.csv("data/FTICR_INPUT_SOILPORE_meta.csv")

pore_sample_meta %>% 
  filter(!Sample_Type=="sample") %>% 
  filter(!Sample_Type=="as") %>% 
  dplyr::rename(code = `X21T_CCS.2_Day8_1.C11_11Jan18_Leopard_Infuse.qb`) -> # rename the f-ing column. WTAF is this column name. Checked -- it's not because a row was moved up. 
  pore_sample_meta

write.csv(pore_sample_meta$code, "data/fticr_columns_to_drop2.txt", row.names = FALSE, quote = FALSE)

drops <- readLines("data/fticr_columns_to_drop2.txt")
fticr_porewater[names(fticr_porewater) %in% drops] <- NULL

# clean up sample names because WTF 
# find the sample code (1 number followed by hyphen followed by letter followed by 1-2 numbers)
# example of sample code: 5_C10: core C10 from CPCRW, -50 kPa porewater

matches <- regexec("[0-9]-[A-Z][0-9]{1,2}", names(fticr_porewater))
matches_n <- unlist(matches)
lengths <- sapply(matches, function(x) attr(x, "match.length"))
# extract the part of the name we want and change
names <- substr(names(fticr_porewater), matches_n, matches_n + lengths - 1)
names(fticr_porewater)[matches_n > 0] <- names[matches_n > 0]

# remove addiitonal unnecessary names that couldn't be automated above
fticr_porewater %>% 
  select(-`C13`,-`3use`,-`Error_ppm`)->
  fticr_porewater

## split porewater file into metadata and sample data. ----
## sample data split by pore size (50 kPa and 1.5 kPa). 
fticr_pore_meta = as.data.frame(fticr_porewater[,1:11])
fticr_pore_data_50 = (select(fticr_porewater, "Mass", starts_with("5")))
fticr_pore_data_1 = (select(fticr_porewater, "Mass", starts_with("1")))

## meta: remove componds without class
fticr_pore_meta = fticr_pore_meta[!(fticr_pore_meta$Class=="None"),]

## create new columns for Aromatic Index, Nominal Oxidative State of Compounds, H/C, and O/C

#AImod = (1+C-1/2 O-S-1/2H)/(C=1/2 O -S-N-P). Formula from Bailey et al. 2017 SOC pore water
fticr_pore_meta$AImod = with(fticr_pore_meta, (1+C-(0.5*O)-S-(0.5*H))/(C-(0.5*O)-S-N-P))

#NOSC = 4-((4C+H-3N-2O-2S)/C). From Riedel et al. in Coward et al. 2019
fticr_pore_meta$NOSC = with(fticr_pore_meta, 4-(((4*C)+H-(3*N)-(2*O)-(2*S))/C))

fticr_pore_meta$HC = with(fticr_pore_meta, H/C)
fticr_pore_meta$OC = with(fticr_pore_meta, O/C)

### OUTPUT
write_csv(fticr_pore_meta, FTICR_PORE_META)

# melt/gather. transform from wide to long form
## using "gather" in the name despite using melt, to keep it consistent with the fticr_soil script
fticr_pore_gather_50 = fticr_pore_data_50 %>% 
  melt(id = "Mass")
fticr_pore_gather_1 = fticr_pore_data_1 %>% 
  melt(id = "Mass")


# remove all samples with zero intensity
fticr_pore_gather_50 = fticr_pore_gather_50[!(fticr_pore_gather_50$value=="0"),]
fticr_pore_gather_1 = fticr_pore_gather_1[!(fticr_pore_gather_1$value=="0"),]

# combine the 50 and 1.5 kPa files. rbind combines vertically
fticr_pore_gather = rbind(fticr_pore_gather_1,fticr_pore_gather_50)

# create columns for core # and tension
# use tension_2 to code the tension column using the stringr extraction function, and then delete tension_2 because it is unnecessary
fticr_pore_gather %>% 
  dplyr::rename(intensity = value) %>% # the melt function gave us a column value, rename to intensity
  mutate(tension_2 = substr(variable,start=1,stop=1)) %>% 
  mutate(core = substr(variable,start=3,stop=7)) %>% 
  mutate(tension = case_when(
    tension_2=="1"~"1.5 kPa",
    tension_2=="5"~"50 kPa")) ->
  fticr_pore_gather

fticr_pore_gather %>% 
  select(-tension_2,-variable) ->
  fticr_pore_gather

# merge with the core key file
fticr_pore_gather = left_join(corekey,fticr_pore_gather, by = "core")
#remove NA
fticr_pore_gather = fticr_pore_gather[complete.cases(fticr_pore_gather),]


### remove peaks seen in < 3 replicates 
# first, group 
# then, remove

fticr_pore_gather %>% 
  group_by(Mass,treatment,site, tension) %>% 
  dplyr::mutate(reps = n()) ->
  fticr_pore_gather2

fticr_pore_gather2 = fticr_pore_gather2[!(fticr_pore_gather2$reps<3),]

# write.csv(fticr_soil_gather,"fticr_soil_gather.csv")

### OUTPUT
write_csv(fticr_pore_gather2, FTICR_PORE_LONG)

#
## step 3: relative abundance ---- 
# merge the file with the metadata
fticr_pore_gather2  = left_join(fticr_pore_meta, fticr_pore_gather2, by = "Mass")
fticr_pore_gather2 = fticr_pore_gather2[complete.cases(fticr_pore_gather2),]

# summarizing by groups
fticr_pore_gather2 %>% 
  group_by(site, treatment,Class,core, tension) %>% 
  dplyr::summarize(compounds = sum(intensity)) ->
  fticr_pore_groups

fticr_pore_groups$compounds = as.numeric(fticr_pore_groups$compounds)

fticr_pore_groups_wide = spread(fticr_pore_groups,Class,compounds)
fticr_pore_groups_wide = as.data.frame(fticr_pore_groups_wide)

# create a `total` column adding counts across all "group" columns (columns 5-13)
fticr_pore_groups_wide %>%
  replace(.,is.na(.),0) ->
  fticr_pore_groups_wide

fticr_pore_groups_wide %>%
  mutate(total = rowSums(.[5:13])) ->
  fticr_pore_groups_wide

## 3.1 relative abundance: ----
# split the dataset into (a) just the abundance values for easy calculations, and (b) the core key. Then combine again.
fticr_pore_groups_wide[,-c(1:4)] %>% 
  sapply('/', fticr_pore_groups_wide$total/100)->
  fticr_pore_abundance

fticr_pore_abundance = data.frame(fticr_pore_abundance)
corenames = data.frame(fticr_pore_groups_wide[,c(1:4)])

fticr_pore_relabundance = cbind(corenames,fticr_pore_abundance)

### OUTPUT
# write.csv(fticr_soil_relabundance,"fticr_soil_relabund_cores.csv")
write_csv(fticr_pore_relabundance,path = "fticr/fticr_pore_relabund_cores.csv")

## relative abundance by treatment/site
fticr_pore_relabundance_long = fticr_pore_relabundance %>% 
  gather(group, relabund, AminoSugar:total)


fticr_pore_relabundance_summary = summarySE(fticr_pore_relabundance_long, measurevar = "relabund", groupvars = c("site","treatment","group","tension"),na.rm = TRUE)
fticr_pore_relabundance_summary$relativeabundance = paste((round(fticr_pore_relabundance_summary$relabund,2)),
                                                           "\u00B1",
                                                           round(fticr_pore_relabundance_summary$se,2))


## option1: don't like this way of table formatting. use option2 below
          #fticr_pore_relabundance_summarytable = dcast(fticr_pore_relabundance_summary,site+treatment+tension~group,value.var = "relativeabundance") 
          
          # move Unnamed and total columns to the end
          # "Unnamed" is "Other" for pores
          #fticr_pore_relabundance_summarytable %>% 
          #  select(-Other,Other) %>% 
          #  select(-total,total) ->
          #  fticr_pore_relabundance_summarytable
          
          # remove +/- SE values for the total column
          #fticr_pore_relabundance_summarytable$total="100"
          ## ## some cells have +/- 0. probably because n=1 for those. (??!!) double-check. 
          
          ### OUTPUT
          # write.csv(fticr_soil_relabundance_summarytable,"fticr_soil_relabundance_groups.csv")
          #write_csv(fticr_pore_relabundance_summarytable,path = "fticr/fticr_pore_relabundance_groups.csv")


## option2
# relativeabundance for the total rows is 100 +/- 0. set it to 100
setDT(fticr_pore_relabundance_summary)[group=="total", relativeabundance := "100"]

# cast the table in a different manner, with groups as rows
fticr_pore_relabundance_summarytable2 = dcast(fticr_pore_relabundance_summary,
                                              group~tension+site+treatment,
                                              value.var = "relativeabundance") 

# write_csv(fticr_pore_relabundance_summarytable2, path = "fticr/fticr_pore_relabundance_groups2.csv")

#
## 3.2 stats for the rel_abund summary table -- HSD ----
      # NOT DOING THIS, SWITCHED TO DUNNETT'S TEST
      #  # create a function to calculate aov and hsd. this function can then be used for rel_abund for each site/tension/group
      #  
      #  fit_hsd_relabund <- function(dat) {
      #    a <-aov(relabund ~ treatment, data = dat)
      #    h <-HSD.test(a,"treatment")
      #    #create a tibble with one column for each treatment
      #    #the hsd results are row1 = drought, row2 = saturation, row3 = time zero saturation, row4 = field moist. hsd letters are in column 2
      #    tibble(`drought` = h$groups["drought",2], 
      #           `saturation` = h$groups["saturation",2],
      #           `time zero saturation` = h$groups["time zero saturation",2],
      #           `field moist` = h$groups["field moist",2])
      #  }
      #  
      #  fticr_pore_relabundance_long[!fticr_pore_relabundance_long$group=="total",] %>% 
      #    group_by(site, tension, group) %>% 
      #    do(fit_hsd_relabund(.))  ->
      #    pore_relabund_hsd
      #  
      #  pore_relabund_hsd %>% 
      #    gather(treatment, hsd, 4:7)-> #gather columns 4-7 (treatment levels)
      #    pore_relabund_hsd2
      #  
      #  # now merge this with `fticr_pore_relabundance_summary`
      #  
      #  fticr_pore_relabundance_summary2 = merge(fticr_pore_relabundance_summary, pore_relabund_hsd2, by = c("tension","site","group","treatment"))
      #  fticr_pore_relabundance_summary2$relativeabundance = paste(fticr_pore_relabundance_summary2$relativeabundance," ",fticr_pore_relabundance_summary2$hsd)
      #  
      #  fticr_pore_relabundance_summary2table2 = dcast(fticr_pore_relabundance_summary2,
      #                                                group~tension+site+treatment,value.var = "relativeabundance") 
      #  
      #  ### OUTPUT
      #  write_csv(fticr_pore_relabundance_summary2,FTICR_PORE_RELABUND)

#


#
## 3.3 stats for the rel_abund summarry table -- Dunnett ----
## Dunnett's Test compares all levels to a single control treatment
## we want to compare drought, saturation, field moist against TZsaturation

fit_dunnett_relabund <- function(dat) {
  d <-DescTools::DunnettTest(relabund~treatment, control = "time zero saturation", data = dat)
  #create a tibble with one column for each treatment
  # column 4 has the pvalue
  t = tibble(`drought` = d$`time zero saturation`["drought-time zero saturation",4], 
         `saturation` = d$`time zero saturation`["saturation-time zero saturation",4],
         `field moist` = d$`time zero saturation`["field moist-time zero saturation",4])
  # we need to convert significant p values to asterisks
  # since the values are in a single row, it is tricky
  t %>% 
  # first, gather all p-values into a single column, pval
    gather(trt, pval, 1:3) %>% 
  # conditionally replace all significant pvalues (p<0.05) with asterisks and the rest remain blank
    mutate(p = if_else(pval<0.05, "*","")) %>% 
  # remove the pval column
    dplyr::select(-pval) %>% 
  # spread the p (asterisks) column bnack into the three columns
    spread(trt, p)  ->
    t
}

fticr_pore_relabundance_long[!fticr_pore_relabundance_long$group=="total",] %>% 
  group_by(site, tension, group) %>% 
  do(fit_dunnett_relabund(.))  ->
  pore_relabund_dunnett

pore_relabund_dunnett %>% 
  gather(treatment, dunnett, 4:6)-> #gather columns 4-7 (treatment levels)
  pore_relabund_dunnett2

# now merge this with `fticr_pore_relabundance_summary`

fticr_pore_relabundance_summary %>% 
  left_join(pore_relabund_dunnett2,by = c("tension","site","group","treatment"), all.x = TRUE) %>% 
  replace(.,is.na(.),"") %>% 
  dplyr::mutate(relativeabundance = paste(relativeabundance,dunnett)) %>% 
  dplyr::select(-se,-sd, -ci, -dunnett,-N,)->
  fticr_pore_relabundance_summary2

### OUTPUT
write_csv(fticr_pore_relabundance_summary2,FTICR_PORE_RELABUND)




## step 3-2: count peaks ----

# summarizing by groups
fticr_pore_gather2 %>% 
  group_by(tension,site,treatment,Class) %>% 
  dplyr::summarize(peaks = n()) %>% # get count of each group/class for each tension-site-treatment
  group_by(tension,site,treatment) %>% 
  dplyr::mutate(total = sum(peaks)) -> # then create a new column for sum of all peaks for each tension-site-treatment
  fticr_pore_peaks

# we need to combine the total value into the existing groups column
fticr_pore_peaks %>% 
  spread(Class,peaks) %>% # first, convert into wide-form, so each group is a column
  dplyr::select(-total,total) %>% # move total to the end
  gather(Class,peaks_count,AminoSugar:total)-> # combine all the groups+total into a single column
  fticr_pore_peaks2

# now we need to format into a better table
# first, move total to the end
old.lvl = levels(factor(fticr_pore_peaks2$Class))
fticr_pore_peaks2$Class = factor(fticr_pore_peaks2$Class, 
                                            levels=c(sort(old.lvl[old.lvl!="total"]), "total"))


fticr_pore_peaks2 %>% 
  dcast(Class~tension+site+treatment, value.var = "peaks_count")->
  fticr_pore_peaks3

### OUTPUT
write_csv(fticr_pore_peaks2,FTICR_PORE_PEAKS)



#
## step 4: molecules added/lost ----

# first, combine all cores within each treatment
fticr_pore_gather_trtsummary = summarySE(fticr_pore_gather2, measurevar = "intensity", groupvars = c("site", "treatment","tension", "Mass"))

# second, split the file into three, for the three sites
fticr_pore_gather_trtsummary_c = fticr_pore_gather_trtsummary[fticr_pore_gather_trtsummary$site=="CPCRW",1:5]
fticr_pore_gather_trtsummary_d = fticr_pore_gather_trtsummary[fticr_pore_gather_trtsummary$site=="DWP",1:5]
fticr_pore_gather_trtsummary_s = fticr_pore_gather_trtsummary[fticr_pore_gather_trtsummary$site=="SR",1:5]

# third, make a new column that is binary for presence (1) and absence (0). if N>0, a molecule is present
setDT(fticr_pore_gather_trtsummary_c)[N>0, presence := "1"]  

# fourth, split the treatment column into five separate columns. this will make further calculations easier.
fticr_pore_gather_trtsummary_c2 = dcast(fticr_pore_gather_trtsummary_c, Mass+tension ~ treatment, value.var = "presence")

# fifth, replace all NA with 0 for subsequent subtraction
fticr_pore_gather_trtsummary_c2 %>% 
  replace(.,is.na(.),0) ->
  fticr_pore_gather_trtsummary_c2

# sixth, convert all columns into numeric and transform this mess into a dataframe. the mutate functions (next) will not work if it is not a dataframe. fml
fticr_pore_gather_trtsummary_c2[,3:6] = sapply(fticr_pore_gather_trtsummary_c2[,3:6], as.numeric)
fticr_pore_gather_trtsummary_c2 = data.frame(fticr_pore_gather_trtsummary_c2)

# seventh, create new columns for molecules added/lost for each treatment. subtract all treatments from baseline
### THERE ARE NO BASELINE DATA IN THIS DATASET. SO SUBTRACT TZSATURATION INSTEAD OF BASELINE.
# +1 = new molecule, -1 = lost molecule, 0 = molecule present or absent in treatment&baseline
fticr_pore_gather_trtsummary_c2 %>% 
  mutate(drought_new = drought - time.zero.saturation) %>% 
  mutate(saturation_new = saturation - time.zero.saturation) %>% 
  mutate(fieldmoist_new = field.moist - time.zero.saturation) ->
  fticr_pore_gather_trtsummary_c2

# eighth, create a new column for unique molecules
setDT(fticr_pore_gather_trtsummary_c2)[time.zero.saturation==0 & saturation==1 & drought==0 & field.moist==0, unique := "saturation"]
fticr_pore_gather_trtsummary_c2[time.zero.saturation==0 & saturation==0 & drought==1 & field.moist==0, unique := "drought"]
fticr_pore_gather_trtsummary_c2[time.zero.saturation==0 & saturation==0 & drought==0 & field.moist==1, unique := "field_moist"]

# ninth, add 'site' column for when we bind later
fticr_pore_gather_trtsummary_c2$site="CPCRW"


## repeat all steps with DWP

# 
setDT(fticr_pore_gather_trtsummary_d)[N>0, presence := "1"]  

#
fticr_pore_gather_trtsummary_d2 = dcast(fticr_pore_gather_trtsummary_d, Mass+tension ~ treatment, value.var = "presence")

#
fticr_pore_gather_trtsummary_d2 %>% 
  replace(.,is.na(.),0) ->
  fticr_pore_gather_trtsummary_d2

#
fticr_pore_gather_trtsummary_d2[,3:6] = sapply(fticr_pore_gather_trtsummary_d2[,3:6], as.numeric)
fticr_pore_gather_trtsummary_d2 = data.frame(fticr_pore_gather_trtsummary_d2)

#
### THERE ARE NO BASELINE DATA IN THIS DATASET. SO SUBTRACT TZSATURATION INSTEAD OF BASELINE.
# +1 = new molecule, -1 = lost molecule, 0 = molecule present or absent in treatment&baseline
fticr_pore_gather_trtsummary_d2 %>% 
  mutate(drought_new = drought - time.zero.saturation) %>% 
  mutate(saturation_new = saturation - time.zero.saturation) %>% 
  mutate(fieldmoist_new = field.moist - time.zero.saturation) ->
  fticr_pore_gather_trtsummary_d2

#
setDT(fticr_pore_gather_trtsummary_d2)[time.zero.saturation==0 & saturation==1 & drought==0 & field.moist==0, unique := "saturation"]
fticr_pore_gather_trtsummary_d2[time.zero.saturation==0 & saturation==0 & drought==1 & field.moist==0, unique := "drought"]
fticr_pore_gather_trtsummary_d2[time.zero.saturation==0 & saturation==0 & drought==0 & field.moist==1, unique := "field_moist"]

#
fticr_pore_gather_trtsummary_d2$site="DWP"


## repeat all steps with SR

# 
setDT(fticr_pore_gather_trtsummary_s)[N>0, presence := "1"]  

#
fticr_pore_gather_trtsummary_s2 = dcast(fticr_pore_gather_trtsummary_s, Mass+tension ~ treatment, value.var = "presence")

#
fticr_pore_gather_trtsummary_s2 %>% 
  replace(.,is.na(.),0) ->
  fticr_pore_gather_trtsummary_s2

#
fticr_pore_gather_trtsummary_s2[,3:6] = sapply(fticr_pore_gather_trtsummary_s2[,3:6], as.numeric)
fticr_pore_gather_trtsummary_s2 = data.frame(fticr_pore_gather_trtsummary_s2)

#
### THERE ARE NO BASELINE DATA IN THIS DATASET. SO SUBTRACT TZSATURATION INSTEAD OF BASELINE.
# +1 = new molecule, -1 = lost molecule, 0 = molecule present or absent in treatment&baseline
fticr_pore_gather_trtsummary_s2 %>% 
  mutate(drought_new = drought - time.zero.saturation) %>% 
  mutate(saturation_new = saturation - time.zero.saturation) %>% 
  mutate(fieldmoist_new = field.moist - time.zero.saturation) ->
  fticr_pore_gather_trtsummary_s2

#
setDT(fticr_pore_gather_trtsummary_s2)[time.zero.saturation==0 & saturation==1 & drought==0 & field.moist==0, unique := "saturation"]
fticr_pore_gather_trtsummary_s2[time.zero.saturation==0 & saturation==0 & drought==1 & field.moist==0, unique := "drought"]
fticr_pore_gather_trtsummary_s2[time.zero.saturation==0 & saturation==0 & drought==0 & field.moist==1, unique := "field_moist"]

#
fticr_pore_gather_trtsummary_s2$site="SR"




### now, combine all three dataframes

fticr_pore_new = rbind (fticr_pore_gather_trtsummary_c2,fticr_pore_gather_trtsummary_d2,fticr_pore_gather_trtsummary_s2)

## remove the presence/absence columns, they are now unnecessary
fticr_pore_new = data.frame(fticr_pore_new[,-c(3:6)])
fticr_pore_new[,3:5] = sapply(fticr_pore_new[,3:5], as.factor)

## recode 1, -1 to presence and absence. do this in new columnns
## this dataframe now has the original numeric coding for new/lost, the new character coding for new/lost, and a column for unique molecules in each treatment

fticr_pore_new %>% 
  mutate(drought = case_when(
    drought_new=="1"~"new",
    drought_new=="-1"~"lost")) %>% 
  mutate(saturation = case_when(
    saturation_new=="1"~"new",
    saturation_new=="-1"~"lost")) %>%
  mutate(field.moist = case_when(
    fieldmoist_new=="1"~"new",
    fieldmoist_new=="-1"~"lost"))  ->
  fticr_pore_new

## subset only the character coding columns for new/lost 
fticr_pore_new %>% 
  select("Mass","site","tension","saturation","field.moist","drought")->
  fticr_pore_new2

## melt/gather into long-form. make new columns for treatment and newmolecules
fticr_pore_new2 = (fticr_pore_new2) %>% 
  gather(treatment, newmolecules,saturation:drought)

## remove NA
fticr_pore_new2 = fticr_pore_new2[complete.cases(fticr_pore_new2),]

## merge the file with the metadata

fticr_pore_new3 = merge(fticr_pore_meta,fticr_pore_new2, by = "Mass")

## OUTPUT
write_csv(fticr_pore_new3, path = "fticr/fticr_pore_newmolecules.csv")


#
## step 4b: unique molecules ----

fticr_pore_unique = fticr_pore_new %>% 
  select("Mass","site","tension","unique")

## remove NA
fticr_pore_unique = fticr_pore_unique[complete.cases(fticr_pore_unique),]

## merge the file with metadata

fticr_pore_unique2 = merge(fticr_pore_meta, fticr_pore_unique, by = "Mass")

## OUTPUT
write_csv(fticr_pore_unique2, FTICR_PORE_UNIQUE)




## step 4b-2: unique molecules peaks ----

# summarizing by groups
fticr_pore_unique2 %>% 
  dplyr::group_by(tension,site, unique,Class) %>% 
  dplyr::summarize(peaks_count = n())  %>% 
  group_by(tension,site,unique) %>% 
  dplyr::mutate(total = sum(peaks_count))->
  fticr_pore_unique_peaks

fticr_pore_unique_peaks %>% 
  spread(Class,peaks_count) %>% # first, convert into wide-form, so each group is a column
  dplyr::select(-total,total) %>% # move total to the end
  gather(Class,peaks_count,AminoSugar:total)-> # combine all the groups+total into a single column
  fticr_pore_unique_peaks2

fticr_pore_unique_peaks2 = fticr_pore_unique_peaks2[complete.cases(fticr_pore_unique_peaks2),]



### OUTPUT
write_csv(fticr_pore_unique_peaks2,FTICR_PORE_UNIQUE_PEAKS)


## option2
# relativeabundance for the total rows is 100 +/- 0. set it to 100
setDT(fticr_pore_relabundance_summary)[group=="total", relativeabundance := "100"]

# cast the table in a different manner, with groups as rows
fticr_pore_relabundance_summarytable2 = dcast(fticr_pore_relabundance_summary,
                                              group~tension+site+treatment,value.var = "relativeabundance") 
write_csv(fticr_pore_relabundance_summarytable2,path = "fticr/fticr_pore_relabundance_groups2.csv")






## step 5: HC, OC data for van krevelen ----

# subset only select columns from fticr_soil_gather2

fticr_pore_gather2 %>% 
  select("core","site","treatment","tension","Mass","HC","OC","intensity") %>% 
  mutate(HC = round(HC,2)) %>%   
  mutate(OC = round(OC,2))  %>% 
  mutate(intensity = round(intensity,2))  ->
  fticr_pore_hcoc
## R message: Adding missing grouping variables: `treatment`, `site` -- happened for soil but not for pores. weird

### OUTPUT
# write.csv(fticr_soil_hcoc,"fticr_soil_hcoc.csv")
write_csv(fticr_pore_hcoc, FTICR_PORE_HCOC)

#

## step 6: NOSC data ----
fticr_pore_gather2 %>% 
  select("core","site","treatment","tension","Mass","NOSC","intensity") %>% 
  mutate(NOSC = round(NOSC,4)) ->
  fticr_pore_nosc

### OUTPUT
# write.csv(fticr_soil_nosc,"fticr_soil_nosc.csv")
write_csv(fticr_pore_nosc, FTICR_PORE_NOSC)

# NOSC summary - mean
fticr_pore_nosc_summary = summarySE(fticr_pore_nosc, measurevar = "NOSC", groupvars = c("tension","site","treatment"), na.rm = TRUE)
fticr_pore_nosc_summary$nosc = paste(round(fticr_pore_nosc_summary$NOSC,2),"\u00B1",round(fticr_pore_nosc_summary$se,2))
fticr_pore_nosc_summarytable = dcast(fticr_pore_nosc_summary, treatment~tension+site,value.var = "nosc")

# NOSC summary - median
fticr_pore_nosc %>% 
  dplyr::group_by(tension, site, treatment) %>% 
  dplyr::summarise(nosc_median = median(NOSC))->
  fticr_pore_nosc_median
fticr_pore_nosc_median_summarytable = dcast(fticr_pore_nosc_median, treatment~tension+site,value.var = "nosc_median")

#

## step 7: kendrick mass data ----
# subset relevant columns, and then create new columns for kendrickmass and kendrickmassdefect

fticr_pore_gather2 %>% 
  select(core,site,treatment,tension,Mass,intensity) %>% 
  mutate(intensity = round(intensity,2))  ->
  fticr_pore_kendrick


# kendrick mass = Mass * 14.00000/14.01565
# kendrick mass defect = nominal mass - kendrick mass.  (nominal mass = integer of mass)
# https://en.wikipedia.org/wiki/Kendrick_mass

nominal_ch2 = 14.00000
iupac_ch2 = 14.01565

fticr_pore_kendrick %>% 
  mutate(kmass = Mass*nominal_ch2/iupac_ch2) %>% 
  mutate(kdefect = as.integer(Mass) - kmass) ->
  fticr_pore_kendrick

### OUTPUT
# write.csv(fticr_soil_kendrick,"fticr_soil_kendrick.csv")
write_csv(fticr_pore_kendrick,path = "fticr/fticr_pore_kendrick.csv")

#

## step 8: aromatic peaks ----
fticr_pore_gather2 %>% 
  select("core","site","treatment","tension","Mass","AImod","intensity") %>% 
  mutate(AImod = round(AImod,4)) %>% 
  mutate(intensity = round(intensity,2))->
  fticr_pore_aromatic

setDT(fticr_pore_aromatic)[AImod>0.5, aromatic := "aromatic"]

fticr_pore_aromatic %>% 
  group_by(site, treatment, core, tension,aromatic) %>% 
  dplyr::mutate(arom_core_counts = n()) ->
  fticr_pore_aromatic

## remove the non-aromatic peaks
fticr_pore_aromatic = fticr_pore_aromatic[complete.cases(fticr_pore_aromatic),]

### OUTPUT
# write.csv(fticr_soil_aromatic,"fticr_soil_aromatic.csv")
write_csv(fticr_pore_aromatic,path = "fticr/fticr_pore_aromatic.csv")

# summary by treatment. then remove NA to keep only aromatic counts
fticr_pore_aromatic_counts = summarySE(fticr_pore_aromatic, measurevar = "arom_core_counts", groupvars = c("core","aromatic","site","treatment","tension"))
fticr_pore_aromatic_counts = fticr_pore_aromatic_counts[complete.cases(fticr_pore_aromatic_counts),]

### OUTPUT
# write.csv(fticr_soil_aromatic_counts,"fticr_soil_aromatic_counts.csv")
write_csv(fticr_pore_aromatic_counts,path = "fticr/fticr_pore_aromatic_counts.csv")
write_csv(fticr_pore_aromatic_counts,FTICR_PORE_AROMATIC)

#


