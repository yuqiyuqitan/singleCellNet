# singleCellNet

### Introduction
See [CellNet](https://github.com/pcahan1/CellNet) for an introduction to CellNet, how to use it on bulk RNA-Seq, and how to analyze single cell RNA-Seq (scRNA-Seq) data with classifiers trained on bulk RNA-Seq. Here, we illustrate

- how to build and assess single cell classifiers 

- how to build and assess cross-species single cell classifiers

- how to use these classifiers to quantify 'cell identity' from query scRNA-Seq data

- how to cluster scRNA-Seq data using our 'cluster by competition' method

### DATA

In this example, we use a subset of the Tabula Muris data to train singleCellNet. To learn more about the Tabula Muris project, see the [manuscript])(https://www.biorxiv.org/content/early/2018/03/29/237446). As query data, we use scRNA-Seq of kidney cells as reported in [Park et al 2018](https://www.ncbi.nlm.nih.gov/pubmed/29622724). We also provide an example of classifying human, bead enriched PBMCs (from https://www.ncbi.nlm.nih.gov/pubmed/28091601). You can download this data here:

| APPLICATION | METADATA | EXPRESSION |
|-------------|----------|------------|
| Query       | [metadata](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/sampTab_Park_MouseKidney_062118.rda) | [expression data](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/expDat_Park_MouseKidney_062218.rda") |
| Training    | [metadata](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/sampTab_TM_053018.rda) | [expression data](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/expTM_Raw_053018.rda) |
| cross-species | [human-mouse orthologs](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/human_mouse_genes_Jul_24_2018.rda)| Query (human bead-purified PBMC from 10x) | [metadata](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/stDat_beads_mar22.rda) | [expression data](https://s3.amazonaws.com/cnobjects/singleCellNet/examples/6k_beadpurfied_raw.rda) |

#### Setup
```R
install_github("pcahan1/singleCellNet", ref="master", auth="your_token")
library(singleCellNet)
library(dplyr)

mydate<-utils_myDate()
```

#### Fetch the data if you have not already done so
```R
download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/sampTab_Park_MouseKidney_062118.rda", "sampTab_Park_MouseKidney_062118.rda")

download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/expMatrix_Park_MouseKidney_Oct_12_2018.rda", "expMatrix_Park_MouseKidney_Oct_12_2018.rda")

download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/expMatrix_TM_Raw_Oct_12_2018.rda", "expMatrix_TM_Raw_Oct_12_2018.rda")

download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/sampTab_TM_053018.rda", "sampTab_TM_053018.rda")

## For cross-species analyis:
download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/human_mouse_genes_Jul_24_2018.rda", "human_mouse_genes_Jul_24_2018.rda")

download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/6k_beadpurfied_raw.rda", "6k_beadpurfied_raw.rda")

download.file("https://s3.amazonaws.com/cnobjects/singleCellNet/examples/stDat_beads_mar22.rda", "stDat_beads_mar22.rda")

```

#### Load query data
```R
stPark<-utils_loadObject("sampTab_Park_MouseKidney_062118.rda")
expPark<-utils_loadObject("expMatrix_Park_MouseKidney_Oct_12_2018.rda")
dim(expPark)
[1] 16272 43745

genesPark<-rownames(expPark)

rm(expPark)
gc()
```

#### Load the training data
```R
expTMraw<-utils_loadObject("expMatrix_TM_Raw_Oct_12_2018.rda")
dim(expTMraw)
[1] 23433 24936

stTM<-utils_loadObject("sampTab_TM_053018.rda")
dim(stTM)
[1] 24936    17

stTM<-droplevels(stTM)
```

#### Find genes in common to the data sets and limit analysis to these
```R
commonGenes<-intersect(rownames(expTMraw), genesPark)
length(commonGenes)
[1] 13831

expTMraw<-expTMraw[commonGenes,]
```

#### Split for training and assessment, and transform training data
```R
stList<-splitCommon(stTM, ncells=100, dLevel="newAnn")
stTrain<-stList[[1]]
expTrain<-expTMraw[,rownames(stTrain)]


system.time(tmpX<-weighted_down(expTrain, 1.5e3, dThresh=0.25))
   user  system elapsed 
  4.837   0.845   5.711

system.time(expTrain<-trans_prop(tmpX, 1e4))
   user  system elapsed 
  1.486   0.645   2.136
```

#### Find the best set of classifier genes
```R

system.time(cgenes2<-findClassyGenes(expTrain, stTrain, "newAnn", topX=10))
  user  system elapsed 
 38.721  10.045  48.767

cgenesA<-cgenes2[['cgenes']]
grps<-cgenes2[['grps']]
length(cgenesA)
[1] 476

# heatmap these genes
hm_gpa_sel(expTrain, cgenesA, grps, maxPerGrp=5, toScale=T, cRow=F, cCol=F,font=4)
```
<img src="md_img/hm_tabulaMuris.png">

#### Find the best pairs
```R
expT<-as.matrix(expTrain[cgenesA,])
dim(expT)
[1]  476 3036

system.time(xpairs<-ptGetTop(expT, grps, topX=25, sliceSize=5000))
    user   system  elapsed 
1671.187 1406.671  154.199

length(xpairs)
[1] 799
```

#### TSP transform the training data
```R
system.time(pdTrain<-query_transform(expT[cgenesA, ], xpairs))

dim(pdTrain)
[1]  799 3036

 ```

#### Train the classifier
```R
system.time(rf_tspAll<-sc_makeClassifier(pdTrain[xpairs,], genes=xpairs, groups=grps, nRand=100, ntrees=1000))
  user  system elapsed 
  166.643   0.248 166.866
```

#### Apply to held out data -- this is the place to add the multi-class assessment
```R
stTest<-stList[[2]]

system.time(expQtransAll<-query_transform(expTMraw[cgenesA,rownames(stTest)], xpairs))
    user  system elapsed 
  4.221   2.751  11.369 


nrand<-100
system.time(classRes_val_all<-rf_classPredict(rf_tspAll, expQtransAll, numRand=nrand))
  user  system elapsed 
 37.136   1.522  38.691 

sla<-as.vector(stTest$newAnn)
names(sla)<-rownames(stTest)
slaRand<-rep("rand", nrand)
names(slaRand)<-paste("rand_", 1:nrand, sep='')
sla<-append(sla, slaRand)

# heatmap classification result
sc_hmClass(classRes_val_all, sla, max=300, isBig=TRUE)
```
<img src="md_img/hmClass_validation.png">


#### Attribution plot
```R
plot_attr(classRes_val_all, stTest, nrand=nrand, dLevel="newAnn", sid="cell")
```
<img src="md_img/attribution_val_101218.png">

#### UMAP by category
```R
system.time(umPrep<-prep_umap_class(classRes_val_all, stTest, nrand=nrand, dLevel="newAnn", sid="cell", topPC=5))
  user  system elapsed 
  109.500   3.588 113.067 

plot_umap(umPrep)
```
<img src="md_img/umap_val_101218.png">


#### Assess classifier
```R
newSampTab<-makeSampleTable(classRes_val_all, stTest, nrand, "cell")
tm_heldoutassessment <- assessmentReport_comm(classRes_val_all, newSampTab, classLevels='newAnn',dLevelSID='cell')
plot_PRs(tm_heldoutassessment)
```
<img src="md_img/pr_101218.png">

```R
plot_metrics(tm_heldoutassessment)
```
<img src="md_img/metrics_112918.png">


#### Apply to Park et al query data
```R
expPark<-utils_loadObject("expMatrix_Park_MouseKidney_Oct_12_2018.rda")
system.time(kidTransAll<-query_transform(expPark[cgenesA,], xpairs))
   user  system elapsed 
  8.594   3.314  15.704 
  
nqRand<-100
system.time(crParkall<-rf_classPredict(rf_tspAll, kidTransAll, numRand=nqRand))
  user  system elapsed 
 78.520   3.873  82.49

sgrp<-as.vector(stPark$description1)
names(sgrp)<-rownames(stPark)
grpRand<-rep("rand", nqRand)
names(grpRand)<-paste("rand_", 1:nqRand, sep='')
sgrp<-append(sgrp, grpRand)

# heatmap classification result
sc_hmClass(crParkall, sgrp, max=5000, isBig=TRUE, cCol=F, font=8)
```
<img src="md_img/hmClass_Park.png">


### Skyline plot of classification results
```R
stKid2<-addRandToSampTab(crParkall, stPark, "description1", "sample_name")
skylineClass(crParkall, "T cell", stKid2, "description1",.25, "sample_name")
```
<img src="md_img/skyline_Tcell_Park.png">


### Cross-species classification

#### Load the human query data
```R
stQuery<-utils_loadObject("stDat_beads_mar22.rda")
expQuery<-utils_loadObject("6k_beadpurfied_raw.rda") # use Matrix if RAM low
dim(expQuery)
[1] 32643  6000

expTMraw<-utils_loadObject("expMatrix_TM_Raw_Oct_12_2018.rda") # reload training

```

#### Load the ortholog table and convert human gene names to mouse ortholog names, and limit analysis to genes in common between the training and query data.
```R
oTab<-utils_loadObject("human_mouse_genes_Jul_24_2018.rda")
dim(oTab)
[1] 16688     3

aa = csRenameOrth(expQuery, expTMraw, oTab)
expQuery <- aa[['expQuery']]
expTrain <- aa[['expTrain']]
```

#### Limit anlaysis to a subset of the TM cell types
```R
cts<-c("B cell",  "cardiac muscle cell", "endothelial cell", "erythroblast", "granulocyte", "hematopoietic precursor cell", "late pro-B cell", "limb_mesenchymal", "macrophage", "mammary_basal_cell", "monocyte", "natural killer cell", "T cell", "trachea_epithelial", "trachea_mesenchymal")

stTM2<-filter(stTM, newAnn %in% cts)
stTM2<-droplevels(stTM2)
rownames(stTM2)<-as.vector(stTM2$cell) # filter strips rownames

expTrain<-expTrain[,rownames(stTM2)]
dim(expTrain)
[1] 14550 15161
```

#### Split into training and validation, normalize training data, and find classy genes
```R
stList<-splitCommon(stTM2, ncells=100, dLevel="newAnn")
stTrain<-stList[[1]]
dim(stTrain)
[1] 1457   17

expTMnorm<-trans_prop(weighted_down(expTrain[,rownames(stTrain)], 1.5e3, dThresh=0.25), 1e4)

system.time(cgenes2<-findClassyGenes(expTMnorm, stTrain, "newAnn", topX=10))
   user  system elapsed 
 12.735   3.114  15.847 


cgenesA<-cgenes2[['cgenes']]
grps<-cgenes2[['grps']]
length(cgenesA)
[1] 244

# heatmap these genes
hm_gpa_sel(expTrain, cgenesA, grps, maxPerGrp=20, toScale=T, cRow=F, cCol=F,font=4)
```
<img src="md_img/heatmap_classGenes_CS_heldOut_112918.png">


#### find best pairs and transform query data, and train classifier
```R
system.time(xpairs<-ptGetTop(expTMnorm[cgenesA,], grps, topX=25, sliceSize=5000))
   user  system elapsed 
117.248 120.292 115.127 

length(xpairs)
[1] 375

pdTrain<-query_transform(expTrain[cgenesA, rownames(stTrain)], xpairs)

dim(pdTrain)
[1]  375 1457

nrand = 50
system.time(rf_tspAll<-sc_makeClassifier(pdTrain[xpairs,], genes=xpairs, groups=grps, nRand=50, ntrees=1000))
   user  system elapsed 
 18.321   0.057  18.373
 ```

#### Apply to held out data
```R
stTest<-stList[[2]]

system.time(expQtransAll<-query_transform(expTrain[cgenesA,rownames(stTest)], xpairs))
   user  system elapsed 
  2.744   0.061   2.806 

nrand<-50
system.time(classRes_val_all<-rf_classPredict(rf_tspAll, expQtransAll, numRand=nrand))
   user  system elapsed 
  8.015   0.178   8.191 


sla<-as.vector(stTest$newAnn)
names(sla)<-rownames(stTest)
slaRand<-rep("rand", nrand)
names(slaRand)<-paste("rand_", 1:nrand, sep='')
sla<-append(sla, slaRand)

# heatmap classification result
sc_hmClass(classRes_val_all, sla, max=300, font=7, isBig=TRUE)
```
<img src="md_img/hmClass_CS_heldOut_112918.png">

#### Attribute plot
```R
plot_attr(classRes_val_all, stTest, nrand=nrand, dLevel="newAnn", sid="cell")
```
<img src="md_img/attribution_CS_heldout_112918.png">

#### UMAP by category
```R
system.time(umPrep<-prep_umap_class(classRes_val_all, stTest, nrand=nrand, dLevel="newAnn", sid="cell", topPC=5))
  user  system elapsed 
 79.352   1.578  81.177 

plot_umap(umPrep)
```
<img src="md_img/umap_CS_val_112918.png">

#### assess classifier
```R
newSampTab<-makeSampleTable(classRes_val_all, stTest, nrand, "cell")
tm_heldoutassessment <- assessmentReport_comm(classRes_val_all, newSampTab, classLevels='newAnn',dLevelSID='cell')
plot_PRs(tm_heldoutassessment)
```
<img src="md_img/pr_CS_heldout_112918.png">

```R
plot_metrics(tm_heldoutassessment)
```
<img src="md_img/metrics_CS_heldout_112918.png">

#### Apply to human query data
```R
system.time(expQueryTrans<-query_transform(expQuery[cgenesA,], xpairs))
  user  system elapsed 
  0.149   0.027   0.176 
  
nqRand<-50
system.time(crHS<-rf_classPredict(rf_tspAll, expQueryTrans, numRand=nqRand))
   user  system elapsed 
  2.390   0.068   2.456 

# heatmap classification result
sgrp<-as.vector(stQuery$prefix)
names(sgrp)<-rownames(stQuery)
grpRand<-rep("rand", nqRand)
names(grpRand)<-paste("rand_", 1:nqRand, sep='')
sgrp<-append(sgrp, grpRand)

sc_hmClass(crHS, sgrp, max=5000, isBig=TRUE, cCol=F, font=8)
```
<img src="md_img/hmClass_CS_101218.png">

Note that the macrophage category seems to be promiscuous in the mouse held out data, too.

#### Attribution plot
```R
plot_attr(crHS, stQuery, nrand=nqRand, dLevel="description", sid="sample_name")
```
<img src="md_img/attribution_CS_112918.png">

#### UMAP by category
```R
system.time(umPrep_HS<-prep_umap_class(crHS, stQuery, nrand=nqRand, dLevel="description", sid="sample_name", topPC=5))
  user  system elapsed
  26.666   0.957  27.741
plot_umap(umPrep_HS)
```
<img src="md_img/umap_CS_112918.png">

#### Assess classifier
```R
newSampTab_pbmc<-makeSampleTable(crHS, stQuery, nqRand, "sample_name")
tm_pbmc_assessment <- assessmentReport_comm(crHS, newSampTab_pbmc, classLevels='description',dLevelSID='sample_name')
plot_PRs(tm_pbmc_assessment)
```
<img src="md_img/pr_CS_112918.png">

```R
plot_metrics(tm_pbmc_assessment)
```
<img src="md_img/metrics_CS_112918.png">
