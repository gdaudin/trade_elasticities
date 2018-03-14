*March 12th, 2018*
*adjusted to work with pwt 9.0 data and on liza laptop

*Sept 10th, 2015*

*This file combines unit value data with lagged unit values and info on price level changes from PWT 8.1
*to instrument observed unit values prior to running non-linear estimation of Armington elasticity
*assumption: cost shocks to the economy are absorbed relatively quickly: use 1-2-3 lags

****************************************
*set directory*
****************************************
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
	cd "$dir/Data/For Third Part/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013_in2018"
}

*****Test pour les BLX, BEL, LUX, FRG, DEU, SER, YUG

local pays_a_tester 
*BLX BEL LUX FRG DEU SER YUG CSK ETF KN1 PCZ PMY PSE SER SVR SU

foreach pays of local pays_a_tester  {
	foreach status in d o {
		local `pays'_`status'
	}
}

*start from 1962
foreach year of numlist 1962(1)2013 {
	use prepar_cepii_`year', clear
	foreach pays of local pays_a_tester  {
		foreach status in d o {
			capture tabulate iso_`status' if iso_`status'== "`pays'"
			if r(N) >=1 local `pays'_`status' = "``pays'_`status'' `year'"
		}
		
	}
}

foreach pays of local pays_a_tester  {
	foreach status in d o {
		display "`pays'_`status'" "``pays'_`status''"
	}
}


***********************************************************
*prepare annual unit value files: crop data; construct ms 
***********************************************************
*this program replaces calc_ms in estim_nonlin.do and crops uv-sample as in reg_nlin (adjust reg_nlin!)
capture program drop calc_ms
program calc_ms
args year
use prepar_cepii_`year', clear

replace iso_o="BEL" if iso_o=="BLX"
*En effet, BEL et LUX commencent en 1999 dans WITS : c'est toujours BLX avant
*Par contre, toujours DEU

drop if iso_o==iso_d
drop if value_`year'==0
tostring product, gen(sitc4) usedisplayformat
generate prod_unit=sitc4+"_"+qty_unit
gen double uv_presente=uv_`year'
drop if uv_presente<=0

*!*here I take up piece of reg_nlin file: cropping data before instrumenting

*first eliminate small exporters:
rename value_`year' value
bys iso_d: egen tot_import = total(value)
bys iso_d iso_o: egen tot_import_export = total(value)
bys iso_o: egen tot_export = total(value)
egen tot_trade = total(value)
*market share: par destination (before cropping data)
gen double ms_pays = tot_import_export/tot_import
gen double lnms_pays = ln(tot_import_export / tot_import)
*par exportateur dans commerce mondial
gen double ms_tot = tot_export/tot_trade
*enlever ptts exportateurs: 22103 obs in 1967
drop if ms_tot<(1/1000)
drop tot_import tot_trade

*second crop unit values in each market by product and measurement unit:
bys prod_unit iso_d: egen double c_95_uv = pctile(uv_presente), p(95)
bys prod_unit iso_d: egen double c_05_uv = pctile(uv_presente), p(05)
bys prod_unit iso_d: egen double c_50_uv = pctile(uv_presente), p(50)

*in 1967 drops 8800 and 366 obs respectively
drop if uv_presente < c_05_uv | uv_presente > c_95_uv
drop if uv_presente < c_50_uv/100 | uv_presente > c_50_uv*100

*recalculate total imports, total world trade, world market share of exporter
bys iso_d: egen double tot_import = total(value)
egen double tot_trade = total(value)
replace ms_tot = tot_export/tot_trade

*compute sectoral expenditure in each destination:
bys iso_d prod_unit: egen double tot_import_secteur = total(value)
gen double ms_secteur = tot_import_secteur / tot_import

*drop obs with unknown unit values:
drop if uv_`year'==.

*drop redundant variables: first is equal to value; second is equal to tot_export_import
*third is about equal to tot_import
drop tot_pair_product_`year' tot_pair_full_`year' tot_dest_full_`year' uv_`year'
*drop variables I won't use that may mix up with info from other years:
drop c_95* c_05* c_50*

save temp_`year', replace
*erase prepar_cepii_`year'.dta
clear
end

***********************************************************
*combine with lagged unit values and lagged price levels 
***********************************************************
capture program drop prep_instr
program prep_instr
args year
*group data by 3-year period: lagged prices (1965-2013)
use temp_`year', clear
save temp_mod_`year', replace
local i=`year'-3
local j=`year'-1
foreach t of numlist `i'/`j' {
	use temp_`t', clear
	assert year==`t'
	keep iso_o iso_d prod_unit sitc4 qty_token qty_unit uv_presente ms_secteur ms_pays
	local vars uv_presente ms_secteur ms_pays
	foreach v of local vars {
		rename `v' `v'_`t'
	}
	gen year=`year'
	joinby iso_o iso_d year prod_unit sitc4 qty_token qty_unit using temp_mod_`year', unmatched(using)
	drop _merge 
	save temp_mod_`year', replace
}
use temp_mod_`year', clear
joinby iso_o year using tmp_pwt90_`year', unmatched(master)
drop _merge
save temp_mod_`year', replace
erase tmp_pwt90_`year'.dta
erase temp_`i'.dta
clear
end



***********************************************************
*run different specifications: save coefs and std errors 
***********************************************************
capture program drop coef_instr
program coef_instr
args year instr
*years: 1965-2013
*instr: gdpo i k 
use temp_mod_`year', clear
*clean data: restrict to dest-product groups where at least 5 suppliers observed \& to dest where at least 50 products observed
bysort iso_d prod_unit: gen nb_obs=_N
drop if nb_obs<5
preserve
bysort iso_d prod_unit: drop if _n!=1
bysort iso_d: gen nb=_N
by iso_d, sort: drop if _n!=1
keep iso_d nb
drop if nb<50
save tmp, replace
restore
joinby iso_d using tmp, unmatched(none)
erase tmp.dta

*construct logged variables in each year: current and lagged
gen double ln_uv=ln(uv_presente)
local i=`year'-3
local j=`year'-1
local iprime=`year'-2
foreach t of numlist `i'/`j' {
	gen double ln_uv_`t'=ln(uv_presente_`t')
}
rename ln_uv_`i' ln_uv_lag_3
rename ln_uv_`iprime' ln_uv_lag_2
rename ln_uv_`j' ln_uv_lag_1

foreach y of numlist 1/3 {
	gen double ln_`instr'_lag_`y'=ln(rel_`instr'_lag_`y')
}
*add info on one lag or two lag exporter price level for specifications in which two lags are used
*reformulate as per year changes:
gen double ln_`instr'_lag1=ln(rel_`instr'_lag_2/rel_`instr'_lag_1)
gen double ln_`instr'_lag2=ln(rel_`instr'_lag_3/rel_`instr'_lag_2)
*drop if iso_o=="USA"
**run simple lag specifications and store coefs and std errors: uv and instr in some year
local k 3
foreach t of numlist 1/3 {
	xi: areg ln_uv I.iso_d ln_uv_lag_`t' ln_`instr'_lag_`t', absorb(prod_unit) cluster(iso_o)
	preserve
	keep if _n==1
	keep year
	*keep info on which lag this is
	gen lag_year=`t'
	gen lag_nbr=`k'
	scalar define obs=e(N)
	scalar define rsq=e(r2)
	gen obs = obs
	gen rsq = rsq
	local var ln_uv ln_`instr'
	foreach v of local var {
		capture generate double coef_`v'=_b[`v'_lag_`t']
		capture generate double se_`v'=_se[`v'_lag_`t']
	}
	*keep info on price level used:
	gen instr="`instr'"
	*keep info on fixed effects:
	gen fe="dest; prod_unit"
	*keep info on std errors:
	gen stderr="cluster(iso_o)"
	capture append using instr_coef_`instr'_baseline
	save instr_coef_`instr'_baseline, replace
	restore
	local k=`k'-1
}
**run combined lag specifications (first and second lag) and store coefs and std errors: uv and instr in two years
xi: areg ln_uv I.iso_d ln_uv_lag_1 ln_uv_lag_2 ln_`instr'_lag_1 ln_`instr'_lag1, absorb(prod_unit) cluster(iso_o)
preserve
keep if _n==1
keep year
*keep info on which lags these are
gen lag_year1=`j'
gen lag_year2=`iprime'
scalar define obs=e(N)
scalar define rsq=e(r2)
gen obs = obs
gen rsq = rsq
local var ln_uv 
foreach v of local var {
	capture generate double coef_`v'_year1=_b[`v'_lag_1]
	capture generate double se_`v'_year1=_se[`v'_lag_1]
	capture generate double coef_`v'_year2=_b[`v'_lag_2]
	capture generate double se_`v'_year2=_se[`v'_lag_2]
}
capture generate double coef_ln_`instr'_year1=_b[ln_`instr'_lag_1]
capture generate double se_ln_`instr'_year1=_se[ln_`instr'_lag_1]
capture generate double coef_ln_`instr'_year2=_b[ln_`instr'_lag1]
capture generate double se_ln_`instr'_year2=_se[ln_`instr'_lag1]
*keep info on price level used:
gen instr="`instr'"
*keep info on fixed effects:
gen fe="dest; prod_unit"
*keep info on std errors:
gen stderr="cluster(iso_o)"
capture append using instr_coef_`instr'_combined
save instr_coef_`instr'_combined, replace
restore
**run combined lag specifications (second and third lag) and store coefs and std errors: uv and instr in two years
xi: areg ln_uv I.iso_d ln_uv_lag_2 ln_uv_lag_3 ln_`instr'_lag_2 ln_`instr'_lag2, absorb(prod_unit) cluster(iso_o)
keep if _n==1
keep year
*keep info on which lags these are
gen lag_year1=`iprime'
gen lag_year2=`i'
scalar define obs=e(N)
scalar define rsq=e(r2)
gen obs = obs
gen rsq = rsq
local var ln_uv 
foreach v of local var {
	capture generate double coef_`v'_year1=_b[`v'_lag_2]
	capture generate double se_`v'_year1=_se[`v'_lag_2]
	capture generate double coef_`v'_year2=_b[`v'_lag_3]
	capture generate double se_`v'_year2=_se[`v'_lag_3]
}
capture generate double coef_ln_`instr'_year1=_b[ln_`instr'_lag_2]
capture generate double se_ln_`instr'_year1=_se[ln_`instr'_lag_2]
capture generate double coef_ln_`instr'_year2=_b[ln_`instr'_lag2]
capture generate double se_ln_`instr'_year2=_se[ln_`instr'_lag2]
*keep info on price level used:
gen instr="`instr'"
*keep info on fixed effects:
gen fe="dest; prod_unit"
*keep info on std errors:
gen stderr="cluster(iso_o)"
capture append using instr_coef_`instr'_combined
save instr_coef_`instr'_combined, replace
clear
end

*instrumenting: for early years, inclusion of product-unit and destination fixed effects adds marginal explanatory power
*but matters for std errors: estimation more precise for gdpo-i-k without product-unit fixed effects (only matters for gdpo-i-k precision)
*use of further lags problematic: cost shocks no longer significant: only lagged prices still work
*hence: use 1;2;3; 1-2; 2-3 lags as alternative instrumenting approaches
*hence: use gdpo, i, k as alternative exporter-level variables

**check results before running instrumented specification: graph coefs and std errors: price level instrument flips sign in 90s!
capture program drop vres
program vres
args instr 
*instr: gdpo i k
*local instr gdpo
use instr_coef_`instr'_baseline, clear
graph twoway (scatter coef_ln_uv se_ln_uv year if lag_nbr==1) (scatter coef_ln_uv se_ln_uv year if lag_nbr==2) (scatter coef_ln_uv se_ln_uv year if lag_nbr==3)
*coef on lagged uv very stable: with more lags; over whole sample
*coef on lagged gdpo (idem for each lag) not stable: first positive, then all over the place (positive, negative)
graph twoway (scatter coef_ln_`instr' se_ln_`instr' year if lag_nbr==1), legend(label(1 "coef 1 lag") label(2 "se 1 lag")) 
graph twoway (scatter coef_ln_`instr' se_ln_`instr' year if lag_nbr==2) (scatter coef_ln_`instr' se_ln_`instr' year if lag_nbr==3), legend(label(1 "coef 2 lag") label(2 "se 2 lag") label(3 "coef 3 lag") label(4 "se 3 lag")) 
**baseline:
*gdpo: coef 2d and 3d lag significant positive before 1990s; negative when significant after 1990s
*i;k: coef 2d and 3d lag remains sign positive until 2000s, negative when significant, after 2000s
**combined:
use instr_coef_`instr'_combined, clear
gen gap=year-lag_year1
*if gap=1: lag1 and lag2
graph twoway (scatter coef_ln_uv_year1 se_ln_uv_year1 year if gap==1, msymbol(smcircle plus)) (scatter coef_ln_uv_year2 se_ln_uv_year2 year if gap==1, msymbol(smcircle plus)) 
*if gap=2: lag2 and lag3
graph twoway (scatter coef_ln_uv_year1 se_ln_uv_year1 year if gap==2, msymbol(smcircle plus)) (scatter coef_ln_uv_year2 se_ln_uv_year2 year if gap==2, msymbol(smcircle plus)) 
*coef on lagged uv very stable: with more lags; over whole sample
**price level instrument:
graph twoway (scatter coef_ln_`instr'_year1 se_ln_`instr'_year1 year if gap==1, msymbol(smcircle plus)) (scatter coef_ln_`instr'_year2 se_ln_`instr'_year2 year if gap==1, msymbol(smcircle plus)), legend(label(1 "coef 1 lag") label(2 "se 1 lag") label(3 "coef 2 lag") label(4 "se 2 lag")) 
graph twoway (scatter coef_ln_`instr'_year1 se_ln_`instr'_year1 year if gap==2, msymbol(smcircle plus)) (scatter coef_ln_`instr'_year2 se_ln_`instr'_year2 year if gap==2, msymbol(smcircle plus)), legend(label(1 "coef 2 lag") label(2 "se 2 lag") label(3 "coef 3 lag") label(4 "se 4 lag")) 
*combined: gdpo works for 2d and 3d lag in 1970-1988 (pos, sign) but then tends to flip sign (sometimes pos; sometimes neg)
*combined: i, k: works for 2d and 3d lag until (roughly) 2000s, then flips sign
end

*ISSUES with instrumenting
*ok*lagged uv strongly positively linked to current uv but t-stat enormous unless std errors clustered by iso_o
*however* price level instrument (gdpo,i,k) imprecisely estimated when std errors are clustered, and it also changes sign 
*also* coef on price level instrument flips sign from before to after 1990s...


*NOTES:
*?*redo estimation after dropping iso_o==USA (changes slightly point estimate on price levels) and without clustering by iso_o (precision of price level estimation)
*?*redo estimation for balanced sample (pairs present in each year)
*?*sectoral dimension: estimate sectoral sigmas and change in sectoral sigmas over time using predicted uv
*?*then aggregate to bilat elasticities; aggregate to world elasticity; decompose: composition (between sectors-pairs)/substitution (within sector-pair) 
*why? check whether substitution effects fudged by composition effects



*market share file with cropped uv constructed for each year
foreach n of numlist 1962/2013 {
	calc_ms `n'
}

*market share file with lagged uv and 3-year lag is constructed in each year between 1965/2013
foreach n of numlist 1965/2013 {
	prep_instr `n'
}

*only run on gdpo (not i or k)
*local instr gdpo i k
local instr gdpo
foreach i of local instr {
	foreach n of numlist 1965/2013 {
		coef_instr `n' `i'
	}
}


foreach year of numlist 1965/2013 {
	erase temp_mod_`year'.dta
}

*view results (coefs on instruments)
*only run on gdpo (not i or k)
*local instr gdpo i k
local instr gdpo
foreach i of local instr {
		vres `i'
}

