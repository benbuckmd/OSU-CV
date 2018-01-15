%macro ODSOff(); /* Call prior to BY-group processing */
ods graphics off;
ods exclude all;
%mend;
 
%macro ODSOn(); /* Call after BY-group processing */
ods graphics on;
ods exclude none;
%mend;

ods exclude all;
proc datasets library = work;
	delete table_data;
run; quit;
ods exclude none;

data bkd; set cvwoac.cv_analysis_set; run;

options mprint;
%macro tablemaker(var_type = , thing_n=, variable=);
	%if &var_type. = categorical %then %do;
		ods output CrossTabs = ct_disp(drop = stddev percent stderr);
		ods output ChiSq = chi_disp;
		proc surveyfreq data = cvwoac.cv_analysis_set;
			table risk_group * &variable. / chisq row; 
			weight discwt; 
			where index_admit = 1;
		run;

		data chi_disp(rename = cvalue1 = pvalue);
			set chi_disp;
			if name1 = "P_RSF" then do;
				table_row = "&variable.";
				output;
			end;
			keep table_row cvalue1;
		run;

		proc sort data = ct_disp;
			by &variable.;
		run;

		proc transpose data = ct_disp out = ct_disp_count prefix = count;
			by &variable.;
			var wgtfreq;
			id f_risk_group;
		run;

		proc transpose data = ct_disp out = ct_disp_pct prefix = pct;
			by &variable.;
			var rowpercent;
			id f_risk_group;
		run;

		data ct_merged;
			length table_row $ 40 &variable. 8 count1 8 pct1 8 count2 8 pct2 8 count3 8 pct3 8;
			merge ct_disp_count(drop = _label_ _name_ countTotal) ct_disp_pct(drop = _label_ _name_ pctTotal);
			by &variable.;
			if &variable. = . then delete;
		run;

		data ct_merged; *in trial;
			DECLARE Hash fmtr ();
		  	rc = fmtr.DefineKey("&variable.");
		  	rc = fmtr.DefineData("table_row");
		  	rc = fmtr.DefineDone();
		  	DO UNTIL (eof1); *set additional file;
		   	  SET nrdfmt.&variable._set end = eof1;
			  rc = fmtr.add ();
		  	END;
		    DO UNTIL (eof2); *set base file;
		      SET ct_merged end = eof2;
			  	call missing(table_row);
				  rc = fmtr.find ();
				  OUTPUT;
		    END;
		    STOP;
		run;

		data ct_merged;
			length table_row $ 40 &variable. 8 count1 8 pct1 8 text1 $ 12 count2 8 pct2 8 text2 $ 12 count3 8 pct3 8 text3 $ 12 Pvalue $ 8;
			set chi_disp ct_merged;
			table_no = _n_;
			thing_no = &thing_n.;
			if table_row = "" then table_row = &variable.;
			drop &variable.;
			if pct1 ne . then text1 = "(" || put(pct1, 5.2) || ")";
			if pct2 ne . then text2 = "(" || put(pct2, 5.2) || ")";
			if pct3 ne . then text3 = "(" || put(pct3, 5.2) || ")";

			drop pct1 pct2 pct3 rc;
		run;

		*merge tables;
		proc append base = table_data data = ct_merged; run;

		*clean up;
		proc datasets library = work;
			delete chi_disp ct_disp ct_disp_count ct_disp_pct ct_merged;
		run;
		quit;
	%end;

	%if &var_type. = dichotomous %then %do;
		ods output CrossTabs = ct_disp(drop = stddev percent stderr);
		ods output ChiSq = chi_disp;
		proc surveyfreq data = cvwoac.cv_analysis_set;
			table risk_group * &variable. / chisq row; 
			weight discwt; 
			where index_admit = 1;
		run;

		data chi_disp(rename = cvalue1 = pvalue);
			set chi_disp;
			if name1 = "P_RSF" then do;
				
				output;
			end;
			keep table_row cvalue1;
		run;

		proc sort data = ct_disp;
			by &variable.;
		run;

		proc transpose data = ct_disp out = ct_disp_count prefix = count;
			by &variable.;
			var wgtfreq;
			id f_risk_group;
		run;

		proc transpose data = ct_disp out = ct_disp_pct prefix = pct;
			by &variable.;
			var rowpercent;
			id f_risk_group;
		run;

		data ct_merged;
			length table_row $ 40 &variable. 8 count1 8 pct1 8 count2 8 pct2 8 count3 8 pct3 8;
			merge ct_disp_count(drop = _label_ _name_ countTotal) ct_disp_pct(drop = _label_ _name_ pctTotal);
			by &variable.;
			if &variable. = . then delete;
			if &variable. = 0 then delete;
			table_row = "&variable.";
		run;

		data ct_merged;
			length table_row $ 40 &variable. 8 count1 8 pct1 8 text1 $ 12 count2 8 pct2 8 text2 $ 12 count3 8 pct3 8 text3 $ 12 Pvalue $ 8;
			merge chi_disp ct_merged;
			table_no = _n_;
			thing_no = &thing_n.;
			drop &variable.;
			if pct1 ne . then text1 = "(" || put(pct1, 5.2) || ")";
			if pct2 ne . then text2 = "(" || put(pct2, 5.2) || ")";
			if pct3 ne . then text3 = "(" || put(pct3, 5.2) || ")";

			drop pct1 pct2 pct3;
		run;

		*merge tables;
		proc append base = table_data data = ct_merged; run;

		*clean up;
		proc datasets library = work;
			delete chi_disp ct_disp ct_disp_count ct_disp_pct ct_merged;
		run;
		quit;
	%end;

	%if &var_type. = normal %then %do;
	*results;
	*stats;
		*merge tables;
		proc append base = table_data data = ct_merged; run;
	%end;

	%if &var_type. = NP %then %do;
		ods output KruskalWallisTest = kw_test(drop = nvalue1 label1);
		proc npar1way wilcoxon data = bkd;
		  class risk_group;
		  var &variable.;
		  *exact wilcoxon;
		  freq discwt;
		run;

		data kw_test;
		  set kw_test;
		  if name1 = "P_KW"; 
		  table_no = 1;
		run;

		ods output summary = &variable._quartiles;
		proc means data = bkd median q1 q3;
		  class risk_group;
		  var &variable.;
		  weight discwt;
		run;

		data &variable._quartiles;
		  set &variable._quartiles;
		  iqr = cats("(", put(&variable._q1, 5.1), "-", put(&variable._q3, 5.1), ")");
		  keep risk_group &variable._median iqr;
		run;

		proc transpose data = &variable._quartiles out = &variable._quartiles_iqr prefix = risk_group ;*label = risk_group;
		  var iqr;
		  id risk_group;
		run;

		proc transpose data = &variable._quartiles out = &variable._quartiles_median prefix = risk_group ;*label = risk_group;
		  var &variable._median;
		  id risk_group;
		run;

		data &variable._quartiles_iqr;
		  length table_row $ 40;
		  set &variable._quartiles_iqr(drop = _name_);
		  table_row = "&variable.";
		  rename risk_group1 = text1 risk_group2 = text2 risk_group3 = text3;
		run;

		data &variable._quartiles_median;
		  length table_row $ 40;
		  set &variable._quartiles_median(drop = _name_ _label_);
		  table_row = "&variable.";
		  rename risk_group1 = count1 risk_group2 = count2 risk_group3 = count3;  
		run;

		data kw_test;
		  length table_row $ 40;
		  set kw_test(rename = variable = table_row);
		  drop name1;
		  rename cvalue1 = Pvalue;
		  table_row = "&variable.";
		run;

		data &variable._data;
		  length Pvalue $ 8 text1 $ 12 text2 $12 text3 $ 12;
		  merge &variable._quartiles_iqr &variable._quartiles_median kw_test;
		  by table_row;
		  thing_no = &thing_n.;
		run;

    *merge tables;
    proc append base = table_data data = &variable._data; run;

		*clean up;
		proc datasets library = work;
			delete &variable._data &variable._quartiles &variable._quartiles_iqr &variable._quartiles_median kw_test;
		run;
		quit;
  %end;

	%if &var_type. = section %then %do;
	*section name;
	*others missing;
		*merge tables;
		proc append base = table_data data = ct_merged; run;
	%end;
%mend tablemaker;

*var_type identifies type of variable, choices are categorical, dichomatous, non-parametric, normal;
*thing_n orders table;
*variable determines variable tested;
%odsoff;
	%tablemaker(var_type = NP, thing_n = 1, variable = age);
	%tablemaker(var_type = dichotomous, thing_n = 2, variable = female);
	%tablemaker(var_type = dichotomous, thing_n = 3, variable = dccv_flag);
	%tablemaker(var_type = dichotomous, thing_n = 4, variable = flag_ckd);
%odson;
/*	%tablemaker(var_type = categorical, thing_n = 12, variable = pay1);
	%tablemaker(var_type = categorical, thing_n = 5, variable = dispuniform);
	%tablemaker(var_type = dichotomous, thing_n = 6, variable = flag_chf);
	%tablemaker(var_type = dichotomous, thing_n = 7, variable = flag_dm);
	%tablemaker(var_type = dichotomous, thing_n = 8, variable = flag_htn);
	%tablemaker(var_type = dichotomous, thing_n = 9, variable = flag_smk);
	*%tablemaker(var_type = dichotomous, thing_n = 9, variable = flag_strk);
	%tablemaker(var_type = dichotomous, thing_n = 10, variable = flag_vasc);
	%tablemaker(var_type = dichotomous, thing_n = 11, variable = flag_ckd);*/

data table_data;
	set table_data;
	row_no = _n_;
run;

ods document name = cvwoacr.demographics(write);
title1 bold justify = left 'Table 1';
title2 justify = left 'Characteristics of Study Population';
proc report data = table_data;
	options missing = '';
	columns table_row count1 text1 count2 text2 count3 text3 Pvalue table_no thing_no row_no /*label*/;

	define table_row / display 'Characteristic';
	define count1 / display 'Low Risk' format = 7.0;
	define text1 / display;
	define count2 / display 'Intermediate Risk' format = 7.0;
	define text2 / display;
	define count3 / display 'High Risk' format = 7.0;
	define text3 / display;
	define pvalue / display;
	define table_no / noprint; *the rub;
	define thing_no / noprint;
	define row_no / noprint order = data;

	/*compute label;
		if table_no = 1 then call define(_row_, "style", "style={font_weight=bold}");
	endcomp;*/
run;
ods document close;

/*Experimental*/ /*
proc freq data = cvwoac.cv_analysis_set;
table cv_9961 cv_9962 dccv_flag;
weight discwt;
run;
*/
/*
		ods output CrossTabs = ct_disp(drop = stddev percent stderr);
		ods output ChiSq = chi_disp;
		ods trace on;
		proc surveyreg data = cvwoac.cv_analysis_set;
			model age = risk_group;* = age /* &variable. *//*; 
			weight discwt; 
			where index_admit = 1;
			cluster HOSP_NRD;
			strata NRD_STRATUM;
		run;
		ods trace off;*/