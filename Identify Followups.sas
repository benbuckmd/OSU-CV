proc sql noprint;
	create table fu_post_cv as
  select *
  from nrdcore.core2014
  	where nrd_visitlink in (select distinct nrd_visitlink from cvwoac.index_cv);
quit;

data index_cv_and_date;
	set cvwoac.index_cv(keep = nrd_visitlink nrd_daystoevent);
	rename NRD_DaysToEvent = index_days;
run;

data fu_post_cv;
	DECLARE Hash fucvs ();
  	rc = fucvs.DefineKey("nrd_visitlink", "cv_9961", "cv_9962");
  	rc = fucvs.DefineData("index_days");
  	rc = fucvs.DefineDone();
  	DO UNTIL (eof1); *set additional file;
   	  SET index_cv_and_date end = eof1;
	  rc = fucvs.add ();
  	END;
    DO UNTIL (eof2); *set base file;
      SET fu_post_cv end = eof2;
	  	call missing(index_days, cv_9961, cv_9962);
		  rc = fucvs.find ();
		  OUTPUT;
    END;
    STOP;
run;

data fu_post_cv;
	set fu_post_cv;
	index_admit = 0;

	*Initialize variables for outcomes;
	arterial_embolism = 0;
	precerebral_dz = 0;
	cerebral_dz = 0;
	isch_cerebral_dz = 0;
	tia = 0;
	primary_outcome = 0;
	primary_outcome_r = 0;
	primary_outcome_stroke = 0;
	stroke_any_dx = 0;
	readmit_days_01_30 = 0;
	readmit_days_31_60 = 0;
	readmit_days_61_90 = 0;
	event_flag_01_30 = 0;
	event_flag_31_60 = 0;
	event_flag_61_90 = 0;
	primary_stk_readm = 0;
	drg_flag = 0;

	if nrd_daystoevent > index_days;
	days_of_fu = nrd_daystoevent - index_days;
	if days_of_fu le 90;

	*Outcome by ICD codes;
	array dx dx1-dx30; 
		do over dx;
			if substr(dx,1,3) = '433' then precerebral_dz = 1;
			if substr(dx,1,3) = '434' then cerebral_dz = 1;
			if substr(dx,1,4) = '4371' then isch_cerebral_dz = 1;
			if substr(dx,1,3) = '435' then tia = 1;
			if substr(dx,1,3) = '444' then arterial_embolism = 1;
		end;

	stroke_any_dx = max(precerebral_dz, cerebral_dz, isch_cerebral_dz, tia, arterial_embolism);

 	if substr(dx1,1,3) = '433' then primary_stk_readm = 1;
		else if substr(dx1,1,3) = '434' then primary_stk_readm = 1;
		else if substr(dx1,1,4) = '4371' then primary_stk_readm = 1;
		else if substr(dx1,1,4) = '4359' then primary_stk_readm = 1;
		else if substr(dx1,1,3) = '444' then primary_stk_readm = 1;

	*Outcome by CCS codes;
	if dxccs1 in (109, 110, 111, 112, 116) then primary_outcome_r = 1;
	if dxccs1 = 109 then primary_outcome_stroke = 1;

	*Outcomes by DRG Code;
	if drg in (61:72) then drg_flag = 1;

	*Indicate patients of interest;
	primary_outcome = max(primary_stk_readm, drg_flag);

	if days_of_fu in (01:30) then do;
			readmit_days_01_30 = 1;
			event_flag_01_30 = primary_outcome;
		end;
		else if days_of_fu in (31:60) then do;
				readmit_days_31_60 = 1;
				event_flag_31_60 = primary_outcome;
			end;
		else if days_of_fu in (61:90) then do;
				readmit_days_61_90 = 1;
				event_flag_61_90 = primary_outcome;
			end;
run;

proc sort data = work.fu_post_cv;
	by NRD_VisitLink;
run;

data pts_rehospd;
	set work.fu_post_cv;
	by NRD_VisitLink;
	retain days_of_fu fu_01_30 fu_31_60 fu_61_90; *days is new thing;
	if first.NRD_VisitLink then do;
		fu_01_30 = event_flag_01_30;
		fu_31_60 = event_flag_31_60;
		fu_61_90 = event_flag_61_90;
	end;
	fu_01_30 = max(fu_01_30, event_flag_01_30);
	fu_31_60 = max(fu_31_60, event_flag_31_60);
	fu_61_90 = max(fu_61_90, event_flag_61_90);
	if last.NRD_VisitLink and sum(fu_01_30, fu_31_60, fu_61_90) ge 1 then output;

	keep NRD_VisitLink days_of_fu fu_01_30 fu_31_60 fu_61_90 primary_outcome;
/*	if sum(fu_01_30, fu_31_60, fu_61_90) ge 1;*/
run;

proc copy in = work out = cvwoac;
	select fu_post_cv pts_rehospd;
run;

proc datasets lib = work;
	delete index_cv_and_date;
run;
quit;
