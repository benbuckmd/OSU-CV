proc import datafile="C:\CCS\dxlabel 2015.csv" 
	out=ccscode dbms=csv replace; 
	getnames=yes; 
run;

data ccsformat_data;
	set work.ccscode(rename = ('CCS DIAGNOSIS CATEGORIES'n = start 'CCS DIAGNOSIS CATEGORIES LABELS'n = label));
	retain fmtname 'ccsformat' type 'n';
run;

proc format cntlin = ccsformat_data; run;

proc datasets library = work;
	delete ccscode ccsformat_data;
run;