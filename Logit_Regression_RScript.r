## Let us first create our dataset for modeling
setwd("D:/K2Analytics/Datafile/temp_out")
load(file = "LR_DF.RData")
View(LR_DF)




lr_ds1 <- read.table("LR_DS1.csv",sep = ",", header = T)
head(lr_ds1)

tail(lr_ds1)


lr_ds2 <- read.fwf( "LR_FWF.txt",
widths=c(6,3), header = T, sep = "|", strip.white = T)

head(lr_ds2)

tail(lr_ds2)


###Importing excel file using XLConnect
##install.packages("XLConnect")
library(XLConnect)
wb <- loadWorkbook( "LR_Xls.xlsx" )
sh <- getSheets(wb)
sh[1]
lr_ds3 <- readWorksheet(wb, sheet = "HoldingPeriod", 
	startRow = 1, header = T)

head(lr_ds3)

tail(lr_ds3)

cbind(nrow(lr_ds3), ncol(lr_ds3))

## Merging the datasets to create the Modeling Dataset
lr_df <- merge(x=lr_ds1, y=lr_ds2, by = "Cust_ID")

LR_DF <- merge(x=lr_df, y=lr_ds3, by="Cust_ID", all.x=T)
cbind(nrow(LR_DF), ncol(LR_DF))

head(LR_DF)

save(LR_DF, file = "LR_DF.RData")
## We have our Logistic Regression Data Frame LR_DF ready for modeling
## Step 1 - Understand your data


summary(LR_DF)

## run the standard deviation on all the fields in the dataset
##sapply(LR_DF, sd)

## See the percentile distribution
quantile(LR_DF$Balance, 
c(0.01, 0.05, 0.1, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99, 1))


quantile(LR_DF$Age, 
c(0.01, 0.05, 0.1, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99, 1))

## What if I want the percentile distribution for all the fields
apply(LR_DF[,sapply(LR_DF, is.numeric)], 
2, quantile, 
probs=c(0.01, 0.05, 0.1, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99, 1),
na.rm=T)


## Typically we floor and cap the variables at P1 and P99. 
## Let us cap the Balance variable at P99.
LR_DF$BAL_CAP <- 
ifelse(LR_DF$Balance > 723000, 723000, LR_DF$Balance)

summary(LR_DF$BAL_CAP)
sd(LR_DF$BAL_CAP)

quantile(LR_DF$BAL_CAP, 
c(0.01, 0.05, 0.1, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99, 1))


## Missing Value Imputation for Holding Period
#### Creating a function to decile the records function
decile <- function(x){
  deciles <- vector(length=10)
  for (i in seq(0.1,1,.1)){
    deciles[i*10] <- quantile(x, i, na.rm=T)
  }
  return (
  ifelse(x<deciles[1], 1,
    ifelse(x<deciles[2], 2,
      ifelse(x<deciles[3], 3,
        ifelse(x<deciles[4], 4,
          ifelse(x<deciles[5], 5,
            ifelse(x<deciles[6], 6,
              ifelse(x<deciles[7], 7,
                ifelse(x<deciles[8], 8,
                  ifelse(x<deciles[9], 9, 10
  ))))))))))
}



tmp <- LR_DF
tmp$deciles <- decile(tmp$Holding_Period)
View(tmp)

library(data.table)
tmp_DT = data.table(tmp)
RRate <- tmp_DT[, list(
min_hp = min(Holding_Period), 
max_hp = max(Holding_Period), 
avg_hp = mean(Holding_Period),
cnt = length(Target), 
cnt_resp = sum(Target), 
cnt_non_resp = sum(Target == 0)) , 
by=deciles][order(deciles)]
RRate$rrate <- RRate$cnt_resp * 100 / RRate$cnt;
View(RRate)
?mean
mean(LR_DF$Holding_Period, na.rm = T)


LR_DF$HP_Imputed <- ifelse(is.na(LR_DF$Holding_Period), 
18, LR_DF$Holding_Period)

summary(LR_DF$HP_Imputed)
summary(LR_DF$Holding_Period)

## two-way contingency table of categorical outcome and predictors we want
## to make sure there are not 0 cells
##m = table(LR_DF$Target ,LR_DF$Occupation)
##prop.table(m) * 100 # Relative frequency scaled up to a percentage
##prop.table(m,1) # Scale cells by the row sum
##prop.table(m,2) # Scale cells by the column sum

CrossTable(LR_DF$Target, LR_DF$Occupation)
ctab <- xtabs(~Target + Occupation, data = LR_DF)
ctab
class(LR_DF$Occupation)


LR_DF$Occupation <- as.character(LR_DF$Occupation)


LR_DF$OCC_Imputed <- ifelse(LR_DF$Occupation=="", 
"MISSING", LR_DF$Occupation)


LR_DF$Occupation <- as.factor(LR_DF$Occupation)
table(LR_DF$OCC_Imputed)



## Let us find the variables Information Value

##setwd(folderpath)
##load(file = "LR_DF.RData")
##install.packages("devtools")
library(devtools)
##install_github("tomasgreif/riv")


##install_github("riv","tomasgreif")

##
library(devtools)
library(woe)

iv.mult(LR_DF[,!names(LR_DF) %in% c("Cust_ID")]
        , "Target",TRUE)

        
        ##iv.mult(LR_DF[,!names(LR_DF) %in% c("Cust_ID")], "Target", TRUE)
iv.plot.summary(iv.mult(LR_DF[,!names(LR_DF) %in% c("Cust_ID")],
"Target",TRUE))
View(LR_DF)
summary(LR_DF)
## Pattern Detection
## Visualization Function
library(data.table)
library(scales)
fn_biz_viz <- function(df, target, var)
{
  
  tmp <- df[, c(var , target)]
  colnames(tmp)[1] = "Xvar"
  colnames(tmp)[2] = "Target"
  
  
  tmp$deciles <- decile(tmp$Xvar)
  
  
  tmp_DT = data.table(tmp)
  
  RRate <- tmp_DT[, list(
    min_ = min(Xvar), max_ = max(Xvar), avg_ = mean(Xvar),
    cnt = length(Target), cnt_resp = sum(Target), 
    cnt_non_resp = sum(Target == 0)
  ) , 
  by=deciles][order(deciles)]
  
  RRate$range = paste(RRate$min_ , RRate$max_ , sep = " to ");
  RRate$prob <- round(RRate$cnt_resp / RRate$cnt,2);
  
  setcolorder(RRate, c(1, 8, 2:7, 9))
  
  
  RRate$cum_tot <- cumsum(RRate$cnt)
  RRate$cum_resp <- cumsum(RRate$cnt_resp)
  RRate$cum_non_resp <- cumsum(RRate$cnt_non_resp)
  RRate$cum_tot_pct <- round(RRate$cum_tot / sum(RRate$cnt),2);
  RRate$cum_resp_pct <- round(RRate$cum_resp / sum(RRate$cnt_resp),2);
  RRate$cum_non_resp_pct <- round(RRate$cum_non_resp / sum(RRate$cnt_non_resp),2);
  RRate$ks <- abs(RRate$cum_resp_pct - RRate$cum_non_resp_pct);
  
  RRate$prob = percent(RRate$prob)
  RRate$cum_tot_pct = percent(RRate$cum_tot_pct)
  RRate$cum_resp_pct = percent(RRate$cum_resp_pct)
  RRate$cum_non_resp_pct = percent(RRate$cum_non_resp_pct)
  
  ## Output the RRate table to csv file
  ## you should ensure the setwd -  working directory 
  write.csv(RRate, file = paste0(output_folder, var, ".csv"),
            row.names = FALSE)
  View(RRate)
}

LR_DF$Occupation = as.factor(LR_DF$Occupation)
LR_DF$OCC_Imputed = as.factor(LR_DF$OCC_Imputed)
## Set the working directory folder where you wish to dump the output
output_folder = "D:/K2Analytics/Logistic_Regression/Visualizations/"
Target_var_name = "Target"

fn_biz_viz(df = LR_DF, target = Target_var_name, var = "Age")
fn_biz_viz(df = LR_DF, target = Target_var_name, var = "Balance")

col_list = colnames(LR_DF)[
              lapply(LR_DF, class) %in% c("numeric", "integer")
            ]


for (i in 1 : length(col_list)) {
  fn_biz_viz(df = LR_DF, target = Target_var_name, var = col_list[i])
}


LR_DF$DV_Age = ifelse(LR_DF$Age <= 43, LR_DF$Age, 
                      43 - (LR_DF$Age - 43)
                      )



fn_biz_viz(df = LR_DF, target = Target_var_name, var = "DV_Age")


summary(LR_DF)

mydata <- LR_DF
mydata$random <- runif(nrow(mydata), 0, 1)
View(mydata)
mydata.dev <- mydata[which(mydata$random <= 0.5),]
mydata.val <- mydata[which(mydata$random > 0.5 & mydata$random <= 0.8),]
mydata.hold <- mydata[which(mydata$random > 0.8),]
nrow(mydata.dev)
nrow(mydata.val)
nrow(mydata.hold)

sum(mydata.dev$Target)/ nrow(mydata.dev)
sum(mydata.val$Target)/ nrow(mydata.val)
sum(mydata.hold$Target)/ nrow(mydata.hold)

##install.packages("aod")
##install.packages("ggplot2")
library(aod)
library(ggplot2)
colnames(mydata)
?glm
attach(mydata.dev)
detach(mydata.dev)
mylogit <- glm(
Target ~  BAL_CAP + No_OF_CR_TXNS + SCR  + HP_Imputed + OCC_Imputed, 
data = mydata.dev[,-c(1,14)], family = "binomial"
)
colnames(mydata)
summary(mylogit)


table(mydata.dev$OCC_Imputed, mydata.dev$Target)

class(mydata.dev$OCC_Imputed)
mydata.dev$DV_Occupation = ifelse(mydata.dev$OCC_Imputed == "MISSING" 
                             | mydata.dev$OCC_Imputed == "PROF" , 
                             "PROF_MISSING", mydata.dev$OCC_Imputed )

table(mydata.dev$DV_Occupation, mydata.dev$Target)
mydata.dev$DV_BAL_CAP = mydata.dev$BAL_CAP / 1000

mydata.dev$DV_HP <- ifelse(mydata.dev$HP_Imputed >= 18, 18, mydata.dev$HP_Imputed)

mylogit <- glm(
  Target ~  BAL_CAP + No_OF_CR_TXNS + SCR  + DV_HP + DV_Occupation , 
  data = mydata.dev[,-c(1,14)], family = "binomial"
)

mydata.dev$DV_Age = ifelse(mydata.dev$Age > 43, 
                           mydata.dev$Age - (mydata.dev$Age - 43),
                           mydata.dev$Age)
summary(mylogit)



mydata.val$DV_Occupation = ifelse(mydata.val$OCC_Imputed == "MISSING" 
                                  | mydata.val$OCC_Imputed == "PROF" , 
                                  "PROF_MISSING", mydata.val$OCC_Imputed )
View(mydata.dev)


mylogit_v <- glm(
  Target ~  BAL_CAP + No_OF_CR_TXNS + SCR  + DV_HP + DV_Occupation , 
  data = mydata.val[,-c(1,14)], family = "binomial"
)

summary(mylogit_v)


##install.packages("car")
library(car)
vif(mylogit)



## Summary output of the glm
summary_output = summary(mylogit)
write(capture.output(summary_output), 
      file = "logistic.txt", append = FALSE, sep=" ")
 


## We use the wald.test function. b supplies the coefficients, while Sigma supplies the variance covariance matrix of the 
## error terms, finally Terms tells R which terms in the model are to be tested, in this case, terms 4, 5, and 6, are the 
## three terms for the levels of rank.
## wald.test(b = coef(mylogit), Sigma = vcov(mylogit), Terms = 4:6)

## Calculating the probabilities
##ranked_data = mydata
##ranked_data$prob <- predict(mylogit, newdata=mydata, type="response")
##head(ranked_data)

## Calculating the probabilities
View(mydata.dev)
?predict
mydata.dev$prob <- predict(mylogit, mydata.dev, type="response")
head(mydata.dev)


## Creating Deciles for Rank Ordering Test
mydata.dev$deciles <- decile(mydata.dev$prob)


##mydata$y = -4.376697 +  0.771705 * mydata$No_OF_CR_TXNS_ln + -0.065168 * mydata$HP_Imputed 
##mydata$p <- exp(mydata$y)/ (1+exp(mydata$y))

############ Goodness of Fit: ##############
####
# A function to do the Hosmer-Lemeshow test in R.
# R Function is due to Peter D. M. Macdonald, McMaster University.
# 
hosmerlem <-
 function (y, yhat, g = 10) 
 {
     cutyhat <- cut(yhat, breaks = quantile(yhat, probs = seq(0, 
         1, 1/g)), include.lowest = T)
     obs <- xtabs(cbind(1 - y, y) ~ cutyhat)
     expect <- xtabs(cbind(1 - yhat, yhat) ~ cutyhat)
     chisq <- sum((obs - expect)^2/expect)
     P <- 1 - pchisq(chisq, g - 2)
     c("X^2" = chisq, Df = g - 2, "P(>Chi)" = P)
 }
#
######
# Doing the Hosmer-Lemeshow test
# (after copying the above function into R):

hl_gof = hosmerlem(mydata.dev$Target, mydata.dev$prob )
hl_gof
write("\n\n----Hosmer Lemeshow Goodness of Fit----", file = "logistic.txt", append = TRUE, sep = " ")
write(capture.output(hl_gof), file = "logistic.txt", append = TRUE, sep=" ")
# The P-value will not match SAS's P-value perfectly but should be close.





## Creating Deciles for Rank Ordering Test
mydata$deciles <- decile(mydata$prob)

# order data frame
mydata <- mydata[with(mydata, order(prob)),]



#### Rank Ordering Table #####
library(data.table)
mydata.DT = data.table(mydata.dev)
mydata.DT$deciles <- decile(mydata.DT$prob)

rank <- mydata.DT[, 
                  list(min_prob = min(prob), 
                       max_prob = max(prob), 
                       cnt = length(Target), 
                      cnt_resp = sum(Target), 
                      cnt_non_resp = sum(Target == 0), 
                    sum_prob = sum(prob)) 
, by=deciles][order(-deciles)]

rank$RRate <- rank$cnt_resp / rank$cnt
rank$cum_resp <- cumsum(rank$cnt_resp)
rank$cum_non_resp <- cumsum(rank$cnt_non_resp)
rank$cum_rel_resp <- rank$cum_resp / sum(rank$cnt_resp);
rank$cum_rel_non_resp <- rank$cum_non_resp / sum(rank$cnt_non_resp);
rank$ks <- abs(rank$cum_rel_resp - rank$cum_rel_non_resp);

View(rank)
write("\n\n----Rank Ordering Table----", file = "logistic.txt", append = TRUE, sep = " ")
write(capture.output(rank), file = "logistic.txt", append = TRUE, sep=" ")

DT <- data.table(mydata.dev)

library(sqldf)
sqldf("select deciles, count(1) as cnt, 
sum(Target) as Obs_Resp, 
sum(Target==0) as Obs_Non_Resp, 
sum(prob) as Exp_Resp,
sum(1-prob) as Exp_Non_Resp 
from DT
group by deciles
order by deciles desc")


### Calculating ROC Curve and KS for the model
##install.packages("ROCR")
library(ROCR)
pred <- prediction(mydata$prob, mydata$Target)
perf <- performance(pred, "tpr", "fpr")
plot(perf, col="green", lwd=2, main="ROC Curve")
abline(a=0,b=1,lwd=2,lty=2,col="gray")

KS <- max(attr(perf, 'y.values')[[1]]-attr(perf, 'x.values')[[1]])
KS
cat("\n\n----KS from ROCR Curve (compare it with Rank Ordering Table also----\n", file = "logistic.txt", append = TRUE, sep = " ")
cat("KS = "  , file = "logistic.txt", append = TRUE)
cat(KS  , file = "logistic.txt", append = TRUE)
cat("\n\n"  , file = "logistic.txt", append = TRUE)




############ GINI Index ##############
##install.packages("ineq")
library(ineq)
gini = ineq(mydata.dev$prob, type="Gini")
gini
cat("\n\n----Gini Coefficient----\n", file = "logistic.txt", append = TRUE, sep = " ")
cat("Gini = "  , file = "logistic.txt", append = TRUE)
cat(gini  , file = "logistic.txt", append = TRUE)
cat("\n\n"  , file = "logistic.txt", append = TRUE)

gini

#***FUNCTION TO CALCULATE CONCORDANCE AND DISCORDANCE***#
concordance=function(y, yhat)
{
Con_Dis_Data = cbind(y, yhat) 
ones = Con_Dis_Data[Con_Dis_Data[,1] == 1,]
zeros = Con_Dis_Data[Con_Dis_Data[,1] == 0,]
conc=matrix(0, dim(zeros)[1], dim(ones)[1])
disc=matrix(0, dim(zeros)[1], dim(ones)[1])
ties=matrix(0, dim(zeros)[1], dim(ones)[1])
for (j in 1:dim(zeros)[1])
{
for (i in 1:dim(ones)[1])
{
if (ones[i,2]>zeros[j,2])
{conc[j,i]=1}
else if (ones[i,2]<zeros[j,2])
{disc[j,i]=1}
else if (ones[i,2]==zeros[j,2])
{ties[j,i]=1}
}
}
Pairs=dim(zeros)[1]*dim(ones)[1]
PercentConcordance=(sum(conc)/Pairs)*100
PercentDiscordance=(sum(disc)/Pairs)*100
PercentTied=(sum(ties)/Pairs)*100
return(list("Percent Concordance"=PercentConcordance,"Percent Discordance"=PercentDiscordance,"Percent Tied"=PercentTied,"Pairs"=Pairs))
}
#***FUNCTION TO CALCULATE CONCORDANCE AND DISCORDANCE ENDS***#


concordance_output = concordance(mydata.dev$Target, mydata.dev$prob)
concordance_output
cat("\n\n----Concordance----\n", file = "logistic.txt", append = TRUE, sep = " ")
# create a connection
sink("logistic.txt", append=T, split=T)
# for each element in the list, print
for (list_name in names(concordance_output)) {
cat(list_name, unlist(concordance_output[list_name]),"\n", file = "logistic.txt", append = TRUE) }
# close connection 
sink()


mydata.val$DV_HP <- ifelse(mydata.val$HP_Imputed >= 18, 18, mydata.val$HP_Imputed)

mylogit_v <- glm(
  Target ~  BAL_CAP + No_OF_CR_TXNS + SCR  + DV_HP + DV_Occupation , 
  data = mydata.val[,-c(1,14)], family = "binomial"
)

summary(mylogit)

summary(mylogit_v)

mydata.val$prob <- predict(mylogit_v, mydata.val, type="response")

hl_gof_v = hosmerlem(mydata.val$Target, mydata.val$prob )
hl_gof_v



## Creating Deciles for Rank Ordering Test
mydata.val$deciles <- decile(mydata.val$prob)

# order data frame
mydata <- mydata[with(mydata, order(prob)),]



#### Rank Ordering Table #####
library(data.table)
mydata.DT = data.table(mydata.val)

rank_v <- mydata.DT[, 
                  list(min_prob = min(prob), 
                       max_prob = max(prob), 
                       cnt = length(Target), 
                       cnt_resp = sum(Target), 
                       cnt_non_resp = sum(Target == 0), 
                       sum_prob = sum(prob)) 
                  , by=deciles][order(-deciles)]

rank_v$RRate <- rank_v$cnt_resp / rank_v$cnt
rank_v$cum_resp <- cumsum(rank_v$cnt_resp)
rank_v$cum_non_resp <- cumsum(rank_v$cnt_non_resp)
rank_v$cum_rel_resp <- rank_v$cum_resp / sum(rank_v$cnt_resp);
rank_v$cum_rel_non_resp <- rank_v$cum_non_resp / sum(rank_v$cnt_non_resp);
rank_v$ks <- abs(rank_v$cum_rel_resp - rank_v$cum_rel_non_resp);

View(rank_v)
## Creating Derived Variables in Hold Out
mydata.hold$DV_HP <- ifelse(mydata.hold$HP_Imputed >= 18, 18, mydata.hold$HP_Imputed)

mydata.hold$DV_Occupation = ifelse(mydata.hold$OCC_Imputed == "MISSING" 
                                  | mydata.hold$OCC_Imputed == "PROF" , 
                                  "PROF_MISSING", mydata.hold$OCC_Imputed )
View(mydata.hold)
## Hold Out Test for Rank Ordering
mydata.hold$prob <- predict(mylogit, mydata.hold, type="response")

## Creating Deciles for Rank Ordering Test
mydata.hold$deciles <- decile(mydata.hold$prob)




#### Rank Ordering Table #####

mydata.DT = data.table(mydata.hold)

rank_v <- mydata.DT[, 
                    list(min_prob = min(prob), 
                         max_prob = max(prob), 
                         cnt = length(Target), 
                         cnt_resp = sum(Target), 
                         cnt_non_resp = sum(Target == 0), 
                         sum_prob = sum(prob)) 
                    , by=deciles][order(-deciles)]

rank_v$RRate <- rank_v$cnt_resp / rank_v$cnt
rank_v$cum_resp <- cumsum(rank_v$cnt_resp)
rank_v$cum_non_resp <- cumsum(rank_v$cnt_non_resp)
rank_v$cum_rel_resp <- rank_v$cum_resp / sum(rank_v$cnt_resp);
rank_v$cum_rel_non_resp <- rank_v$cum_non_resp / sum(rank_v$cnt_non_resp);
rank_v$ks <- abs(rank_v$cum_rel_resp - rank_v$cum_rel_non_resp);

View(rank_v)
