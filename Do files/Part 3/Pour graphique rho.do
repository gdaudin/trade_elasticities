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
	global dirgit "~/Documents/Recherche/2007 OFCE Substitution Elasticities local/Git/"
*	cd "$dir/Résultats/Troisième partie/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/"
	global dirgit "/Users/liza/Documents/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/"
	cd "$dir/Résultats/Troisième partie/"
}


capture log using "logs/`c(current_time)' `c(current_date)'"
****************************************************************************************************************************************************************

capture program drop pour_graph_rho
program pour_graph_rho
args sample

if "`sample'"=="baseline" local sample1 full 
if "`sample'"=="instrumented" local sample1 full 
if "`sample'"=="superbal" local sample1 1962


use "$dir/Résultats/Première partie/part1_ppml_`sample1'_nofta_current_current", clear
keep coef_lndist se_lndist year
rename coef_lndist estim_delta
gen double ci_delta_high=estim_delta+1.96*se_lndist
gen double ci_delta_low=estim_delta-1.96*se_lndist

merge 1:1 year using  "$dir/Résultats/Troisième partie/Résultats 1ere regression 3e partie_`sample'.dta"
drop if converge==0

set seed 1335

postfile buffer rho_hat sd_hat year using MonteCarloEstimatesRho_`sample'.dta, replace
sort year
local startyear 1962
if  "`sample'"=="superbal" local startyear 1963

forvalue year = 1962/2013 {
	preserve
	keep if year==`year'
	expand 100000
	generate rho =rnormal(estim_delta,se_lndist)/(1-rnormal(sigma_est,ecart_type_lnsigmaminus1))
	summarize rho
	post buffer (r(mean)) (r(sd)) (`year')
	restore
}
postclose buffer
use MonteCarloEstimatesRho_`sample'.dta, clear

gen double ci_delta_high = rho_hat+1.96*sd_hat
gen double ci_delta_low  = rho_hat-1.96*sd_hat

display "******Sample `sample' -- The following years are droped from the graph because the sd is >=1"
tab year if sd_hat>=1
drop if  sd_hat>=1


foreach i of varlist rho_hat { 
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





twoway   (rarea ci_delta_high ci_delta_low year, fintensity(inten20) lpattern(dot) lwidth(thin)) ///
		 (connected rho_hat year, msize(vsmall)) ///
		 (lfit rho_hat year), ///
		 legend(order (1 3) label(1 "confidence interval" ) label( 3 "linear fit"))  ///
		 xscale(range(1962 2013)) xlabel(1965(10)2015) ///
		 title("`sample'") ///
		 name(graph_rho_`sample') ///
		 scheme(s1mono)
		 
graph export "graph_rho_`sample'.pdf", replace	 


twoway   (rarea ci_delta_high ci_delta_low year, fintensity(inten20) lpattern(dot) lwidth(thin)) ///
		 (connected rho_hat year, msize(vsmall)) ///
		 (lfit rho_hat year), ///
		 legend(order (1 3) label(1 "confidence interval" ) label( 3 "linear fit")) ///
		 yscale(range(-1 3)) ylabel(-1 (1) 3) ///
		 xscale(range(1962 2013)) xlabel(1965(10)2015) ///
		 title("`sample'") ///
		 name(graph_rho_coma_`sample') ///
		 scheme(s1mono)
		 
graph export "graph_rho_common_axis_`sample'.pdf", replace	 
		
		

graph dir
end

pour_graph_rho baseline
pour_graph_rho instrumented
pour_graph_rho superbal

graph combine  graph_rho_baseline graph_rho_instrumented graph_rho_superbal  ///
	,  ycommon scheme(s1mono)
	
graph export "graph_rho.pdf", replace
graph export "$dirgit/trade_elasticities/Rédaction/tex/graph_rho.pdf", replace	 
