data cv_analysis_set; *primary_outcome is new thing;
	DECLARE Hash fuall ();
  	rc = fuall.DefineKey("nrd_visitlink");
  	rc = fuall.DefineData("days_of_fu","primary_outcome","fu_01_30","fu_31_60","fu_61_90");
  	rc = fuall.DefineDone();
  	DO UNTIL (eof1); *set additional file;
   	  SET cvwoac.Pts_rehospd end = eof1;
	  rc = fuall.add ();
  	END;
    DO UNTIL (eof2); *set base file;
      SET cvwoac.index_cv end = eof2;
	  	call missing(days_of_fu, primary_outcome, fu_01_30, fu_31_60, fu_61_90);
		  rc = fuall.find ();
		  OUTPUT;
    END;
    STOP;
run;

data cv_analysis_set;
	set cv_analysis_set;

	dccvby09 = 0;
	dccvin10 = 0;
	dccvin11 = 0;

	if fu_01_30 = . and dmonth le 11 then fu_01_30 = 0;
	if fu_31_60 = . and dmonth le 10 then fu_31_60 = 0;
	if fu_61_90 = . and dmonth le  9 then fu_61_90 = 0;


	if chads2vasc in (0, 1) then risk_group = 1;
		else if chads2vasc in (2, 3) then risk_group = 2;
		else if chads2vasc ge 4 then risk_group = 3;

	if primary_outcome = . then primary_outcome = 0;

	if dmonth le 09 then dccvby09 = 1;
	if dmonth eq 10 then dccvin10 = 1;
	if dmonth eq 11 then dccvin11 = 1;
run;

proc copy in = work out = cvwoac;
	select cv_analysis_set;
run;

*Unweighted count of index admissions;
proc freq data = cvwoac.cv_analysis_set;
table fu_01_30 flag_strk;
run;