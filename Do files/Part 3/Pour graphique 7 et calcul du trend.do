*v3 Dec 2018 adjusted to run on each results file
 
** This file produces recap graph for sigma
** baseline (sitc)
** baci (hs4)
** instrumented (sitc)
** imputed (sitc)



****************************************
*set directory*
****************************************
clear all
*set mem 2g
*set matsize 800
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
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


** baseline

use "Résultats 1ere regression 3e partie.dta", clear


generate one_minus_sigma = 1-sigma_est


 generate double cl_elast=-exp(ln(sigma_est-1)-1.96*ecart_type_lnsigmaminus1)
 generate double cu_elast=-exp(ln(sigma_est-1)+1.96*ecart_type_lnsigmaminus1)
bys year : keep if _n==1


preserve
drop if year == 2008


foreach i of varlist one_minus_sigma { 
	quietly generate ln_`i' = ln(abs(`i'))
	regress ln_`i' year
	quietly predict ln_`i'_p
	quietly generate `i'_p= -exp(ln_`i'_p)
	quietly drop ln_`i'_p ln_`i'
	display "`i' : total change in baseline"
	display `i'_p[_N]/`i'_p[1]
}



				
		
twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(small)) /*
	*/ (lfit one_minus_sigma year), /*
	*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s2mono)
graph export graph7_without2008.eps, replace
restore

twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(vsmall)) /*
	*/ (lfit one_minus_sigma year), /*
	*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s2mono)
graph export graph7_with2008.eps, replace
graph dir

** baci

use "Résultats 1ere regression 3e partie_Baci.dta", clear


generate one_minus_sigma = 1-sigma_est


generate double cl_elast=-exp(ln(sigma_est-1)-1.96*ecart_type_lnsigmaminus1)
generate double cu_elast=-exp(ln(sigma_est-1)+1.96*ecart_type_lnsigmaminus1)
bys year : keep if _n==1


preserve
drop if year == 2011


foreach i of varlist one_minus_sigma { 
	quietly generate ln_`i' = ln(abs(`i'))
	regress ln_`i' year
	quietly predict ln_`i'_p
	quietly generate `i'_p= -exp(ln_`i'_p)
	quietly drop ln_`i'_p ln_`i'
	display "`i': total change in Baci"
	display `i'_p[_N]/`i'_p[1]
}

*total change in estimated parameter: +25.8% over 1995-2016
		
twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(small)) (lfit one_minus_sigma year), /*
*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s2mono)
graph export graph8_without2011.eps, replace
restore

twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(vsmall)) (lfit one_minus_sigma year), /*
*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s2mono)
graph export graph8_with2011.eps, replace
*graph dir
