*This program adjusted on Sept 13 to replace part1_for_paper.do
*and to use correct superbalanced sample defined in 1962-2013; 
*we suppress FTA bit of program (go back to part1_for_paper.do for that part)

*This file prepares graphs and recap table reported in part 1 of the paper

*****************************
***set directory and matsize
*****************************

clear all
set more off
set matsize 800
**at Mac laptop
*global dir "/Users/liza/Documents/LIZA_WORK/"
*cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015"


display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities"
	cd "$dir/Résultats/Première Partie"

}


if "`c(hostname)'" =="ECONCES1" {
*	global dir "/Users/liza/Documents/LIZA_WORK"
*	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015"
	global dir "Y:\ELAST_NONLIN"
	cd "$dir"
}

********************
***CONSTRUCT GRAPHS
********************
*graphs: report point estimates, confidence intervals, and geometric trend
*together with total percentage increase in coefficient and significance
**1.1**full and superbalanced sample: benchmark year 1962
capture program drop basic
program basic
*local 1 1962
use part1_ppml_full_nofta_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*se_lndist
gen double ci_full_low=estim_full-1.96*se_lndist
drop se_lndist
save basic, replace
use part1_ppml_`1'_nofta_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
**first graph: distance puzzle enhanced if we fix sample of trading partners (full-superbal)
use basic, clear
sort year
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef=ln(abs(estim_`s'))	
	reg ln_`s'_coef year, robust
	scalar define rate_`s'=_b[year]
	predict `s'
	replace `s'=-(exp(`s'))
*growth rate: 
*growth rate: 
*0.087% per year for full sample (sign. at 10%): 4.5% increase in coef (marg significant)
*0.33% per year for superbal sample (sign at 1%): 18.2% increase in coef (using 1965 increases growth rate to .47% per year)
	quietly graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
	*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
	*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s' sample") saving(`s')
}
quietly graph combine full.gph superbal.gph, ycommon xcommon title("The sample composition effect")
graph export "sample_composition_effect_`1'.eps", replace
erase full.gph 
erase superbal.gph 
erase basic.dta

*product composition: world bundle
use part1_ppml_full_nofta_`1'_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*se_lndist
gen double ci_full_low=estim_full-1.96*se_lndist
drop se_lndist
save basic, replace
use part1_ppml_`1'_nofta_`1'_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace

**second graph: distance puzzle enhanced if we fix composition of traded bundle at world level 
*very similar for full-superbal samples
use basic, clear
sort year
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef=ln(abs(estim_`s'))	
	reg ln_`s'_coef year, robust
	scalar define rate_`s'=_b[year]
	predict `s'
	replace `s'=-(exp(`s'))
*growth rate: 
*0.265% per year for full sample (sign. at 1%): 14.5% increase in coef 
*0.331% per year for superbal sample (sign at 1%): 18.4% increase in coef (using 1965 increases growth rate to .495% per year)
	quietly graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
	*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
	*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s' sample") saving(`s')
}
quietly graph combine full.gph superbal.gph, ycommon xcommon title("The product composition effect (world)")
graph export "product_composition_effect_world_`1'.eps", replace
erase full.gph 
erase superbal.gph 
erase basic.dta

*product composition: country bundle
use part1_ppml_full_nofta_current_`1', clear
keep coef_lndist se_lndist year
rename coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*se_lndist
gen double ci_full_low=estim_full-1.96*se_lndist
drop se_lndist
save basic, replace
use part1_ppml_`1'_nofta_current_`1', clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
**third graph: distance puzzle enhanced if we fix composition of traded bundle at country level
*results are most pronounced here (difference between full superbal sample secondary): product composition crucial
use basic, clear
sort year
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef=ln(abs(estim_`s'))	
	reg ln_`s'_coef year, robust
	scalar define rate_`s'=_b[year]
	predict `s'
	replace `s'=-(exp(`s'))
*growth rate: 
*0.40% per year for full sample (sign. at 1%): 22.7% increase in coef [explains 87% of tot variation]
*0.54% per year for superbal sample (sign at 1%): 31.4% increase in coef (using 1965 increases growth rate to .61% per year)
	graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
	*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
	*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s' sample") saving(`s')
}
graph combine full.gph superbal.gph, ycommon xcommon title("The product composition effect (country)")
graph export "product_composition_effect_country_`1'.eps", replace
erase full.gph 
erase superbal.gph 
erase basic.dta
clear
end

*RUN PROGRAM:
basic 1962
*variant for first year of instrumented data (1965-2013)
basic 1965

**NOTES:
*country bundle fixing enhances distance puzzle by more; sample effects matter more here
**non-linearity disappears: 86.6% of variation explained by the year trend (81% in superbal sample)
*shows shift to differentiated goods even for stable trading pairs (confirms B\&F)
*hence: product and country composition effects have all contributed to mute the distance puzzle

**************************
***FTA effect not updated: see previous version of file for FTA effects
***FIXED DISTANCE DISTRIBUTION not updated: see previous version of file for this part with/-out composition
**CORRECTED FTA effect not updated: see previous version of file for corr_FTA
**INTERPRETATION: 
**before 1990s fta effect is driven by selection into ftas; 
*since 1990s: fta effect is driven by intensification of within-fta trade: fta control reduces distance puzzle
**************************

**************************
***RECAP TABLE (NO FTA)***
**************************
*recap table: report implied annualized growth rate and pp change rel. baseline
*where baseline is increase in distcoef in full sample (geom.fit)
capture program drop recap
program recap
*local 1 1962
local 2=`1'-1900
use part1_ppml_full_nofta_current_current, clear
keep coef_lndist year
rename coef_lndist base_full
gen double ln_base=ln(abs(base_full))	
reg ln_base year, robust
predict pred_base_full
replace pred_base_full=-(exp(pred_base_full))
keep year pred_base_full
save basic_`1', replace
*stable sample baseline
use part1_ppml_`1'_nofta_current_current, clear
keep coef_lndist year
rename coef_lndist base`2'
gen double ln_base`2'=ln(abs(base`2'))	
reg ln_base`2' year, robust
predict pred_base`2'
replace pred_base`2'=-(exp(pred_base`2'))
keep year pred_base`2'
joinby year using basic_`1'
save basic_`1', replace

*full with world bundle
*local 1 1962
*local 2=`1'-1900
use part1_ppml_full_nofta_`1'_current, clear
keep coef_lndist year
rename coef_lndist base_full`2'
gen double ln_base`2'=ln(abs(base_full`2'))	
reg ln_base`2' year, robust
predict pred_base_full`2'
replace pred_base_full`2'=-(exp(pred_base_full`2'))
keep year pred_base_full`2'
joinby year using basic_`1'
save basic_`1', replace
*stable with world bundle
use part1_ppml_`1'_nofta_`1'_current, clear
keep coef_lndist year
rename coef_lndist base`2'`2'
gen double ln_base`2'`2'=ln(abs(base`2'`2'))	
reg ln_base`2'`2' year, robust
predict pred_base`2'`2'
replace pred_base`2'`2'=-(exp(pred_base`2'`2'))
keep year pred_base`2'`2'
joinby year using basic_`1'
save basic_`1', replace

*full with country bundle
*local 1 1962
*local 2=`1'-1900
use part1_ppml_full_nofta_current_`1', clear
keep coef_lndist year
rename coef_lndist base_fullc`2'
gen double ln_basec`2'=ln(abs(base_fullc`2'))	
reg ln_basec`2' year, robust
predict pred_base_fullc`2'
replace pred_base_fullc`2'=-(exp(pred_base_fullc`2'))
keep year pred_base_fullc`2'
joinby year using basic_`1'
save basic_`1', replace
*stable with country bundle
use part1_ppml_`1'_nofta_current_`1', clear
keep coef_lndist year
rename coef_lndist base`2'c`2'
gen double ln_base`2'c`2'=ln(abs(base`2'c`2'))	
reg ln_base`2'c`2' year, robust
predict pred_base`2'c`2'
replace pred_base`2'c`2'=-(exp(pred_base`2'c`2'))
keep year pred_base`2'c`2'
joinby year using basic_`1'
save basic_`1', replace

*full with naive FTA
*use part1_ppml_full_big_current_current, clear
*keep Coef_lndist year
*rename Coef_lndist base_fullfta
*gen double ln_basefta=ln(abs(base_fullfta))	
*reg ln_basefta year, robust
*predict pred_base_fullfta
*replace pred_base_fullfta=-(exp(pred_base_fullfta))
*keep year pred_base_fullfta
*joinby year using basic
*save basic, replace
*stable with naive FTA
*use part1_ppml_1963_big_current_current, clear
*keep coef_lndist year
*rename coef_lndist base63fta
*gen double ln_base63fta=ln(abs(base63fta))	
*reg ln_base63fta year, robust
*predict pred_base63fta
*replace pred_base63fta=-(exp(pred_base63fta))
*keep year pred_base63fta
*joinby year using basic
*save basic, replace
**for corr_fta: look into corr_fta.dta
clear
end

*RUN PROGRAM:
recap 1962
*variant for first year of instrumented elast (1965-2013):
recap 1965
