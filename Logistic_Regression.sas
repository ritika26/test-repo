/* Creating the library */
libname dst '/folders/myfolders/datasets';

/* Importing the file */
PROC IMPORT DATAFILE='/folders/myfolders/raw_data/LR_DF.csv' DBMS=CSV 
		OUT=dst.LR_DF;
	GETNAMES=YES;
RUN;

data DST.LR_DF;
	infile '/folders/myfolders/raw_data/LR_DF.csv' 
	delimiter=',' MISSOVER DSD 
	lrecl=32767 firstobs=2;
	informat Cust_ID $8.;
	informat Target best32.;
	informat Age best32.;
	informat Gender $3.;
	informat Balance best32.;
	informat Occupation $16.;
	informat No_OF_CR_TXNS best32.;
	informat AGE_BKT $7.;
	informat SCR best32.;
	informat Holding_Period best32.;
	format Cust_ID $8.;
	format Target best12.;
	format Age best12.;
	format Gender $3.;
	format Balance best12.;
	format Occupation $16.;
	format No_OF_CR_TXNS best12.;
	format AGE_BKT $7.;
	format SCR best12.;
	format Holding_Period best12.;
	input Cust_ID $
          Target Age Gender $
          Balance Occupation $
          No_OF_CR_TXNS AGE_BKT $
          SCR Holding_Period;

run;

proc contents data=dst.lr_df;
run;

proc means data=dst.lr_df;
run;

PROC freq DATA=dst.LR_DF;
	table AGE_BKT Gender Occupation;
RUN;

proc univariate data=dst.lr_df;
	var Balance Age Holding_Period;
	output out=uni_out p1=p1 p5=p5 p10=p10 p25=p25 p50=p50 
	p75=p75 p90=p90 p95=p95 p99=p99 max=p100;
run;

/* Boxplot */
title 'Balance Box Plot';

proc sgplot data=dst.lr_df;
	vbox Balance;
run;

/* Let us cap the Balance variable at P99. */
data dst.lr_df;
	set dst.lr_df;

	if Balance > 723000 then
		BAL_CAP=723000;
	else
		BAL_CAP=Balance;
run;

/* Deciling Code */
%macro decile(in_out_dst=, 
				in_var=, ngroups = 10, 
				descending = ,
				out_decile_var=);
proc rank data = &in_out_dst. 
	groups = &ngroups.  &descending.  out = &in_out_dst.;
	var &in_var.;
	ranks &out_decile_var.;
run;
%mend;


%macro rank_order(in_out_dst =, Target =, 
		in_var =, out_decile_var =, 
		ngroups = 10,
		descending= ,ks = 0  );

%decile(in_out_dst = &in_out_dst., in_var=&in_var.,
		ngroups = &ngroups.,
		descending = &descending., 
		out_decile_var = &out_decile_var.);

proc sql ;
	create table RRATE as 
	Select &out_decile_var. as &out_decile_var., 
	min(&in_var.) as MIN, 
	max(&in_var.) as MAX, 
	round(mean(&in_var.), 0.001) as AVG, 
	count(1) as CNT_CUST, sum(&Target.) as CNT_RESP, 
	sum(case when &Target. = 0 then 1 else 0 end) as CNT_NON_RESP, 
	round(sum(&Target.) * 100 / count(1), 0.01) as RRATE 
	From &in_out_dst. 
	Group by &out_decile_var.
	order by &out_decile_var.;
quit;

%if &KS = 1 %then %do; 
	PROC SQL noprint; 
	SELECT SUM(CNT_RESP), SUM(CNT_NON_RESP) INTO :N_GOOD, :N_BAD 
	FROM RRate; 
	QUIT; 
	
	DATA RRate; 
	set RRate ; 
	IF _n_ = 1 THEN DO; 
	CUM_RESP = 0; 
	CUM_NON_RESP = 0; 
	CUM_TOT_CUST = 0; 
	END; 
	CUM_RESP + CNT_RESP; 
	CUM_NON_RESP + CNT_NON_RESP; 
	CUM_TOT_CUST + CNT_CUST; 
	CUM_RESP_PCT = ROUND(CUM_RESP * 100 / &N_GOOD., 0.01); 
	CUM_NON_RESP_PCT= ROUND(CUM_NON_RESP * 100 / &N_BAD., 0.01); 
	KS = ABS(ROUND(CUM_RESP_PCT - CUM_NON_RESP_PCT, 0.01)); 
	&out_decile_var. = &ngroups. - &out_decile_var.;
	RUN; 
%end;


proc print data=RRATE; run;

%mend;


/* Missing Value Imputation */

%rank_order(in_out_dst =dst.lr_df, Target = Target, 
				in_var = Holding_Period, out_decile_var = HP_Decile);
data dst.lr_df;
	set dst.lr_df;
	if Holding_Period=. then
		HP_Imputed=18;
	else
		HP_Imputed=Holding_Period;
run;

proc tabulate data=dst.lr_df missing;
	class Target Occupation;
	table Target ALL, Occupation ALL;
	keylabel n=' ';
run;

data dst.lr_df;
	set dst.lr_df;
	length OCC_Imputed $16;
	if Occupation='' then
		OCC_Imputed='MISSING';
	else
		OCC_Imputed=Occupation;
run;

proc tabulate data=dst.lr_df missing;
	class Target OCC_Imputed;
	table Target ALL, OCC_Imputed ALL;
	keylabel n=' ';
run;

/******* Continuous Variable Visualization *******/
%rank_order(in_out_dst =dst.lr_df, Target = Target, 
				in_var = Age, out_decile_var = Decile );


%rank_order(in_out_dst =dst.lr_df, Target = Target, 
				in_var = HP_Imputed, out_decile_var = Decile );

				
%rank_order(in_out_dst =dst.lr_df, Target = Target, 
				in_var = Balance, out_decile_var = Decile );

data dst.lr_df;
	set dst.lr_df;
	if Age > 43  then
		DV_Age= 43-(Age-43);
	else
		DV_Age=Age;
run;

/* Model development */


   
data mydata;
	set dst.lr_df;
	n=ranuni(7);
run;

data data_dev data_val data_hold;
   set mydata nobs=nobs;
   if n <= .5 then output data_dev;
    else if n <= 0.8 then output data_val;
    else output data_hold;
run;


proc sql;
select sum(Target)/count(1) as target_rate_mydata
from     WORK.MYDATA;
select sum(Target)/count(1) as target_rate_val
from     WORK.DATA_VAL;
select sum(Target)/count(1) as target_rate_hold
from      WORK.DATA_HOLD;
select sum(Target)/count(1) as target_rate_dev
from      WORK.DATA_DEV;
quit;



proc logistic data = data_dev namelen = 200 
outest = PE outmodel = out_dst descending;
class   OCC_Imputed Gender;
model Target =  DV_Age Gender 
		OCC_Imputed  SCR Balance
		No_OF_CR_TXNS HP_Imputed / lackfit
selection= forward slentry = 0.05 slstay = 0.001; 
output out=LR_OUT prob=prob;
run;

/* Removing Gender */

proc logistic data = data_dev namelen = 200 
outest = PE outmodel = out_dst descending plots=roc;
class    OCC_Imputed ;
model Target =  DV_Age  
		OCC_Imputed  SCR Balance
		No_OF_CR_TXNS HP_Imputed / lackfit
selection= forward slentry = 0.05 slstay = 0.0001; 
output out=LR_OUT prob=prob;
run;



proc sql ;
	create table work.PP as 
	Select OCC_Imputed as OCC_Imputed, 
	sum(Target) as cnt_resp, 
	sum(Target=0) as cnt_non_resp, 
	count(1) as cnt, 
	round(sum(Target) * 100 / count(1), 0.001) as rrate 
	From data_dev
	Group by OCC_Imputed;
quit;

proc print data=work.PP;
run;

data data_dev;
set data_dev;
length DV_OCC $16;

if OCC_Imputed='SAL' or OCC_Imputed='SENP' then
	DV_OCC='SAL-SENP';
else if OCC_Imputed='MISSING' or OCC_Imputed='PROF' then
	DV_OCC='MISSING-PROF';
else
	DV_OCC=OCC_Imputed;
run;

proc freq data = data_dev;
	table DV_OCC;
run;



/* Using Merged Occupation Categories */

proc logistic data = data_dev namelen = 200 
outest = PE outmodel = out_dst descending plots=roc;
class    DV_OCC ;
model Target =  DV_Age  
		DV_OCC  SCR Balance
		No_OF_CR_TXNS HP_Imputed / lackfit
selection= forward slentry = 0.05 slstay = 0.0001; 
output out=LR_OUT prob=prob;
run;


proc reg data =  DATA_DEV;
model Target =  DV_Age  
		SCR Balance
		No_OF_CR_TXNS HP_Imputed / vif;
run;


%rank_order(in_out_dst = LR_OUT, Target = Target, in_var = prob, 
	out_decile_var = Decile, ngroups = 10, descending = descending, ks = 1);



/*********** Model Validation **************/
data data_val;
set data_val;
length DV_OCC $16;

if OCC_Imputed='SAL' or OCC_Imputed='SENP' then
	DV_OCC='SAL-SENP';
else if OCC_Imputed='MISSING' or OCC_Imputed='PROF' then
	DV_OCC='MISSING-PROF';
else
	DV_OCC=OCC_Imputed;
run;


proc logistic data =  WORK.DATA_VAL namelen = 200 
outest = PE_val outmodel = out_dst_val descending plots=roc;
class    DV_OCC ;
model Target =  DV_Age  
		DV_OCC  SCR Balance
		No_OF_CR_TXNS HP_Imputed / lackfit
selection= forward slentry = 0.05 slstay = 0.0001; 
output out=LR_OUT_val prob=prob;
run;

data betaratio;
set  WORK.PE  WORK.PE_VAL;
keep  Intercept Balance DV_Age DV_OCCMISSING_PROF 
	DV_OCCSAL_SENP HP_Imputed No_OF_CR_TXNS SCR;
run;

proc transpose data = betaratio out= betaratio;
run;

data betaratio;
set betaratio;
rename col1=DEV col2= VAL;
drop _label_;
run;

Proc SQL;
create table betatable as
select _name_ as Name,
DEV as DEV, VAL as VAL,
DEV/VAL as betaratio
from  betaratio;
quit;

proc print data = betatable; run;

proc freq data = data_dev; table DV_OCC * Target/nocol nopercent; run;
proc freq data = data_val; table DV_OCC * Target/nocol nopercent; run;


/***** Weight of Evidence *****/
proc freq data = data_dev; table Occ_Imputed * Target/nocol nopercent norow; run;

data data_dev;
set data_dev;
if OCC_Imputed = 'SAL' then DV_Occ_WoE = -55.75;
else if OCC_Imputed = 'SENP' then DV_Occ_WoE = -111.47;
else if OCC_Imputed = 'SELF-EMP' then DV_Occ_WoE = 61.46;
else if OCC_Imputed ='PROF' then DV_Occ_WoE = -4.53;
else DV_Occ_WoE = 13.21;
run;

data data_val;
set data_val;
if OCC_Imputed = 'SAL' then DV_Occ_WoE = -55.75;
else if OCC_Imputed = 'SENP' then DV_Occ_WoE = -111.47;
else if OCC_Imputed = 'SELF-EMP' then DV_Occ_WoE = 61.46;
else if OCC_Imputed ='PROF' then DV_Occ_WoE = -4.53;
else DV_Occ_WoE = 13.21;
run;


proc logistic data = data_dev namelen = 200 
outest = PE outmodel = out_dst descending plots=roc;
class     ;
model Target =  DV_Age  
		DV_Occ_WoE  SCR Balance
		No_OF_CR_TXNS HP_Imputed / lackfit
selection= forward slentry = 0.05 slstay = 0.0001; 
output out=LR_OUT prob=prob;
run;


proc logistic data =  DATA_VAL namelen = 200 
outest = PE_val outmodel = out_dst_val descending plots=roc;
class     ;
model Target =  DV_Age  
		DV_Occ_WoE  SCR Balance
		No_OF_CR_TXNS HP_Imputed / lackfit
selection= forward slentry = 0.05 slstay = 0.0001; 
output out=LR_OUT_val prob=prob;
run;




proc logistic inmodel= WORK.OUT_DST;
   score data = WORK.DATA_VAL;
run;
