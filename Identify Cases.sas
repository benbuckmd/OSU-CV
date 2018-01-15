data index_cv;
	af_flag = 0;
	cv_flag = 0;
	cv_9961 = 0;
	cv_9962 = 0;
	cv_9969 = 0;
	index_admit = 1;
 	re_admit = 0;
	set nrdcore.core2014;

/*	Data Processing*/
	ARRAY dx dx1-dx25; 
    DO over dx;
			IF substr(dx,1,5) = '42731' THEN af_flag = 1;
		END;
	ARRAY pr pr1-pr15; 
		DO over pr;
			IF substr(pr,1,4) = '9961' or substr(pr,1,4) = '9962' or substr(pr,1,4) = '9969' 
				THEN cv_flag = 1;
			IF substr(pr,1,4) = '9961'
				THEN cv_9961 = 1; *Atrial cardioversion;
			IF substr(pr,1,4) = '9962'
				THEN cv_9962 = 1; *Other Countershock;
			IF substr(pr,1,4) = '9969'
				THEN cv_9969 = 1; *Other Conversion;
	END;

/*	Inclusion Criteria*/
	if cv_flag;
	if af_flag = 1;
	if dmonth LE 11;
	if age ge 18;
	
run;

proc sort data = index_cv;
	by nrd_visitlink;
run;

data index_cv;
	set index_cv;
	by nrd_visitlink;
	if first.nrd_visitlink;

	*initialize CHADS2VASC Score Variables;
	CHADS2VASc = 0;
	flag_chf = 0;
	flag_htn = 0;
	flag_age = 0;
	flag_dm = 0;
	flag_strk = 0;
	flag_vasc = 0;
	flag_sex = 0;	
	flag_ckd = 0;

	*identify other comorbidities;
	flag_ckd = 0;
	flag_smk = 0;

	*Calculate CHADS2VASC score and identifiy other comorbidities;
	array dx dx1-dx30; 
		do over dx;
			*CHADS2VASC score;
			if substr(dx,1,3) = '428' 
				or substr(dx,1,5) in ('39891') 
					then flag_chf	= 1;
			if substr(dx,1,3) in ('401', '402', '403', '404', '405') 
				then flag_htn	= 1;
			if substr(dx,1,3) = '250' or substr(dx,1,4) in ('3572', '3620') 
				or substr(dx,1,5) = '36641' 
					then flag_dm = 1;
			if substr(dx,1,3) in ('434', '435') 
				or substr(dx,1,5) in ('v1254') 
					then flag_strk = 2;
			if substr(dx,1,3) in ('410', '412', '413', '414', '433', '436', '437', '438', '440') 
				or substr(dx,1,4) in ('4471', '5570', '5571', '5579') 
					then flag_vasc = 1;
			*Identifiy other comorbidities;
			if substr(dx,1,4) = '3051' then flag_smk = 1;
			if substr(dx,1,3) = '585' then flag_ckd = 1;
		end;
	if age GE 65 and age < 75 then flag_age	= 1;
	 	else if age GE 75 then flag_age	= 2;
	if female = 1 then flag_sex	= 1;
	CHADS2VASc = flag_chf + flag_htn + flag_age + flag_dm + flag_strk + flag_vasc + flag_sex;
run;

data hosp_set;
	set nrdcore.core2014;
	by hosp_nrd;
	if first.hosp_nrd;
	index_admit = 0;
	re_admit = 0;
run;

proc copy in = work out = cvwoac;
	select index_cv hosp_set;
run;

/*
proc freq data = index_cv;
	table CHADS2VASc;
	weight discwt;
run;
*/
