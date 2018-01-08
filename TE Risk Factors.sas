%macro logistic_helper(factor=, outcome=, suffix=);
	proc surveylogistic data = cvwoac.cv_analysis_set;
	model &outcome.(event  =  '1') = &factor.;
	strata NRD_STRATUM;
	cluster HOSP_NRD;
	domain index_admit;
	weight discwt;
	ods output OddsRatios = OR_&suffix. ParameterEstimates = param_&suffix.;
	run;
%mend logistic_helper;

%macro te_readm_rf(factor=);
ods document name = cvwoacr.te_rf_&factor.(write);
	%logistic_helper(factor=&factor., outcome=primary_outcome, suffix=all);
	%logistic_helper(factor=&factor., outcome=fu_01_30, suffix=30d);
	%logistic_helper(factor=&factor., outcome=fu_31_60, suffix=60d);
	%logistic_helper(factor=&factor., outcome=fu_61_90, suffix=90d);
ods document close;

data or_&factor._comb;
	set OR_all(in = inall) OR_30d(in = in30) OR_60d(in = in60) OR_90d(in = in90);
	if inall then t_in = 0;
		else if in30 then t_in = 30;
		else if in60 then t_in = 60;
		else if in90 then t_in = 90;
	if index_admit = 1;
run;

data param_&factor._comb;
	set param_all(in = inall) param_30d(in = in30) param_60d(in = in60) param_90d(in = in90);
	if inall then t_in = 0;
		else if in30 then t_in = 30;
		else if in60 then t_in = 60;
		else if in90 then t_in = 90;
	if variable ne 'Intercept';
	if index_admit = 1;
run;

data param_&factor.;
	merge or_&factor._comb param_&factor._comb;
	by t_in;
	drop domain variable index_admit;
run;

proc transpose data = param_&factor. out = param_&factor._or(drop = _name_ _label_) prefix = interval_;
	var OddsRatioEst;
	by effect;
	id t_in;
run;

proc transpose data = param_&factor. out = param_&factor._lcl(drop = _name_ _label_) prefix = lcl_;
	var lowercl;
	by effect;
	id t_in;
run;

proc transpose data = param_&factor. out = param_&factor._ucl(drop = _name_ _label_) prefix = ucl_;
	var UpperCL;
	by effect;
	id t_in;
run;

data effects_&factor.;
	length effect $ 10	interval_0  8 lcl_0  8 ucl_0   8
											interval_30 8 lcl_30 8 ucl_30  8
											interval_60 8 lcl_60 8 ucl_60  8
											interval_90 8 lcl_90 8 ucl_90  8;
	merge param_&factor._or param_&factor._lcl param_&factor._ucl;
	by Effect;
run;

data merged_te_rf; 
	set merged_te_rf effects_&factor.;
run;

proc datasets library = work;
	delete OR_all param_all param_&factor._comb	PARAM_FLAG_AGE	or_&factor._comb effects_&factor.
				 OR_30d param_30d param_&factor._or		PARAM_FLAG_CHF	
				 OR_60d param_60d param_&factor._lcl	PARAM_FLAG_DM		
				 OR_90d param_90d param_&factor._ucl	PARAM_FLAG_HTN	
																							PARAM_FLAG_SEX	
																							PARAM_FLAG_STRK	
																							PARAM_FLAG_VASC	;
run;
quit;

%mend te_readm_rf;

data merged_te_rf; 
	length effect $ 10	interval_0  8 lcl_0  8 ucl_0   8
											interval_30 8 lcl_30 8 ucl_30  8
											interval_60 8 lcl_60 8 ucl_60  8
											interval_90 8 lcl_90 8 ucl_90  8;
	stop;
run;

*Factor is risk factor for contribution to readmission for TE;
sasfile cvwoac.cv_analysis_set open; *not yet attempted to see if it speeds up;
%te_readm_rf(factor = flag_chf); *C;
%te_readm_rf(factor = flag_htn); *H;
%te_readm_rf(factor = flag_age); *A;
%te_readm_rf(factor = flag_dm); *D;
%te_readm_rf(factor = flag_strk); *S;
%te_readm_rf(factor = flag_vasc); *V;
%te_readm_rf(factor = flag_sex); *Sc;
%te_readm_rf(factor = flag_ckd);
sasfile cvwoac.cv_analysis_set close;

/*
proc document name = cvwoacr.te_rf_female;
	*replay;
	list / levels=all; 
run;
quit;
*/

/*
data merged_te_rf;
	set effects_FLAG_AGE effects_FLAG_CHF effects_FLAG_DM effects_FLAG_HTN effects_FLAG_SEX effects_FLAG_STRK effects_FLAG_VASC;
run;
*/

proc datasets lib = work; 
	delete effects_FLAG_AGE effects_FLAG_CHF effects_FLAG_DM effects_FLAG_HTN effects_FLAG_SEX effects_FLAG_STRK effects_FLAG_VASC;
run;
quit;

data merged_te_rf_table;
	set merged_te_rf;
	CI_0  = cats("(", put(lcl_0,  5.2), ",", put(ucl_0,  5.2), ")");
	CI_30 = cats("(", put(lcl_30, 5.2), ",", put(ucl_30, 5.2), ")");
	CI_60 = cats("(", put(lcl_60, 5.2), ",", put(ucl_60, 5.2), ")");
	CI_90 = cats("(", put(lcl_90, 5.2), ",", put(ucl_90, 5.2), ")");
	drop lcl_0 ucl_0 lcl_30 ucl_30 lcl_60 ucl_60 lcl_90 ucl_90;
run;

ods document name = cvwoacr.te_rf_or(write);
title1 justify = left 'Table 3';
title1 justify = left 'Risk Factors for TE';
proc report data = merged_te_rf_table;
	options missing = '';
	columns effect interval_0 CI_0 interval_30 CI_30 interval_60 CI_60 interval_90 CI_90;

	define effect / display;
	define interval_0 / display;
	define CI_0 / display;
	define interval_30 / display;
	define CI_30  / display;
	define interval_60 / display;
	define CI_60 / display;
	define interval_90 / display;
	define CI_90  / display;
run;
ods document close;

proc copy in = work out = cvwoac;
	select merged_te_rf;
run;

