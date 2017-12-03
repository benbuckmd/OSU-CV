data cv_analysis_set;
	DECLARE Hash fuall ();
  	rc = fuall.DefineKey("nrd_visitlink");
  	rc = fuall.DefineData("fu_01_30","fu_31_60","fu_61_90");
  	rc = fuall.DefineDone();
  	DO UNTIL (eof1); *set additional file;
   	  SET cvwoac.pts_rehospd end = eof1;
	  rc = fuall.add ();
  	END;
    DO UNTIL (eof2); *set base file;
      SET cvwoac.index_cv end = eof2;
	  	call missing(fu_01_30, fu_31_60, fu_61_90);
		  rc = fuall.find ();
		  OUTPUT;
    END;
    STOP;
run;

data cv_analysis_set;
	set cv_analysis_set cvwoac.hosp_set;
	if fu_01_30 = . then fu_01_30 = 0;
	if fu_31_60 = . then fu_31_60 = 0;
	if fu_61_90 = . then fu_61_90 = 0;

	if chads2vasc in (0, 1) then risk_group = 1;
		else if chads2vasc in (2, 3) then risk_group = 2;
		else if chads2vasc ge 4 then risk_group = 3;
run;

proc copy in = work out = cvwoac;
	select cv_analysis_set;
run;