data lowrisk;
	set cvwoac.cv_analysis_set;
	where risk_group = 1;
run;

data lowrisk_w_TE;
	set lowrisk;
	where primary_outcome = 1;
run;

proc freq data = lowrisk;
	table  primary_outcome fu_01_30 fu_31_60 fu_61_90;
	weight discwt;
run;

proc freq data = lowrisk_w_te;
table CHADS2VASc;
weight discwt;
run;


proc surveylogistic data = lowrisk;
	model primary_outcome(event  =  '1') = CHADS2VASc;
 	strata NRD_STRATUM;
	cluster HOSP_NRD;
	domain index_admit;
	weight discwt;
run;

title1 justify = left 'CHADS2VASc Score';
title2 justify = left 'Among patients with primary outcome at low risk';
proc surveyfreq data = cvwoac.cv_analysis_set;
	table primary_outcome * CHADS2VASc / chisq row col;
 	strata NRD_STRATUM;
	cluster HOSP_NRD;
	weight discwt;
	where CHADS2VASc le 1;
run;

ods trace on;
proc surveyfreq data = lowrisk;
	table primary_outcome * CHADS2VASc / row col;
 	strata NRD_STRATUM;
	cluster HOSP_NRD;
	weight discwt;
	ods output crosstabs = low_risk_te_rate;
run;
ods trace off;

data low_risk_te_rate;
	set low_risk_te_rate;
	annual_rate = 12 * colpercent;
run;

/*
	proc surveylogistic data = cvwoac.cv_analysis_set;
	model primary_outcome(event  =  '1') = &factor.;
	strata NRD_STRATUM;
	cluster HOSP_NRD;
	domain index_admit;
	weight discwt;
	ods output OddsRatios = OR_&suffix. ParameterEstimates = param_&suffix.;
	run;
*/
ods trace on;
proc freq data = cvwoac.cv_analysis_set;
	table primary_outcome;
	where CHADS2VASc = 1;
	weight discwt;
	
run;
ods trace off;