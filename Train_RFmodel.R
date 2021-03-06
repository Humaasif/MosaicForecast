#!/usr/bin/env Rscript
.libPaths( c( .libPaths(), "/n/data1/hms/dbmi/park/yanmei/tools/R_packages/") )

args = commandArgs(trailingOnly=TRUE)

if (length(args)!=4) {
	stop("Rscript Train_RFmodel.R trainset prediction_model type_model(Phase|Refine) type_variant(SNP|INS|DEL)
	Note:
	The \"Phase\" model indicates the RF model trained on phasing (hap=2, hap=3, hap>3); 
	The \"Refine\" model indicates the RF model trained on Refined-genotypes from the multinomial logistic regression model (het, mosaic, repeat, refhom)
", call.=FALSE)
} else if (length(args)==4) {
	input_file <- args[1]
	prediction_model <- args[2]
	type <- as.character(args[3])
	type_variant <- as.character(args[4])
}

library(caret)
library(e1071)
set.seed(123)

my_chrXY <- function(x){
  !(strsplit(x,"~")[[1]][2]=="X"||strsplit(x,"~")[[1]][2]=="Y")
}

if (type=="Phase") {
#head demo/trainset
#id      dp_p    conflict_num    mappability     type    length  GCcontent       ref_softclip    alt_softclip    querypos_p      leftpos_p       seqpos_p        mapq_p  baseq_p baseq_t ref_baseq1b_p   ref_baseq1b_t       alt_baseq1b_p   alt_baseq1b_t   sb_p    context major_mismatches_mean   minor_mismatches_mean   mismatches_p    AF      dp      mosaic_likelihood       het_likelihood  refhom_likelihood  althom_likelihood        mapq_difference sb_read12_p     dp_diff phase   validation      pc1     pc2     pc3     pc4     phase_model_corrected
#1465~2~213242167~T~C    0.281242330831645       0       0.625   SNP     0       0.428571428571429       0.0150375939849624      0.00826446280991736     0.809467316642184       0.845437840198746       0.529485771832939   1       1.10459623063158e-05    4.39561488489149        8.75803415232249e-05    3.92264997745045        0.193506568120142       0.193506568120142       0.613465093083099       TAG     0.00370927318295739 0.0115151515151515      3.61059951117257e-20    0.476377952755905       254     0.0980449728144787      0.901955027185521       0       0       0       0.801304551054221       11.2142857142857    hap=2   het     1.06829805132481        -3.94107582807268       -1.47931744929006       -2.99768009916148       het
	input <- read.delim(input_file, header=TRUE)
	input <- input[apply(input,1,my_chrXY),]
	input$mapq_p[is.na(input$mapq_p)]<-1
	all_train <- input
	all_train <- subset(input, phase != "notphased")
	all_train$phase <- as.factor(as.character(all_train$phase))
	all_train <-all_train[!is.na(all_train$mosaic_likelihood),]
	#all_train.2 <- subset(all_train, select=-c(althom_likelihood, id, validation, dp_p, pc1, pc2, pc3, pc4, phase))
	#all_train.2 <- subset(all_train, select=c(querypos_p,leftpos_p,seqpos_p,mapq_p,baseq_p,baseq_t,ref_baseq1b_p,ref_baseq1b_t,alt_baseq1b_p,alt_baseq1b_t,sb_p,context,GCcontent,major_mismatches_mean,minor_mismatches_mean,mismatches_p,AF,dp,mapq_difference,sb_read12_p,dp_diff,mosaic_likelihood,het_likelihood,refhom_likelihood,phasing))
	if (type_variant=="SNP"){
		all_train.2 <- subset(all_train, select=c(querypos_p,leftpos_p,seqpos_p,mapq_p,baseq_p,baseq_t,ref_baseq1b_p,ref_baseq1b_t,alt_baseq1b_p,alt_baseq1b_t,sb_p,context,major_mismatches_mean,minor_mismatches_mean,mismatches_p,AF,dp,mapq_difference,sb_read12_p,dp_diff,mosaic_likelihood,het_likelihood,refhom_likelihood,phase,conflict_num,mappability, ref_softclip, alt_softclip, indel_proportion_SNPonly, alt2_proportion_SNPonly))
	}else if (type_variant=="INS"||type_variant=="DEL"){
		all_train.2 <- subset(all_train, select=c(querypos_p,leftpos_p,seqpos_p,mapq_p,baseq_p,baseq_t,ref_baseq1b_p,ref_baseq1b_t,alt_baseq1b_p,alt_baseq1b_t,sb_p,GCcontent,major_mismatches_mean,minor_mismatches_mean,mismatches_p,AF,dp,mapq_difference,sb_read12_p,dp_diff,mosaic_likelihood,het_likelihood,refhom_likelihood,phase,conflict_num,mappability,length,ref_softclip,alt_softclip))
	}
	
	control <- trainControl(method="repeatedcv", number=10, repeats=3, search="grid")
	tunegrid <- expand.grid(.mtry=30)
	metric <- "Accuracy"
	rf_gridsearch <- train(phase ~., data=all_train.2, method="rf", metric=metric,tuneGrid=tunegrid, trControl=control,na.action=na.exclude)
	saveRDS(rf_gridsearch,file=prediction_model)
	#input$prediction_phasing <- predict(rf_gridsearch, input)
	#write.table(input, "test.prediction",sep="\t",quote=FALSE,row.names=FALSE, col.names=TRUE)
} else if (type=="Refine"){
	input <- read.delim(input_file, header=TRUE)
	input <- input[apply(input,1,my_chrXY),]
	input$mapq_p[is.na(input$mapq_p)]<-1
	all_train <- input
	all_train <- subset(input, phase != "notphased")
	all_train$phase <- as.factor(as.character(all_train$phase))
	all_train <-all_train[!is.na(all_train$mosaic_likelihood),]
	#if(sum(all_train$MAF==".")>0){
	#        all_train$MAF<-0
	#}
	#all_train$MAF[is.na(all_train$MAF)]<-0
	if (type_variant=="SNP"){
	all_train.2 <- subset(all_train, select=c(querypos_p,leftpos_p,seqpos_p,mapq_p,baseq_p,baseq_t,ref_baseq1b_p,ref_baseq1b_t,alt_baseq1b_p,alt_baseq1b_t,sb_p,context,major_mismatches_mean,minor_mismatches_mean,mismatches_p,AF,dp,mapq_difference,sb_read12_p,dp_diff,mosaic_likelihood,het_likelihood,refhom_likelihood,phase_model_corrected,conflict_num,mappability, ref_softclip, alt_softclip, indel_proportion_SNPonly, alt2_proportion_SNPonly))
	}else if (type_variant=="INS" || type_variant=="DEL"){
	all_train.2 <- subset(all_train, select=c(querypos_p,leftpos_p,seqpos_p,mapq_p,baseq_p,baseq_t,ref_baseq1b_p,ref_baseq1b_t,alt_baseq1b_p,alt_baseq1b_t,sb_p,GCcontent,major_mismatches_mean,minor_mismatches_mean,mismatches_p,AF,dp,mapq_difference,sb_read12_p,dp_diff,mosaic_likelihood,het_likelihood,refhom_likelihood,phase_model_corrected,conflict_num,mappability,length,ref_softclip,alt_softclip))
}
	#all_train.2 <- subset(all_train, select=c(querypos_p,leftpos_p,seqpos_p,mapq_p,baseq_p,baseq_t,ref_baseq1b_p,ref_baseq1b_t,alt_baseq1b_p,alt_baseq1b_t,sb_p,context,GCcontent,major_mismatches_mean,minor_mismatches_mean,mismatches_p,AF,dp,mapq_difference,sb_read12_p,dp_diff,mosaic_likelihood,het_likelihood,refhom_likelihood,phase_corrected,MAF,repeats,ECNT,HCNT))
	
	all_train.2$sb_p[all_train.2$sb_p=="Inf"]<- 100
	all_train.2$sb_read12_p[all_train.2$sb_read12_p=="Inf"]<- 100
	
	control <- trainControl(method="repeatedcv", number=10, repeats=3, search="grid")
	tunegrid <- expand.grid(.mtry=30)
	metric <- "Accuracy"
	rf_gridsearch <- train(phase_model_corrected ~., data=all_train.2, method="rf", metric=metric,tuneGrid=tunegrid, trControl=control,na.action=na.exclude)
	saveRDS(rf_gridsearch,file=prediction_model)

#write.table(input, "test.prediction",sep="\t",quote=FALSE,row.names=FALSE, col.names=TRUE)
}



