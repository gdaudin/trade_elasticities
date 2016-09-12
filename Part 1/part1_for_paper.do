*This file replaced by part1_for_paper_short.do on Sept.12, 2016

*This file prepares graphs and recap table reported in part 1 of the paper
*****************************
***set directory and matsize
*****************************
clear all
set more off
set matsize 800
**at Dell laptop
*global dir "G:\LIZA_WORK"
*previously: "...\REVISION_nov_2013_data"
*cd "$dir\GUILLAUME_DAUDIN\REVISION_jan14_data"
**at Mac laptop
*cd "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/REVISION_jan14_data"
global dir "/Volumes/VERBATIM HD/LIZA_WORK"
cd "$dir/GUILLAUME_DAUDIN/REVISION_jan14_data"

*graphs: report point estimates, confidence intervals, and geometric trend
*together with total percentage increase in coefficient and significance
**1.1**full and superbalanced sample: benchmark year 1963
capture program drop basic
program basic
use part1_ppml_full_nofta_current_current, clear
keep Coef_lndist SE_lndist year
rename Coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*SE_lndist
gen double ci_full_low=estim_full-1.96*SE_lndist
drop SE_lndist
save basic, replace
use part1_ppml_`1'_nofta_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
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
*0.10% per year for full sample (sign. at 5%): 5% increase in coef 
*0.44% per year for superbal sample (sign at 1%): 22% increase in coef 
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
keep Coef_lndist SE_lndist year
rename Coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*SE_lndist
gen double ci_full_low=estim_full-1.96*SE_lndist
drop SE_lndist
save basic, replace
use part1_ppml_`1'_nofta_`1'_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use basic, clear
sort year
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef=ln(abs(estim_`s'))	
	quietly reg ln_`s'_coef year, robust
	scalar define rate_`s'=_b[year]
	predict `s'
	replace `s'=-(exp(`s'))
*growth rate: 
*0.29% per year for full sample (sign. at 1%): 14% increase in coef 
*0.44% per year for superbal sample (sign at 1%): 22.5% increase in coef 
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
*0.43% per year for full sample (sign. at 1%): 22% increase in coef [explains 89% of tot variation]
*0.64% per year for superbal sample (sign at 1%): 34% increase in coef 
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
basic 1963
basic 1970
**NOTES ON 1963 sample:
*country bundle fixing stronger and consistent b/c less sensitive to sample used: 
**non-linearity disappears in full sample: 89% of variation explained by the year trend
*shows shift to differentiated goods even for stable partners (confirms B\&F)
*hence characteristic of stable set: composition effects have muted the distance puzzle
*!*one way to check BW: reweigh with 2009 weights: if differentiated goods have become more
*differentiated, distance puzzle should be overturned with reweight in 2009
**NB: if 1970 is used for superbal and for country bundle, results muted
*full with bundle fixed to 1970: .15% growth rate (7% increase in coef)
*superbal with current bundle: .4% growth rate (19% increase in coef)
*superbal with bundle fixed to 1970: .3% growth rate(14% increase in coef)
 
**FTA effect:
*first graph: full (superbal) with/without composition (1963)
capture program drop fta
program fta
use part1_ppml_full_big_current_current, clear
keep Coef_lndist SE_lndist year
rename Coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*SE_lndist
gen double ci_full_low=estim_full-1.96*SE_lndist
drop SE_lndist
save basic, replace
use part1_ppml_1963_big_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
**add data on fta with country composition effect: 1963 country bundle
use part1_ppml_full_big_current_1963, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_full63
gen double ci_full63_high=estim_full63+1.96*se_lndist
gen double ci_full63_low=estim_full63-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use part1_ppml_1963_big_current_1963, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal63
gen double ci_superbal63_high=estim_superbal63+1.96*se_lndist
gen double ci_superbal63_low=estim_superbal63-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use basic, clear
sort year
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef=ln(abs(estim_`s'))	
	reg ln_`s'_coef year, robust
	scalar define rate_`s'=_b[year]
	predict `s'
	replace `s'=-(exp(`s'))
*growth rate (without composition effects): 
*-0.95% per year for full sample (sign. at 1%): 35% decrease in coef
*-1.9% per year for superbal sample (sign at 1%): 60% decrease in coef 
	if "`s'"=="full" {
		graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', current bundle") saving(`s')
	}
	else {
		graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.2) ytick(-.8(.2)-.2)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', current bundle") saving(`s')
	}
}
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef63=ln(abs(estim_`s'63))	
	reg ln_`s'_coef63 year, robust
	scalar define rate63_`s'=_b[year]
	predict `s'63
	replace `s'63=-(exp(`s'63))
*growth rate (with composition effects: world bundle): 
*-.54% per year for full sample (sign. at 1%): 22% decrease in coef
*-1.7% per year for superbal sample (sign at 1%): 55% decrease in coef
*growth rate (with composition effects: country bundle): 
*-.35% per year for full sample (sign. at 1%): 15% decrease in coef
*-1.4% per year for superbal sample (sign at 1%): 48% decrease in coef 
	if "`s'"=="full" {
		graph twoway (scatter estim_`s'63 ci_`s'63_high ci_`s'63_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash)  ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', '63 bundle") saving(`s'63)
	}
	else {
		graph twoway (scatter estim_`s'63 ci_`s'63_high ci_`s'63_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash)  ylabel(-.8(.1)-.2) ytick(-.8(.2)-.2)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', '63 bundle") saving(`s'63)
	}
}
graph combine full.gph full63.gph, ycommon xcommon title("FTA effect in full sample: current/fixed bundle")
graph export "fta_full_without_with_country_bundle_1963.eps", replace
graph combine superbal.gph superbal63.gph, ycommon xcommon title("FTA effect in stable sample: current/fixed bundle")
graph export "fta_superbal_without_with_country_bundle_1963.eps", replace
**composition effect reduces fta effect: b/c magnifies distance puzzle, in particular in full, slightly in superbal sample
**but with ftas evolution highly non-linear, in particular in superbal: fit has little meaning
**hence: push idea that distance distribution of trade out of ftas changes
erase full.gph 
erase superbal.gph 
erase full63.gph 
erase superbal63.gph
erase basic.dta
clear
end
fta
**puzzle muted if 1970 bundle/sample used, but fta effect similar in magnitude
capture program drop fta70
program fta70
use part1_ppml_full_big_current_current, clear
keep Coef_lndist SE_lndist year
rename Coef_lndist estim_full
gen double ci_full_high=estim_full+1.96*SE_lndist
gen double ci_full_low=estim_full-1.96*SE_lndist
drop SE_lndist
save basic, replace
use part1_ppml_1970_big_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal
gen double ci_superbal_high=estim_superbal+1.96*se_lndist
gen double ci_superbal_low=estim_superbal-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
**add data on fta with country composition effect: 1970 country bundle
use part1_ppml_full_big_current_1970, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_full70
gen double ci_full70_high=estim_full70+1.96*se_lndist
gen double ci_full70_low=estim_full70-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use part1_ppml_1970_big_current_1970, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_superbal70
gen double ci_superbal70_high=estim_superbal70+1.96*se_lndist
gen double ci_superbal70_low=estim_superbal70-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use basic, clear
sort year
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef=ln(abs(estim_`s'))	
	reg ln_`s'_coef year, robust
	scalar define rate_`s'=_b[year]
	predict `s'
	replace `s'=-(exp(`s'))
*growth rate (without composition effects): 
*-0.95% per year for full sample (sign. at 1%): 35% decrease in coef
*-1.74% per year for superbal sample (sign at 1%): 55% decrease in coef 
	if "`s'"=="full" {
		graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', current bundle") saving(`s')
	}
	else {
		graph twoway (scatter estim_`s' ci_`s'_high ci_`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash) ylabel(-.8(.1)-.2) ytick(-.8(.2)-.2)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', current bundle") saving(`s')
	}
}
local sample full superbal
foreach s of local sample {
	gen double ln_`s'_coef70=ln(abs(estim_`s'70))	
	reg ln_`s'_coef70 year, robust
	scalar define rate70_`s'=_b[year]
	predict `s'70
	replace `s'70=-(exp(`s'70))
*growth rate (with composition effects: country bundle): 
*-.77% per year for full sample (sign. at 1%): 30% decrease in coef
*-1.65% per year for superbal sample (sign at 1%): 54% decrease in coef 
	if "`s'"=="full" {
		graph twoway (scatter estim_`s'70 ci_`s'70_high ci_`s'70_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash)  ylabel(-.8(.1)-.4) ytick(-.8(.2)-.4)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', '70 bundle") saving(`s'70)
	}
	else {
		graph twoway (scatter estim_`s'70 ci_`s'70_high ci_`s'70_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
		*/ (line `s' year, lcolor(red) lpattern(dash)  ylabel(-.8(.1)-.2) ytick(-.8(.2)-.2)), legend(order(1 2 4) label(1 "coef_estim") /*
		*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("`s', '70 bundle") saving(`s'70)
	}
}
graph combine full.gph full70.gph, ycommon xcommon title("FTA effect in full sample: current/fixed bundle")
graph export "fta_full_without_with_country_bundle_1970.eps", replace
graph combine superbal.gph superbal70.gph, ycommon xcommon title("FTA effect in stable sample: current/fixed bundle")
graph export "fta_superbal_without_with_country_bundle_1970.eps", replace
**composition effect reduces fta effect in both cases, but less so for 1970-bundle
**distance puzzle `solved' by ftas in both cases, but with 1970 fixing less sensitive to product composition effects
*but with ftas evolution of distcoef is highly non-linear: fit has little meaning
**hence: push idea that distance distribution of trade out of ftas changes
erase full.gph 
erase superbal.gph 
erase full70.gph 
erase superbal70.gph
erase basic.dta
clear
end
fta
***ILLUSTRATIVE GRAPHS WITH FIXED DISTANCE DISTRIBUTION
**FIRST ILLUSTRATION: CURRENT PRODUCT BUNDLE
*baseline, baseline with fta, baseline with distfix, baseline with distfix and fta
capture program drop distfix
program distfix
use part1_ppml_full_nofta_distfix_baseline, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_nofta63
gen double ci_nofta63_high=estim_nofta63+1.96*se_lndist
gen double ci_nofta63_low=estim_nofta63-1.96*se_lndist
drop se_lndist
save basic, replace
use part1_ppml_full_nofta_distfix_1970, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_nofta70
gen double ci_nofta70_high=estim_nofta70+1.96*se_lndist
gen double ci_nofta70_low=estim_nofta70-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
**add data for full sample with distance fixing within/outside fta
use part1_ppml_full_big_distfix_baseline, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_fta63
gen double ci_fta63_high=estim_fta63+1.96*se_lndist
gen double ci_fta63_low=estim_fta63-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_1970, clear
keep coef_lndist se_lndist year
rename coef_lndist estim_fta70
gen double ci_fta70_high=estim_fta70+1.96*se_lndist
gen double ci_fta70_low=estim_fta70-1.96*se_lndist
drop se_lndist
joinby year using basic
save basic, replace
use basic, clear
sort year
local sample 63 70
foreach s of local sample {
	gen double ln_nofta`s'_coef=ln(abs(estim_nofta`s'))	
	reg ln_nofta`s'_coef year, robust
	scalar define rate_nofta`s'=_b[year]
	predict nofta`s'
	replace nofta`s'=-(exp(nofta`s'))
*growth rate (without fta and without composition effects): 
*.16% per year for distance fixing in 1963 (sign. at 1%): 8% increase in coef
*.14% per year for distance fixing in 1970 (sign at 1%): 7% increase in coef 
	graph twoway (scatter estim_nofta`s' ci_nofta`s'_high ci_nofta`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
	*/ (line nofta`s' year, lcolor(red) lpattern(dash)), legend(order(1 2 4) label(1 "coef_estim") /*
	*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("nofta`s', current bundle") saving(nofta`s')
}
local sample 63 70
foreach s of local sample {
	gen double ln_fta`s'_coef=ln(abs(estim_fta`s'))	
	reg ln_fta`s'_coef year, robust
	scalar define rate_fta`s'=_b[year]
	predict fta`s'
	replace fta`s'=-(exp(fta`s'))
*growth rate (without fta and without composition effects): 
*2.3% per year for distance fixing in 1963 (sign. at 1%): 190% increase in coef
*2.1% per year for distance fixing in 1970 (sign at 1%): 160% increase in coef 
	graph twoway (scatter estim_fta`s' ci_fta`s'_high ci_fta`s'_low year, msymbol(smcircle smcircle_hollow smcircle_hollow) mcolor(gs4 gs8 gs8)) /*
	*/ (line fta`s' year, lcolor(red) lpattern(dash)), legend(order(1 2 4) label(1 "coef_estim") /*
	*/ label(2 "conf_int") label(4 "geometric fit")) xtitle(year) ytitle(distance elasticity) title("fta`s', current bundle") saving(fta`s')
	
}
*graph combine nofta70.gph fta70.gph, ycommon xcommon title("Distance fixing in full sample: with/out FTAs")
*graph export "distfix70_full_current_bundle.eps", replace
erase nofta63.gph
erase nofta70.gph
erase fta63.gph
erase fta70.gph
erase basic.dta
clear
end
distfix
**recap graph for fta/distfix effect: graph point estimates for
*baseline/baseline fta/baseline distfix/baseline distfix fta
capture program drop illusgrph
program illusgrph
use part1_ppml_full_nofta_current_current, clear
keep Coef_lndist SE_lndist year
rename Coef_lndist coef_base
rename SE_lndist se_base
save tmp, replace
local sample baseline 1970
foreach s of local sample {
	use part1_ppml_full_nofta_distfix_`s', clear
	keep coef_lndist se_lndist year
	rename coef_lndist coef_distfix_`s'
	rename se_lndist se_distfix_`s'
	joinby year using tmp, unmatched(none)
	save tmp, replace
}
use part1_ppml_full_big_current_current, clear
keep Coef_lndist SE_lndist year
rename Coef_lndist coef_fta
rename SE_lndist se_fta
joinby year using tmp, unmatched(none)
save tmp, replace
local sample baseline 1970
foreach s of local sample {
	use part1_ppml_full_big_distfix_`s', clear
	keep coef_lndist se_lndist year
	rename coef_lndist coef_distfix_fta_`s'
	rename se_lndist se_distfix_fta_`s'
	joinby year using tmp, unmatched(none)
	save tmp, replace
}
**recap graph for 1963 baseline distfix (no obs for 2000-2009 with distfix-fta):
graph twoway scatter coef_base coef_distfix_baseline coef_fta coef_distfix_fta_baseline year, /*
*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
*/ legend(label(1 "baseline") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
graph export "dist_profile_ftas.eps", replace
*recap graph for 1970 baseline distfix:
graph twoway scatter coef_base coef_distfix_1970 coef_fta coef_distfix_fta_1970 year, /*
*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
*/ legend(label(1 "baseline") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
graph export "dist_profile_70_ftas.eps", replace
**recap graph imputing evolution for '70 when convergence pb in 63
graph twoway (scatter coef_base coef_distfix_baseline coef_fta coef_distfix_fta_baseline year, /*
*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red)) /*
*/ (scatter coef_distfix_fta_1970 year if year>1969, msymbol(smtriangle_hollow) mcolor(cranberry) msize(vsmall)), /*
*/ legend(holes(5) label(1 "baseline") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta") label(5 "distfix '70 with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_63_70.eps", replace

**same exercise with composition effect (country bundle: 63/70)
*full_countrybundle; full_countrybundle_fta; full_countrybundle_distfix; full_countrybundle_distfix_fta
capture program drop recap
program recap 
*baseline: full sample with fixed bundle
use part1_ppml_full_nofta_current_`1', clear
keep coef_lndist se_lndist year
rename coef_lndist coef_base
rename se_lndist se_base
gen double ln_base=ln(abs(coef_base))	
reg ln_base year, robust
scalar define rate_base`1'=_b[year]
predict geomfit_base
replace geomfit_base=-(exp(geomfit_base))
*annual growth rate '63: 0.42905% (0.14578% if 1970)
save tmp, replace
*same sample with ftas:
use part1_ppml_full_big_current_`1', clear
keep coef_lndist se_lndist year
rename coef_lndist coef_fta
rename se_lndist se_fta
gen double ln_fta=ln(abs(coef_fta))	
reg ln_fta year, robust
scalar define rate_fta`1'=_b[year]
predict geomfit_fta
replace geomfit_fta=-(exp(geomfit_fta))
*annual growth rate '63: -0.34925% (-0.77078% if 1970)
joinby year using tmp, unmatched(none)
save tmp, replace
*same sample without ftas and with distfix:
if `1'==1963 {
	use part1_ppml_full_nofta_distfix_baseline_c`1', clear
}
else {
	use part1_ppml_full_nofta_distfix_`1'_c`1', clear
}
keep coef_lndist se_lndist year
rename coef_lndist coef_distfix
rename se_lndist se_distfix
gen double ln_distfix=ln(abs(coef_distfix))	
reg ln_distfix year, robust
scalar define rate_distfix`1'=_b[year]
predict geomfit_distfix
replace geomfit_distfix=-(exp(geomfit_distfix))
*annual growth rate '63: .22294% (.08742% if 1970)
joinby year using tmp, unmatched(none)
save tmp, replace
if `1'==1963 {
	use part1_ppml_full_big_distfix_baseline_c`1', clear
}
else {
	use part1_ppml_full_big_distfix_`1'_c`1', clear
}
keep coef_lndist se_lndist year
rename coef_lndist coef_distfix_fta
rename se_lndist se_distfix_fta
gen double ln_distfix_fta=ln(abs(coef_distfix_fta))	
reg ln_distfix_fta year, robust
scalar define rate_distfix_fta`1'=_b[year]
predict geomfit_distfix_fta
replace geomfit_distfix_fta=-(exp(geomfit_distfix_fta))
*annual growth rate '63: 2.15259% (1.59882% if 1970)	
joinby year using tmp, unmatched(both)
drop _merge
save tmp, replace
if `1'==1963 {
	use part1_ppml_full_big_distfix_1970_c1970, clear	
	keep coef_lndist year
	rename coef_lndist coef_distfix_fta70
	joinby year using tmp, unmatched(both)
	drop _merge
	save tmp, replace
}
use tmp, clear
**recap graph for baseline (1963 for country bundle and distance fixing):
if `1'==1963 {
	graph twoway scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
	*/ legend(label(1 "baseline, bundle '63") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
	graph export "dist_profile_ftas_c1963.eps", replace
*same graph but including reweight for 1970 when convergence pb in 63
	graph twoway (scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red)) /*
	*/ (scatter coef_distfix_fta70 year if year>1969, msymbol(smtriangle_hollow) mcolor(cranberry) msize(vsmall)), /*
	*/ legend(holes(5) label(1 "baseline, bundle '63") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta") label(5 "distfix '70 with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
	graph export "dist_profile_ftas_c1963_70.eps", replace
}
*recap graph for 1970 (1970 for distance fixing and country bundle):
else {
	graph twoway scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
	*/ legend(label(1 "baseline, bundle '70") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
	graph export "dist_profile_70_ftas_c1970.eps", replace
}
clear
end
recap 1963
recap 1970
**REWEIGHT 63 or 70 has little incidence on results
*hence: use 63 except distfix with fta where growth rate taken with 1970 distfix/bundle

*SAME EXERCISE FOR STABLE SAMPLE
*base, distfix, base with fta, distfix with fta
capture program drop recap
program recap 
use part1_ppml_`1'_nofta_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist coef_base
rename se_lndist se_base
gen double ln_base=ln(abs(coef_base))	
reg ln_base year, robust
scalar define rate_base`1'=_b[year]
predict geomfit_base
replace geomfit_base=-(exp(geomfit_base))
*annual growth rate '63: 0.44187 (0.38594% for 1970) 
save tmp, replace
*same sample with ftas:
use part1_ppml_`1'_big_current_current, clear
keep coef_lndist se_lndist year
rename coef_lndist coef_fta
rename se_lndist se_fta
gen double ln_fta=ln(abs(coef_fta))	
reg ln_fta year, robust
scalar define rate_fta`1'=_b[year]
predict geomfit_fta
replace geomfit_fta=-(exp(geomfit_fta))
*annual growth rate '63: -1.98539% (-1.74186% if 1970)
joinby year using tmp, unmatched(none)
save tmp, replace
*same sample without ftas and with distfix:
if `1'==1963 {
	use part1_ppml_`1'_nofta_distfix_baseline_current, clear
}
else {
	use part1_ppml_`1'_nofta_distfix_`1'_current, clear
}
keep coef_lndist se_lndist year
rename coef_lndist coef_distfix
rename se_lndist se_distfix
gen double ln_distfix=ln(abs(coef_distfix))	
reg ln_distfix year, robust
scalar define rate_distfix`1'=_b[year]
predict geomfit_distfix
replace geomfit_distfix=-(exp(geomfit_distfix))
*annual growth rate '63: .49176% (.54771% if 1970)
joinby year using tmp, unmatched(none)
save tmp, replace
if `1'==1963 {
	use part1_ppml_`1'_big_distfix_baseline_current, clear
}
else {
	use part1_ppml_`1'_big_distfix_`1'_current, clear
}
keep coef_lndist se_lndist year
rename coef_lndist coef_distfix_fta
rename se_lndist se_distfix_fta
gen double ln_distfix_fta=ln(abs(coef_distfix_fta))	
reg ln_distfix_fta year, robust
scalar define rate_distfix_fta`1'=_b[year]
predict geomfit_distfix_fta
replace geomfit_distfix_fta=-(exp(geomfit_distfix_fta))
*annual growth rate '63: 1.90876% (2.91794% if 1970)	
joinby year using tmp, unmatched(both)
drop _merge
save tmp, replace
use tmp, clear
**recap graph for baseline (1963 for country bundle and distance fixing):
if `1'==1963 {
	graph twoway scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
	*/ legend(label(1 "baseline") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
	graph export "dist_profile_ftas_superbal63.eps", replace
}
*recap graph for 1970 (1970 for distance fixing and country bundle):
else {
	graph twoway scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
	*/ legend(label(1 "baseline") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
	graph export "dist_profile_70_ftas_superbal70.eps", replace
}
clear
end
recap 1963
recap 1970

**same exercise with composition effect (superbalanced sample)
**base country bundle, distfix country bundle, base country bundle fta, disfix country bundle fta
capture program drop recap
program recap 
use part1_ppml_`1'_nofta_current_`1', clear
keep coef_lndist se_lndist year
rename coef_lndist coef_base
rename se_lndist se_base
gen double ln_base=ln(abs(coef_base))	
reg ln_base year, robust
scalar define rate_base`1'=_b[year]
predict geomfit_base
replace geomfit_base=-(exp(geomfit_base))
*annual growth rate '63: 0.63631 (0.28756% for 1970) 
save tmp, replace
*same sample with ftas:
use part1_ppml_`1'_big_current_`1', clear
keep coef_lndist se_lndist year
rename coef_lndist coef_fta
rename se_lndist se_fta
gen double ln_fta=ln(abs(coef_fta))	
reg ln_fta year, robust
scalar define rate_fta`1'=_b[year]
predict geomfit_fta
replace geomfit_fta=-(exp(geomfit_fta))
*annual growth rate '63: -1.39286% (-1.65446% if 1970)
joinby year using tmp, unmatched(none)
save tmp, replace
*same sample without ftas and with distfix:
if `1'==1963 {
	use part1_ppml_`1'_nofta_distfix_baseline_c`1', clear
}
else {
	use part1_ppml_`1'_nofta_distfix_`1'_c`1', clear
}
keep coef_lndist se_lndist year
rename coef_lndist coef_distfix
rename se_lndist se_distfix
gen double ln_distfix=ln(abs(coef_distfix))	
reg ln_distfix year, robust
scalar define rate_distfix`1'=_b[year]
predict geomfit_distfix
replace geomfit_distfix=-(exp(geomfit_distfix))
*annual growth rate '63:.31391 % (.32511% if 1970)
joinby year using tmp, unmatched(none)
save tmp, replace
if `1'==1963 {
	use part1_ppml_`1'_big_distfix_baseline_c`1', clear
}
else {
	use part1_ppml_`1'_big_distfix_`1'_c`1', clear
}
keep coef_lndist se_lndist year
rename coef_lndist coef_distfix_fta
rename se_lndist se_distfix_fta
gen double ln_distfix_fta=ln(abs(coef_distfix_fta))	
reg ln_distfix_fta year, robust
scalar define rate_distfix_fta`1'=_b[year]
predict geomfit_distfix_fta
replace geomfit_distfix_fta=-(exp(geomfit_distfix_fta))
*annual growth rate '63: 2.11534% (2.83737% if 1970)	
joinby year using tmp, unmatched(both)
drop _merge
save tmp, replace
**no convergence problems for 1963: only 1999 not converged
use tmp, clear
**recap graph for baseline (1963 for country bundle and distance fixing):
if `1'==1963 {
	graph twoway scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
	*/ legend(label(1 "baseline, bundle '63") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
	graph export "dist_profile_ftas_superbal63_c63.eps", replace
}
*recap graph for 1970 (1970 for distance fixing and country bundle):
else {
	graph twoway scatter coef_base coef_distfix coef_fta coef_distfix_fta year, /*
	*/ msymbol(circle smdiamond circle_hollow smdiamond_hollow) mcolor(gs8 red gs4 red) /*
	*/ legend(label(1 "baseline, bundle '70") label(2 "distfix") label(3 "baseline with fta") label(4 "distfix with fta")) /*
	*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation") 
	graph export "dist_profile_70_ftas_superbal70_c70.eps", replace
}
clear
end
recap 1963
recap 1970

***FIRST TAKE AT CORRECTED FTA EFFECT: TIME-SERIES AND CROSS-SECTIONAL DIMENSIONS
*RATE OF CHANGE IN NAIVE FTA EFFECT CORRECTED FOR EXTENSIVE MARGIN 
**compute evolution of distance coefficient with corrected FTA effect
capture program drop corrfta1
program corrfta1
*get data on baseline, distfix63, fta, distfix63+fta, distfix70+fta
use part1_ppml_full_nofta_current_current, clear
keep Coef_lndist year
rename Coef_lndist base
save basic, replace
use part1_ppml_full_nofta_distfix_baseline, clear
keep coef_lndist year
rename coef_lndist base_distfix
joinby year using basic
save basic, replace
*add data for full sample with fta: without/with distance fixing
use part1_ppml_full_big_current_current, clear
keep Coef_lndist year
rename Coef_lndist base_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_baseline, clear
keep coef_lndist year
rename coef_lndist distfix63_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_1970, clear
keep coef_lndist year
rename coef_lndist distfix70_fta
joinby year using basic
save basic, replace
***use sample to correct naive FTA effect with extensive margin
use basic, clear
tsset year
local vars base distfix63 distfix70
foreach v of local vars {
	gen double lncoef_`v'_fta=ln(abs(`v'_fta))
	gen double rate_`v'_fta=D.lncoef_`v'_fta
}
*compute corrected rate of change in coef with fta
gen double rate_ftacorr=rate_base_fta+rate_distfix70_fta
*compute implied distance elasticity with corrected fta effect
global nbr=47
gen lncoef_corr_fta_ts=.
replace lncoef_corr_fta_ts=lncoef_base_fta in 1
foreach n of numlist 2(1)$nbr {
	replace lncoef_corr_fta_ts=L.lncoef_corr_fta_ts+rate_ftacorr in `n'
}
gen double coef_corr_fta_ts=-exp(lncoef_corr_fta_ts)
*compute growth rate in corrected sample: 1.15821% per year: 70\% increase in coef
reg lncoef_corr_fta_ts year, robust
**alternative in levels: correct fta_coef for coef_distfix_fta/coef_distfix_base
gen double coef_corr_fta_cs=base_fta*(distfix70_fta/base_distfix)
*compute growth rate of cross-sectional correction: .994% per year (57.6% growth in coef)
gen double lncoef_corr_fta_cs=ln(abs(coef_corr_fta_cs))
reg lncoef_corr_fta_cs year, robust
*recap graph: with coef corrige
graph twoway (scatter base base_distfix coef_corr_fta_cs year, /*
*/ msymbol(circle circle_hollow plus) mcolor(gs8 gs4 gs4)) /*	
*/ (scatter base_fta distfix70_fta year, msymbol(smdiamond smdiamond_hollow) mcolor(red red)), /*
*/ legend(order(1 4 2 5 3) label(1 "baseline") label(2 "distfix") label(3 "corrected fta") label(4 "naive fta") label(5 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_corr_full.eps", replace
keep lncoef_corr_fta_cs year
rename lncoef_corr_fta_cs lncoef_full_corrfta
save corr_fta, replace
clear
**same investigation with fixed composition of bundle:
use part1_ppml_full_nofta_current_1963, clear
keep coef_lndist year
rename coef_lndist base
save basic, replace
use part1_ppml_full_nofta_distfix_baseline_c1963, clear
keep coef_lndist year
rename coef_lndist base_distfix
joinby year using basic
save basic, replace
*add data for full sample with fta: without/with distance fixing
use part1_ppml_full_big_current_1963, clear
keep coef_lndist year
rename coef_lndist base_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_1970_c1970, clear
keep coef_lndist year
rename coef_lndist distfix70_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_baseline_c1963, clear
keep coef_lndist year
rename coef_lndist distfix63_fta
joinby year using basic, unmatched(both)
drop _merge
save basic, replace
***use sample to correct naive FTA effect with extensive margin
use basic, clear
tsset year
local vars base distfix63 distfix70
foreach v of local vars {
	gen double lncoef_`v'_fta=ln(abs(`v'_fta))
	gen double rate_`v'_fta=D.lncoef_`v'_fta
}
*compute corrected rate of change in coef with fta
gen double rate_ftacorr=rate_base_fta+rate_distfix70_fta
*compute implied distance elasticity with corrected fta effect
global nbr=47
gen lncoef_corr_fta_ts=.
replace lncoef_corr_fta_ts=lncoef_base_fta in 1
foreach n of numlist 2(1)$nbr {
	replace lncoef_corr_fta_ts=L.lncoef_corr_fta_ts+rate_ftacorr in `n'
}
gen double coef_corr_fta_ts=-exp(lncoef_corr_fta_ts)
*compute growth rate in corrected sample: 1.24957% per year: 70\% increase in coef
reg lncoef_corr_fta_ts year, robust
**alternative in levels: correct fta_coef for coef_distfix_fta/coef_distfix_base
gen double coef_corr_fta_cs=base_fta*(distfix70_fta/base_distfix)
*compute growth rate of cross-sectional correction: 1.02663% per year (60% growth in coef)
gen double lncoef_corr_fta_cs=ln(abs(coef_corr_fta_cs))
reg lncoef_corr_fta_cs year, robust
*recap graph: with coef corrige
graph twoway (scatter base base_distfix coef_corr_fta_cs year, /*
*/ msymbol(circle circle_hollow plus) mcolor(gs8 gs4 gs2)) /*	
*/ (scatter base_fta distfix70_fta year, msymbol(smdiamond smdiamond_hollow) mcolor(red red)), /*
*/ legend(order(1 4 2 5 3) label(1 "baseline, '63 bundle") label(2 "distfix") label(3 "corrected fta") label(4 "naive fta") label(5 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_corr_full_c1963.eps", replace
keep lncoef_corr_fta_cs year
rename lncoef_corr_fta_cs lncoef_full_corrfta63
joinby year using corr_fta
save corr_fta, replace
clear
end
corrfta1
**INTERPRETATION: 
*initial fta effect is driven by selection into ftas: before 1990s 
*since 1990s: intensification of within-fta trade: fta control reduces distance puzzle
***SECOND TAKE AT CORRECTED FTA EFFECT: TIME-SERIES DIMENSION
**COMPUTE CONTRIBUTION OF EXOG FTA EFFECT AND CORRECT BASELINE RATE OF CHANGE
**compute evolution of distance coefficient with corrected FTA effect
capture program drop corrfta2
program corrfta2
*get data on baseline, distfix63, fta, distfix63+fta, distfix70+fta
use part1_ppml_full_nofta_current_current, clear
keep Coef_lndist year
rename Coef_lndist base
save basic, replace
use part1_ppml_full_nofta_distfix_baseline, clear
keep coef_lndist year
rename coef_lndist base_distfix
joinby year using basic
save basic, replace
*add data for full sample with fta: without/with distance fixing
use part1_ppml_full_big_current_current, clear
keep Coef_lndist year
rename Coef_lndist base_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_baseline, clear
keep coef_lndist year
rename coef_lndist distfix63_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_1970, clear
keep coef_lndist year
rename coef_lndist distfix70_fta
joinby year using basic
save basic, replace
use basic, clear
tsset year
local vars base base_fta base_distfix distfix70_fta 
foreach v of local vars {
	gen double lncoef_`v'=ln(abs(`v'))
	gen double rate_`v'=D.lncoef_`v'
}
*compute naive fta effect: rate_base-rate_base_fta 
**if positive: ftas LOWER rate of growth of coef by X percentage points
gen double fta_naive=rate_base-rate_base_fta
*compute endog fta effect (selection): rate_distfix63_fta-rate_base_distfix 
**if positive: selection in/out fta sample POLLUTES naive fta effect 
gen double fta_endog=rate_distfix70_fta-rate_base_distfix
*compute exog fta effect (within-FTA trade intensity): naive-endog
**if positive: fta effect LOWERS rate of growth in distance coefficient
gen double fta_exog=fta_naive-fta_endog
*corrected rate of change: rate_base-rate_fta_exog
gen double rate_ftacorr=rate_base-fta_exog
*compute implied distance elasticity with corrected fta effect
global nbr=47
gen lncoef_corr_fta=.
replace lncoef_corr_fta=lncoef_base in 1
foreach n of numlist 2(1)$nbr {
	replace lncoef_corr_fta=L.lncoef_corr_fta+rate_ftacorr in `n'
}
gen double coef_corr_fta=-exp(lncoef_corr_fta)
*compute growth rate in corrected sample: .994% per year: swings
reg lncoef_corr_fta year, robust
*recap graph: with coef corrige
graph twoway (scatter base base_distfix coef_corr_fta year, /*
*/ msymbol(circle circle_hollow plus) mcolor(gs8 gs4 gs4)) /*	
*/ (scatter base_fta distfix70_fta year, msymbol(smdiamond smdiamond_hollow) mcolor(red red)), /*
*/ legend(order(1 4 2 5 3) label(1 "baseline") label(2 "distfix") label(3 "corrected fta") label(4 "naive fta") label(5 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_corr_full_exog.eps", replace
clear
**same investigation with fixed composition of bundle:
use part1_ppml_full_nofta_current_1963, clear
keep coef_lndist year
rename coef_lndist base
save basic, replace
use part1_ppml_full_nofta_distfix_baseline_c1963, clear
keep coef_lndist year
rename coef_lndist base_distfix
joinby year using basic
save basic, replace
*add data for full sample with fta: without/with distance fixing
use part1_ppml_full_big_current_1963, clear
keep coef_lndist year
rename coef_lndist base_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_1970_c1970, clear
keep coef_lndist year
rename coef_lndist distfix70_fta
joinby year using basic
save basic, replace
use part1_ppml_full_big_distfix_baseline_c1963, clear
keep coef_lndist year
rename coef_lndist distfix63_fta
joinby year using basic, unmatched(both)
drop _merge
save basic, replace
***use sample to correct naive FTA effect with extensive margin
use basic, clear
tsset year
local vars base base_fta base_distfix distfix70_fta 
foreach v of local vars {
	gen double lncoef_`v'=ln(abs(`v'))
	gen double rate_`v'=D.lncoef_`v'
}
*compute naive fta effect: rate_base-rate_base_fta 
**if positive: ftas LOWER rate of growth of coef by X percentage points
gen double fta_naive=rate_base-rate_base_fta
*compute endog fta effect (selection): rate_distfix63_fta-rate_base_distfix 
**if positive: selection in/out fta sample POLLUTES naive fta effect 
gen double fta_endog=rate_distfix70_fta-rate_base_distfix
*compute exog fta effect (within-FTA trade intensity): naive-endog
**if positive: fta effect LOWERS rate of growth in distance coefficient
gen double fta_exog=fta_naive-fta_endog
*corrected rate of change: rate_base-rate_fta_exog
gen double rate_ftacorr=rate_base-fta_exog
*compute implied distance elasticity with corrected fta effect
global nbr=47
gen lncoef_corr_fta=.
replace lncoef_corr_fta=lncoef_base in 1
foreach n of numlist 2(1)$nbr {
	replace lncoef_corr_fta=L.lncoef_corr_fta+rate_ftacorr in `n'
}
gen double coef_corr_fta=-exp(lncoef_corr_fta)
*compute growth rate in corrected sample: 1% per year (.0102663, sign. at 1%): 60% increase in coef
reg lncoef_corr_fta year, robust
*recap graph: with coef corrige
graph twoway (scatter base base_distfix coef_corr_fta year, /*
*/ msymbol(circle circle_hollow plus) mcolor(gs8 gs4 gs4)) /*	
*/ (scatter base_fta distfix70_fta year, msymbol(smdiamond smdiamond_hollow) mcolor(red red)), /*
*/ legend(order(1 4 2 5 3) label(1 "baseline, '63 bundle") label(2 "distfix") label(3 "corrected fta") label(4 "naive fta") label(5 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_corr_full_c1963_exog.eps", replace
clear
**same investigation with superbal sample
**trickier to fix distance profile here: no entry or exit in sample
*get data on superbal63, distfix63, fta, distfix63+fta
use part1_ppml_1963_nofta_current_current, clear
keep coef_lndist year
rename coef_lndist base
save basic, replace
use part1_ppml_1963_nofta_distfix_baseline_current, clear
keep coef_lndist year
rename coef_lndist base_distfix
joinby year using basic
save basic, replace
*add data for superbal sample with fta: without/with distance fixing
use part1_ppml_1963_big_current_current, clear
keep coef_lndist year
rename coef_lndist base_fta
joinby year using basic
save basic, replace
use part1_ppml_1963_big_distfix_baseline_current, clear
keep coef_lndist year
rename coef_lndist distfix63_fta
joinby year using basic
save basic, replace
***use sample to correct naive FTA effect with extensive margin
use basic, clear
tsset year
local vars base base_fta base_distfix distfix63_fta 
foreach v of local vars {
	gen double lncoef_`v'=ln(abs(`v'))
	gen double rate_`v'=D.lncoef_`v'
}
*compute naive fta effect: rate_base-rate_base_fta 
**if positive: ftas LOWER rate of growth of coef by X percentage points
gen double fta_naive=rate_base-rate_base_fta
*compute endog fta effect (selection): rate_distfix63_fta-rate_base_distfix 
**if positive: selection in/out fta sample POLLUTES naive fta effect 
gen double fta_endog=rate_distfix63_fta-rate_base_distfix
*compute exog fta effect (within-FTA trade intensity): naive-endog
**if positive: fta effect LOWERS rate of growth in distance coefficient
gen double fta_exog=fta_naive-fta_endog
*corrected rate of change: rate_base-rate_fta_exog
gen double rate_ftacorr=rate_base-fta_exog
*compute implied distance elasticity with corrected fta effect
global nbr=47
gen lncoef_corr_fta=.
replace lncoef_corr_fta=lncoef_base in 1
foreach n of numlist 2(1)$nbr {
	replace lncoef_corr_fta=L.lncoef_corr_fta+rate_ftacorr in `n'
}
gen double coef_corr_fta=-exp(lncoef_corr_fta)
*compute growth rate in corrected sample: -.56839% per year: swings: 1989-1997
reg lncoef_corr_fta year, robust
*reweigh in cross-section and compute growth rate: same
gen double coef_corr_fta_cs=base_fta*(distfix63_fta/base_distfix)
gen double ln_coefcorr_fta_cs=ln(abs(coef_corr_fta_cs))
reg ln_coefcorr_fta_cs year, robust
*recap graph: with coef corrige
graph twoway (scatter base base_distfix coef_corr_fta_cs year, /*
*/ msymbol(circle circle_hollow plus) mcolor(gs8 gs4 blue)) /*	
*/ (scatter base_fta distfix63_fta year, msymbol(smdiamond smdiamond_hollow) mcolor(red red)), /*
*/ legend(order(1 4 2 5 3) label(1 "baseline, stable '63") label(2 "distfix") label(3 "corrected fta") label(4 "naive fta") label(5 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_corr_superbal.eps", replace
keep ln_coefcorr_fta_cs year
rename ln_coefcorr_fta_cs lncoef_stable_corrfta
joinby year using corr_fta
save corr_fta, replace
clear
**same investigation with superbal sample and fixed bundle
*get data on superbal63, distfix63, fta, distfix63+fta
use part1_ppml_1963_nofta_current_1963, clear
keep coef_lndist year
rename coef_lndist base
save basic, replace
use part1_ppml_1963_nofta_distfix_baseline_c1963, clear
keep coef_lndist year
rename coef_lndist base_distfix
joinby year using basic
save basic, replace
*add data for superbal sample with fta: without/with distance fixing
use part1_ppml_1963_big_current_1963, clear
keep coef_lndist year
rename coef_lndist base_fta
joinby year using basic
save basic, replace
use part1_ppml_1963_big_distfix_baseline_c1963, clear
keep coef_lndist year
rename coef_lndist distfix63_fta
joinby year using basic
save basic, replace
***use sample to correct naive FTA effect with extensive margin
use basic, clear
tsset year
local vars base base_fta base_distfix distfix63_fta 
foreach v of local vars {
	gen double lncoef_`v'=ln(abs(`v')) 
	gen double rate_`v'=D.lncoef_`v' 
}
*compute naive fta effect: rate_base-rate_base_fta 
**if positive: ftas LOWER rate of growth of coef by X percentage points
gen double fta_naive=rate_base-rate_base_fta
*compute endog fta effect (selection): rate_distfix63_fta-rate_base_distfix 
**if positive: selection in/out fta sample POLLUTES naive fta effect 
gen double fta_endog=rate_distfix63_fta-rate_base_distfix 
*compute exog fta effect (within-FTA trade intensity): naive-endog
**if positive: fta effect LOWERS rate of growth in distance coefficient
gen double fta_exog=fta_naive-fta_endog
*corrected rate of change: rate_base-rate_fta_exog
gen double rate_ftacorr=rate_base-fta_exog
*compute implied distance elasticity with corrected fta effect
global nbr=47
gen lncoef_corr_fta=.
replace lncoef_corr_fta=lncoef_base in 1
foreach n of numlist 2(1)$nbr {
	replace lncoef_corr_fta=L.lncoef_corr_fta+rate_ftacorr in `n'
}
gen double coef_corr_fta=-exp(lncoef_corr_fta)
*compute growth rate in corrected sample: 1.83% per year between 1963-1998
reg lncoef_corr_fta year, robust
*growth rate for reweighting in cross-section: .4418% per year (sign. at 10%)
gen double coef_corr_fta_cs=base_fta*(distfix63_fta/base_distfix)
gen double ln_coefcorr_fta_cs=ln(abs(coef_corr_fta_cs))
reg ln_coefcorr_fta_cs year, robust
*recap graph: with coef corrige
graph twoway (scatter base base_distfix coef_corr_fta_cs year, /*
*/ msymbol(circle circle_hollow plus) mcolor(gs8 gs4 blue)) /*	
*/ (scatter base_fta distfix63_fta year, msymbol(smdiamond smdiamond_hollow) mcolor(red red)), /*
*/ legend(order(1 4 2 5 3) label(1 "superbal, bundle'63") label(2 "distfix") label(3 "corrected fta") label(4 "naive fta") label(5 "distfix with fta")) /*
*/ ytitle("distance elasticity") xtitle("year") title("The distance profile of trade and FTA formation")
graph export "dist_profile_ftas_corr_superbal_c1963.eps", replace
keep ln_coefcorr_fta_cs year
rename ln_coefcorr_fta_cs lncoef_stable_corrfta63
joinby year using corr_fta
save corr_fta, replace
clear
end
corrfta2
*IN PAPER: USE THE LEVEL EFFECT: FULL AND SUPERBAL SAMPLES
*simple reweighting: coef_fta*coef_distfix_fta/coef_distfix_base

*recap table: report implied annualized growth rate and pp change rel. baseline
*where baseline is increase in distcoef in full sample (geom.fit)
capture program drop recap
program recap
use part1_ppml_full_nofta_current_current, clear
keep Coef_lndist year
rename Coef_lndist base_full
gen double ln_base=ln(abs(base_full))	
reg ln_base year, robust
predict pred_base_full
replace pred_base_full=-(exp(pred_base_full))
keep year pred_base_full
save basic, replace
*stable sample baseline
use part1_ppml_1963_nofta_current_current, clear
keep coef_lndist year
rename coef_lndist base63
gen double ln_base63=ln(abs(base63))	
reg ln_base63 year, robust
predict pred_base63
replace pred_base63=-(exp(pred_base63))
keep year pred_base63
joinby year using basic
save basic, replace
*full with world bundle
use part1_ppml_full_nofta_1963_current, clear
keep Coef_lndist year
rename Coef_lndist base_full63
gen double ln_base63=ln(abs(base_full63))	
reg ln_base63 year, robust
predict pred_base_full63
replace pred_base_full63=-(exp(pred_base_full63))
keep year pred_base_full63
joinby year using basic
save basic, replace
*stable with world bundle
use part1_ppml_1963_nofta_1963_current, clear
keep coef_lndist year
rename coef_lndist base6363
gen double ln_base6363=ln(abs(base6363))	
reg ln_base6363 year, robust
predict pred_base6363
replace pred_base6363=-(exp(pred_base6363))
keep year pred_base6363
joinby year using basic
save basic, replace
*full with country bundle
use part1_ppml_full_nofta_current_1963, clear
keep coef_lndist year
rename coef_lndist base_fullc63
gen double ln_basec63=ln(abs(base_fullc63))	
reg ln_basec63 year, robust
predict pred_base_fullc63
replace pred_base_fullc63=-(exp(pred_base_fullc63))
keep year pred_base_fullc63
joinby year using basic
save basic, replace
*stable with country bundle
use part1_ppml_1963_nofta_current_1963, clear
keep coef_lndist year
rename coef_lndist base63c63
gen double ln_base63c63=ln(abs(base63c63))	
reg ln_base63c63 year, robust
predict pred_base63c63
replace pred_base63c63=-(exp(pred_base63c63))
keep year pred_base63c63
joinby year using basic
save basic, replace
*full with naive FTA
use part1_ppml_full_big_current_current, clear
keep Coef_lndist year
rename Coef_lndist base_fullfta
gen double ln_basefta=ln(abs(base_fullfta))	
reg ln_basefta year, robust
predict pred_base_fullfta
replace pred_base_fullfta=-(exp(pred_base_fullfta))
keep year pred_base_fullfta
joinby year using basic
save basic, replace
*stable with naive FTA
use part1_ppml_1963_big_current_current, clear
keep coef_lndist year
rename coef_lndist base63fta
gen double ln_base63fta=ln(abs(base63fta))	
reg ln_base63fta year, robust
predict pred_base63fta
replace pred_base63fta=-(exp(pred_base63fta))
keep year pred_base63fta
joinby year using basic
save basic, replace
**for corr_fta: look into corr_fta.dta
clear
end
recap
