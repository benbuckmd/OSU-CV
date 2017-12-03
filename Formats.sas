proc format;
	value nrd_dispo_fmt
		1  =  'Routine'
		2	 =	'Transfer to short-term hospital'
		5	 =	'Transfer other: includes Skilled Nursing Facility (SNF), Intermediate Care Facility (ICF), and another type of facility'
		6	 =	'Home Health Care (HHC)'
		7	 =	'Against medical advice (AMA)'
		20 =	'Died in hospital'
		21 =	'Discharged/transferred to court/law enforcement'
		99 =	'Discharged alive, destination unknown, beginning in 2001'
		.	 = 	'Missing'
		.A =	'Invalid';
	value female_fmt
		1 = 'Female'
		0 = 'Male';
	value payer_fmt
		1	= 'Medicare'
		2	= 'Medicaid'
		3	= 'Private insurance'
		4	= 'Self-pay'
		5	= 'No charge'
		6	= 'Other'
		.	= 'Missing';
	picture round10th 
    low - high = '009.9)' (prefix = '(') ;
run;

/*Formats particular to this project*/
proc format;
	value $fu_t
		'30d' = 'Days 1-30'
		'60d' = 'Days 31-60'
		'90d' = 'Days 61-90';
	value risk_grp
		1 = 'Low Risk'
		2 = 'Intermediate Risk'
		3 = 'High Risk';
	run;