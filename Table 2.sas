*table of readmission incidence;
ods exclude all;
proc surveyfreq data = cvwoac.cv_analysis_set;
	table index_admit * risk_group * (primary_outcome fu_01_30 fu_31_60 fu_61_90) / row ;
	format risk_group risk_grp.;
	cluster HOSP_NRD;
	strata NRD_STRATUM;
	weight DISCWT;
	ods output crosstabs = te_rate_overall;
run;

data te_rate_overall;
	length interval $ 10;
	set te_rate_overall;
	if primary_outcome = 1 then interval = 'All';
		else if fu_01_30 = 1 then interval = '1-30 days';
		else if fu_31_60 = 1 then interval = '31-60 days';
		else if fu_61_90 = 1 then interval = '61-90 days';
	if interval ne '';
	if risk_group ne '';
	drop table index_admit F_risk_group F_primary_outcome primary_outcome F_fu_01_30 fu_01_30 F_fu_31_60 fu_31_60 F_fu_61_90 fu_61_90 _SkipLine;
run;

proc sort data = te_rate_overall;
	by risk_group;
run;

proc transpose data = te_rate_overall out = te_rate_overall_pct prefix = pct;
	var RowPercent;
	by risk_group;
	id interval;
run;

proc transpose data = te_rate_overall out = te_rate_overall_ct prefix = ct;
	var WgtFreq;
	by risk_group;
	id interval;
run;

data te_rate_overall_merged;
	merge te_rate_overall_pct te_rate_overall_ct;
	by risk_group;
run;

ods exclude none;

ods document name = cvwoacr.te_incidence_rates(write);
title1 bold justify = left 'Table 2';
title2 justify = left 'TE Rate by Risk Group';
proc report data = te_rate_overall_merged;
	options missing = '';
	columns risk_group ctall pctall 'ct1-30 Days'n 'pct1-30 Days'n 'ct31-60 Days'n 'pct31-60 Days'n 'ct61-90 Days'n 'pct61-90 Days'n ;

	define risk_group / 'Risk Group' display format = risk_grp.;
	define ctall / 'Overall' display;
	define pctall / 'Overall' display;
	define 'ct1-30 Days'n / display;
	define 'pct1-30 Days'n / display;
	define 'ct31-60 Days'n / display;
	define 'pct31-60 Days'n / display;
	define 'ct61-90 Days'n / display;
	define 'pct61-90 Days'n / display;
run;
ods document close;

/*
*Risk specific to low-risk patients;
ods document name = cvwoacr.te_incidence_rates_low_risk(write);
title1 justify = left 'Table N';
title2 justify = left 'TE Rate In Low-Risk Group';
proc surveyfreq data = cvwoac.cv_analysis_set;
	table primary_outcome * CHADS2VASc / chisq row col;
 	strata NRD_STRATUM;
	cluster HOSP_NRD;
	weight discwt;
	where CHADS2VASc le 1;
run;
ods document close;
*/