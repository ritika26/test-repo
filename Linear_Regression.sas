/* Creating the library */
libname dst '/folders/myfolders/datasets';


/* Importing the file */
PROC IMPORT DATAFILE = '/folders/myfolders/raw_data/Inc_Exp_Data.csv' 
		DBMS = CSV 
		OUT = dst.inc_exp;
		GETNAMES = YES;
RUN;

proc print data = dst.inc_exp;
run;

ods graphics on;
title 'Household Income Vs Expense';
proc sgplot data = dst.inc_exp;
  scatter x = Mthly_HH_Income y = Mthly_HH_Expense ;
 run;
ods graphics off;


ods graphics off;
proc reg data = dst.inc_exp;
   model Mthly_HH_Expense = Mthly_HH_Income;
   ods output ParameterEstimates = PE;
run;

data _null_;
   set PE;
   if _n_ = 1 then call symput('Int', put(estimate, BEST6.));    
   else            call symput('Slope', put(estimate, BEST6.));  
run;
proc sgplot data = dst.inc_exp noautolegend;
   title "Household Income Vs Expense";
   reg y = Mthly_HH_Expense x = Mthly_HH_Income;
   inset "Intercept = &Int" "Slope = &Slope" / 
         border title = "Parameter Estimates" position = topleft;
run;
/* model buliding */
ods graphics on;
proc reg data = dst.inc_exp;
   model Mthly_HH_Expense = Mthly_HH_Income / corrb collin vif;
  run;
ods graphics off;

/* Checking correlation */
proc corr data =  dst.inc_exp;
run;

/* multiple linear regreesion */
ods graphics on;
proc reg data = dst.inc_exp;
   model Mthly_HH_Expense = Mthly_HH_Income 
   No_of_Fly_Members Emi_or_Rent_Amt 
   Annual_HH_Income/ corrb collin vif;
  run;
ods graphics off;

ods graphics on;
proc reg data = dst.inc_exp;
   model Mthly_HH_Expense = Mthly_HH_Income  
   No_of_Fly_Members  Emi_or_Rent_Amt / corrb collin vif;
  run;
ods graphics off;

data dst.inc_exp;
set dst.inc_exp;
sr_no = _n_;
run;