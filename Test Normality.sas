proc univariate data = cvwoac.cv_analysis_set normaltest;
	variable age;
run;
/*
%odsoff;
	%nl_test(var_type = NP, thing_n = 1, variable = age);
%odson;
*/