goptions device=actximg;

ods excel file = "C:\Users\Benjamin\Documents\Okabe Research\Cardioversion without Anticoagulation\Tables.xlsx"
					style = Dove
					options(index='on'
									sheet_interval='Proc');

ods excel options(sheet_name="Table 1");
proc document name = cvwoacr.demographics;
	replay;
run;
quit;

/*ods excel options(sheet_name="Readmission Incidence");
proc document name = cvwoacr.te_incidence_rates;
	replay;
run;
quit;*/

ods excel options(sheet_name="RF ORs");
proc document name = cvwoacr.te_rf_or;
	replay;
run;
quit;



ods excel close;

/*
proc document name = cvwoacr.te_incidence_rates;
	replay;
	*list / levels=all; 
run;
quit;
*/