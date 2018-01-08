* Want to demonstrate decrease in TE rate over time;
* Restricted to patients with 90 days of f/u to avoid biasing the results;
data fu_events;
	set cvwoac.cv_analysis_set;
	if fu_01_30 = 1 then by_time = 30;
		else if fu_31_60 = 1 then by_time = 60;
		else if fu_61_90 = 1 then by_time = 90;
run;

proc surveyfreq data = work.fu_events;
	table primary_outcome * by_time / row wchisq;
	weight discwt;
	cluster HOSP_NRD;
	strata NRD_STRATUM;
run;

* Calculate CDF of events;
ods graphics on;
ods document name = cvwoacr.TE_timing(write);
proc univariate data = cvwoac.cv_analysis_set;
	var days_of_fu;
	cdf days_of_fu;
	freq discwt;
	ods output CDFPlot=ECDF_to_TE(rename = (ecdfx = days_of_fu ecdfy = cumulative_pct));
	where index_admit = 1 and dmonth le 9;
run;
ods graphics off;
ods document close;

proc surveyfreq data = cvwoac.cv_analysis_set;
	table days_of_fu;
	weight discwt; 
	cluster HOSP_NRD;
	ods output oneway = time_to_evt;
	strata NRD_STRATUM;
	where index_admit = 1 and dmonth le 9;
run;

proc sort data = ECDF_to_TE; by days_of_fu; run;
proc sort data = time_to_evt; by days_of_fu; run;

data aggregated_risks;
	merge ECDF_to_TE time_to_evt;
	by days_of_fu;
	drop VarName CDFPlot Table F_days_of_fu _skipline;
	if days_of_fu in (0:90);
run;

proc freq data = cvwoac.cv_analysis_set;
	table CHADS2VASc;
	weight discwt; 
	ods output OneWayFreqs = risk_score_n;
	where index_admit = 1 and dmonth le 9;
run;

* Experimental; 
/*
data friberg_te_risk;
input CHADS2VASc n isc_stk isc_stk_asa te te_asa;
datalines;
0 5343 0.2 0.2 0.3 0.3
1 6770 0.6 0.6 0.9 1.0
2 11 240 2.2 2.5 2.9 3.3
3 17 689 3.2 3.7 4.6 5.3
4 19 091 4.8 5.5 6.7 7.8
5 14 488 7.2 8.4 10.0 11.7
6 9577 9.7 11.4 13.6 15.9
7 4465 11.2 13.1 15.7 18.4
8 1559 10.8 12.6 15.2 17.9
9 268 12.23 14.4 17.4 20.3
;

data daily_risk;
merge risk_score_n friberg_te_risk(drop = n isc_stk_asa te_asa);
by CHADS2VASc;
risk_qd = te/36500;
est_evt = risk_qd * frequency;
run;

proc print data = daily_risk label sumlabel;
*by dummy;
var est_evt;
*where Org="Org1";
sum est_evt;
run;
*/

/* still experimental*/
proc sgplot data = aggregated_risks noborder;
	*scatter x = fu_pd y = percent / yerrorlower=lower                                                                                            
                          				yerrorupper=upper                                                                                            
                          				markerattrs=(color=blue symbol=CircleFilled);                                                                
	series x = days_of_fu y = frequency / /*group = risk_group*/
																 lineattrs=(color=blue pattern=2);
	reg x = days_of_fu y = frequency;
	pbspline x = days_of_fu y = frequency / NKNOTS= 200;

	*title1 'Plot Means with Standard Error Bars from Calculated Data';                                                                   
run;

/*
proc print data = aggregated_risks; run;

*proc document example;
proc document name = cvwoacr.EventsByRisk;
	replay;
	list / levels=all; 
run;
quit;
*/
