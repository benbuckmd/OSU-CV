%let time_day = %sysfunc(date(),yymmddn8.) %sysfunc(time(),hour6.3);
goptions device = actximg;

data bkd;
	set cvwoac.cv_analysis_set;

	*initialize variables;
	dccvby09 = 0;
	dccvby10 = 0;
	dccvby11 = 0;
	risk_group = 0;

	if dmonth le 09 then dccvby09 = 1;
	if dmonth le 10 then dccvby10 = 1;
	if dmonth le 11 then dccvby11 = 1;

run;

ods document name = cvwoacr.dccv_timing(write);
proc tabulate data = work.bkd;
	class dccvby09 dccvby10 dccvby11;
	table dccvby09 dccvby10 dccvby11, n;
	freq discwt;
run;
ods document close;

title1 'Table 1';
ods document name = cvwoacr.demographics(write);
proc tabulate data = work.bkd;
	class DISPUNIFORM risk_group female PAY1 flag_chf flag_smk flag_dm flag_htn flag_smk flag_strk flag_vasc;
	var AGE ;
	table DISPUNIFORM female PAY1 flag_smk flag_chf flag_dm flag_htn flag_strk flag_vasc,
				risk_group * (n colpctn*f=round10th.) / nocellmerge;
	table AGE, risk_group * (median q1 q3);
	format DISPUNIFORM nrd_dispo_fmt. female female_fmt. PAY1 payer_fmt. risk_group risk_grp.;
	freq DISCWT;
	where index_admit = 1;
run;
ods document close;

/*
ods excel file = "C:\Users\Benjamin\Documents\Okabe Research\Cardioversion without Anticoagulation\Demographics &time_day..xlsx"
					style = Dove
					options(index='on'
									sheet_interval='none');

ods excel options(sheet_name = 'Demographics');


ods excel close;
*/