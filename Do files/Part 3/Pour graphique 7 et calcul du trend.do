/* v1 GD October 24, 2011
New programming

This file uses the trade This file uses "prep(ar)_`type'_`year'.dta files  where `type' is "full", "sq_list1962", "sqrecip_list" to compute "straight" market share.

It then uses relative prices to compute the elasticity of ms to relative prices. First version without changing the sample
*/


*v2 GD 19/01/2013
*On va essayer de rajouter les variables de gravité classiques à l'estimation


****************************************
*set directory*
****************************************
clear all
set mem 2g
set matsize 800
set more off
*on my laptop:
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*cd "$dir\SITC_Rev1_adv_query_2011"

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
	cd "$dir/Data_Interm/Third_Part/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}


capture log using "logs/`c(current_time)' `c(current_date)'"
****************************************************************************************************************************************************************




use "/Users/guillaumedaudin/Documents/Recherche/OFCE Substitution Elasticities/Résultats/Troisième partie/Résultats 1ere regression 3e partie.dta"


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
	display "`i'"
	display `i'_p[_N]/`i'_p[1]
}



				
		
twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(small)) (lfit one_minus_sigma year), /*
*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s2mono)
graph export graph7_without2008.eps, replace
restore
twoway   (rarea cl_elast cu_elast year, fintensity(inten20) lpattern(dot) lwidth(thin)) (connected one_minus_sigma year, msize(vsmall)) (lfit one_minus_sigma year), /*
*/ legend(order (1 3) label(1 "confidence interval" ) label( 3 "geometric fit")) scheme(s2mono)
graph export graph7_with2008.eps, replace
graph dir
