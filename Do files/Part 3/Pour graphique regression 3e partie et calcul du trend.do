*v3 Dec 2018 adjusted to run on each results file
 
** This file produces recap graph for sigma
** baseline (sitc)
** baci (hs4)
** instrumented (sitc)
** superbal (sitc)



****************************************
*set directory*
****************************************
clear all
*set mem 2g
*set matsize 800
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/2007 OFCE Substitution Elasticities local/"
	cd "$dir/Résultats/Troisième partie/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/"
	cd "$dir/Résultats/Troisième partie/"
}


capture log using "logs/`c(current_time)' `c(current_date)'"
****************************************************************************************************************************************************************

capture program drop pour_graph_regression_3e_partie
program pour_graph_regression_3e_partie
args sample


** baseline

use "Résultats 1ere regression 3e partie_`sample'.dta", clear

generate one_minus_sigma = 1-sigma_est


 generate double cl_elast=-exp(ln(sigma_est-1)-1.96*ecart_type_lnsigmaminus1)
 generate double cu_elast=-exp(ln(sigma_est-1)+1.96*ecart_type_lnsigmaminus1)
bys year : keep if _n==1


*preserve
*drop if year == 2008


foreach i of varlist one_minus_sigma { 
	drop if year==.
	quietly generate ln_`i' = ln(abs(`i'))
	regress ln_`i' year
	quietly predict ln_`i'_p
	quietly generate `i'_p= -exp(ln_`i'_p)
	quietly drop ln_`i'_p ln_`i'
	display  %9.2f  `i'_p[_N]/`i'_p[1] ": total change"
	display  %9.4f  _b[year] ": yearly change"
	local conf_int_low = _b[year]-1.96*_se[year]
	local conf_int_high = _b[year]+1.96*_se[year]
	display   "[" %9.4f `conf_int_low' ";"  %9.4f `conf_int_high' "]"
}



				
		
/*
twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(small)) /*
	*/ (lfit one_minus_sigma year), /*
	*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s1mono)
graph export graph7_without2008.eps, replace
*/
*restore

twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(vsmall)) /*
	*/ (lfit one_minus_sigma year), /*
	*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s1mono)
graph export "$dir/Git/trade_elasticities/Rédaction/tex/1ere regression 3e partie_`sample'.pdf", replace
graph export "1ere regression 3e partie_`sample'.pdf", replace


twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) ///
	(connected one_minus_sigma year, msize(vsmall)) ////
	 (lfit one_minus_sigma year), ///
	legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) ///
	scheme(s1mono) yscale(range(-1.5 0)) ylabel(-1.5 (0.3) 0)
graph export "1ere regression 3e partie_common_axis_`sample'.pdf", replace




*variant with same scale on all graphs:
/*
twoway   (rarea cl_elast cu_elast year, ylabel(-1.5(.5)0) fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(vsmall)) /*
	*/ (lfit one_minus_sigma year), /*
	*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s1mono)
graph export graph7_with2008.eps, replace
*/
graph dir
end

pour_graph_regression_3e_partie baseline
pour_graph_regression_3e_partie superbal
pour_graph_regression_3e_partie instrumented
pour_graph_regression_3e_partie prix_calc
pour_graph_regression_3e_partie Baci
