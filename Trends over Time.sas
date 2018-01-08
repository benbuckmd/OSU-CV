data analysis_set_long;
	set cvwoac.cv_analysis_set;
  array num (*) fu_01_30 fu_31_60 fu_61_90;
  length group $ 8;
  do i=1 to dim(num);
    measurement=num[i];
     call vname(num[i], group);
     output;
   end;
*drop x1 x2 x3 i;
run;

ods document name = cvwoacr.TrendOverTimeRisk(write);
title1 'Events Association with Time and Risk Group';
*ods output CrossTabs = ctf_30d;
proc surveyreg data=analysis_set_long;
	cluster HOSP_NRD;
	strata NRD_STRATUM;
	weight DISCWT;
	class group risk_group;
	model measurement = risk_group group / noint solution vadjust=none;
	contrast 'Ho: fu_01_30 = fu_31_60 = fu_61_90' group 1 0 -1, group 1 0 -1;*, group 1 0 -1;
	domain index_admit;
run;
ods trace off;
/*
data event_freqeuncy;
	set work.ctf(drop = Table index_admit f_risk_group);
	if risk_group ne .;
	if _skipline ne 1;
	if fu_01_30 or fu_31_60 or fu_61_90;
	
	if fu_01_30 = 1 then fu_pd = 30;
		else if fu_31_60 = 1 then fu_pd = 60;
		else if fu_61_90 = 1 then fu_pd = 90;

	drop _SkipLine F_fu_01_30 fu_01_30 F_fu_31_60 fu_31_60 F_fu_61_90 fu_61_90;

	lower = percent - stderr;
	upper = percent + stderr;
run;

proc sgplot data = event_freqeuncy noborder;
	scatter x = fu_pd y = percent / yerrorlower=lower                                                                                            
                          				yerrorupper=upper                                                                                            
                          				markerattrs=(color=blue symbol=CircleFilled);                                                                
	series x = fu_pd y = percent / group = risk_group
																 lineattrs=(color=blue pattern=2);                                                                             
	title1 'Plot Means with Standard Error Bars from Calculated Data';                                                                   
run;
*/
proc copy in = work out = cvwoac;
	select analysis_set_long;
run;

/*
proc datasets lib = work;
	delete ctfreq;
run;
*/

/*
proc sort data = cvwoac.cv_analysis_set out = temp_cv_analysis_set;
	by risk_group;
run;

proc surveyfreq data = temp_cv_analysis_set;
	table index_admit * fu_01_30 * fu_31_60 / chisq1; * fu_61_90 / chisq;
	format risk_group risk_grp.;
	cluster HOSP_NRD;
	strata NRD_STRATUM;
	weight DISCWT;
	by risk_group;
run;

proc ttest data = work.temp_cv_analysis_set;
	var fu_01_30 fu_31_60;
	by risk_group;
run;

proc surveymeans data = work.temp_cv_analysis_set;
	var fu_01_30  fu_31_60 fu_61_90;* / chisq1; *  / chisq;
	format risk_group risk_grp.;
	cluster HOSP_NRD;
	strata NRD_STRATUM;
	weight DISCWT;
	by risk_group;
	domain index_admit;
run;

proc freq data = work.temp_cv_analysis_set;
	table risk_group * (fu_01_30  fu_31_60 fu_61_90);
	weight discwt;
	where index_admit = 1;
run;

/*new try



proc freq data = work.sample2;
	table measurement;
	table group;
	table group * measurement;
run;

title1 'reg 1';
proc surveyreg data=sample2;
	cluster HOSP_NRD;
	strata NRD_STRATUM;
	weight DISCWT;
   class group risk_group;
   model measurement = risk_group group / noint solution vadjust=none;
   contrast 'Ho: fu_01_30 = fu_31_60 = fu_61_90' group 1 -1 -1;*, group 1 0 -1, group 0 1 -1;
run;



proc surveyreg data = work.temp_cv_analysis_set;
	/*var fu_01_30  fu_31_60 fu_61_90;* / chisq1; *  / chisq;
	format risk_group risk_grp.;*//*
	cluster HOSP_NRD;
	strata NRD_STRATUM;
	weight DISCWT;
	*by risk_group;
	domain index_admit;
run;
*/




