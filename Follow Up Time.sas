title1 justify = left 't';
title2 justify = left 't';
title3 justify = left 't';

ods trace on;
proc freq data = cvwoac.cv_analysis_set;
	table dmonth;
	weight DISCWT;
	where index_admit = 1;
	ods output onewayfreqs = fufreqs;
run;
ods trace off;

data fufreqs;
	set fufreqs;
	if dmonth le 09 then days_cont = 90; * frequency;
	if dmonth eq 10 then days_cont = 60; * frequency;
	if dmonth eq 11 then days_cont = 30; * frequency;
run;


/* old way of doing it
*determine follow-up interval;
ods document name = cvwoacr.fu_duration(write);
proc surveyfreq data = cvwoac.cv_analysis_set;
	table index_admit * (dccvby09 dccvin10 dccvin11);
	weight discwt;
run;
ods document close;
*/
