****	Install both packages	****
findit ivreg210
ssc install xtivreg2, replace
* Reference: https://ideas.repec.org/c/boc/bocode/s456501.html
help xtivreg2
help xtivreg

////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////
set scheme s1color

clear all

*** Global directories, Thor ***
cd 				"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\stata"
global figures	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\03_figures"
global tables	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\04_tables"

*** Global directories, Cathrine ***
cd 				"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\stata"
global figures	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\03_figures"
global tables	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\04_tables"


////////////////////////////////////////////////////////////////////////////////
////////	1. Load and set up the time-series data						////////
////////////////////////////////////////////////////////////////////////////////
use "data_stata", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced

*xtdescribe


////////////////////////////////////////////////////////////////////////////////
////	2. Regressions for Wholesale		 								////
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
**** 	Preferred specifications											****
********************************************************************************
est clear
xtivreg e_w (p = wp wp_other) n_w trend temp* daytime ///
	o0.day_bd#i.hour i.week i.month i.year ///
	if bd==1 & inrange(hour,12,15), fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store peak, title("Peak: 12-15")

estout _all using "ws_preferred.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )

estout _all using $tables/ws_preferred.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Calendar dummies=*.*") drop(_cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(3 %9.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

* how to show estimation method and instruments? (first stage)

********************************************************************************
**** 	Elasticity for each hour (business days and non-business days)		****
********************************************************************************
est clear
foreach h of numlist 0/23 {
	xtivreg e_w (p = wp wp_other) n_w trend temp* daytime ///
		o0.day_bd i.week i.month i.year ///
		if bd==1 & hour==`h', fe vce(cluster grid)
	est store bd_h_`h'
}
foreach h of numlist 0/23 {
	xtivreg e_w (p = wp wp_other) n_w trend temp* daytime ///
		i.day i.week i.month i.year ///
		if non_bd==1 & hour==`h', fe vce(cluster grid)
	est store nbd_h_`h'
}
estout _all using "ws_each_hour.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )


********************************************************************************
**** 	Elasticity for each single hour-day combination						****
********************************************************************************
est clear
foreach d of numlist 1/5 {
	foreach h of numlist 0/23 {
		xtivreg e_w (p = wp wp_other) n_w trend temp* daytime ///
			i.week i.month i.year ///
			if day_bd==`d' & hour==`h', fe vce(cluster grid)
		est store bd_`d'_h_`h'
}
}
estout _all using "ws_hour-day-combinations.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )


////////////////////////////////////////////////////////////////////////////////
////	3. Regressions for households and small companies		 			////
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
**** 	Preferred specifications											****
********************************************************************************
est clear
xtivreg e_hh s_tout (p = wp wp_other) n_f n_r trend temp* daytime ///
	o0.day_bd#i.hour i.week i.month i.year ///
	if bd==1, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store bd, title("Business days")

xtivreg e_hh s_tout (p = wp wp_other) n_f n_r trend temp* daytime ///
	i.day#i.hour i.week i.month i.year ///
	if non_bd==1, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store nbd, title("Non-business days")

xtivreg e_hh s_tout (p = wp wp_other) n_f n_r trend temp* daytime ///
	o0.day_bd#i.hour o0.non_bd#i.hour i.week i.month i.year ///
	, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store all, title("All days")

xtivreg e_r s_tout (p = wp wp_other) n_r trend temp* daytime ///
	o0.day_bd#i.hour o0.non_bd#i.hour i.week i.month i.year ///
	, fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store residual, title("Residual only")

estout _all using "hh_preferred.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )

estout _all using $tables/hh_preferred.tex, style(tex) replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Calendar dummies=*.*") drop(_cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(3 %9.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")





	
	
	
	
	



*****	BACK TO WHOLESALE AGAIN!
********************************************************************************
**** 	Trying Differenct peak periods										****
********************************************************************************
est clear
foreach a of numlist 7/12 {
	foreach b of numlist 12/18 {
		xtivreg e_w (p = wp wp_other) n_w trend temp* daytime ///
			o0.day_bd#i.hour i.week i.month i.year ///
			if bd==1 & inrange(hour,`a',`b'), fe vce(cluster grid)
		est store bd_`a'_to_`b'
}
}
estout _all using "ws_peaks-comparison.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )


********************************************************************************
**** 	Trying Differenct shoulder periods									****
********************************************************************************
est clear
foreach a of numlist 7/12 {
	foreach b of numlist 12/18 {
		xtivreg e_w (p = wp wp_other) n_w trend temp* daytime ///
			o0.day_bd#i.hour i.week i.month i.year ///
			if bd==1 & inrange(hour,`a',`b'), fe vce(cluster grid)
		est store bd_`a'_to_`b'
}
}
estout _all using "ws_different-shoulders.xls", replace ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )

	
********************************************************************************
**** 	FE, RE, FEIV, REIV comparison										****
********************************************************************************
xtreg e_w p n_w days temp* dt i.h_* i.d_* i.week i.month i.year ///
	if bd==1 & inrange(hour,12,15), re vce(cluster grid)
estadd scalar cons = _b[_cons]
est store re, title("RE")

xtreg e_w p n_w days temp* dt i.hour_* i.week i.month i.year ///
	if bd==1 & inrange(hour,12,15), fe vce(cluster grid)
estadd scalar cons = _b[_cons]
est store fe, title("FE")

xtivreg e_w (p = wp wp_other) n_w days temp* dt i.h_* i.d_* i.week i.month i.year ///
	if bd==1 & inrange(hour,8,13), re vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store reiv, title("REIV")

xtivreg e_w (p = wp wp_other) n_w days temp* dt i.h_* d_* i.week i.month i.year ///
	if bd==1 & inrange(hour,8,13), fe vce(cluster grid) first
estadd scalar cons = _b[_cons]
est store feiv, title("FEIV")

estout re fe reiv feiv, ///
	label cells( b(star fmt(5)) se(par fmt(5)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(N, fmt(3 %9.0gc) )

	
	
	
	
estout re fe reiv feiv using "ws_fe-re-feiv-reiv-comparison.xls", replace ///
	label cells( b(star fmt(4))) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers)	
help estout

*** Export regression table to Latex ***
estout friday using "fe-re-comparison.tex", style(tex) replace ///
	label cells( b(star fmt(3)) se(par fmt(3)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Hour, month & year dummies=*.") ///
	drop(_cons) ///
	stats(cons N, labels("Constant" "Observations") fmt(3 %9.0gc) ) ///	
	posthead("\midrule") prefoot("\midrule") postfoot("\bottomrule")

	