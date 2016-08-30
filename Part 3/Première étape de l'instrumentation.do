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

/*

*****Test pour les BLX, BEL, LUX, FRG, DEU, SER, YUG : donne la liste des années pour lesquelles les pays sont présents

local pays_a_tester
* BLX BEL LUX FRG DEU SER YUG CSK ETF KN1 PCZ PMY PSE SER SVR SU

foreach pays of local pays_a_tester  {
	foreach status in d o {
		local `pays'_`status'
	}
}


foreach year of numlist 1963(1)2013 {
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

*/

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

	clear
end

***********************************************************
*combine with lagged unit values and lagged price levels 
***********************************************************
capture program drop prep_instr
program prep_instr
	args year
	**Exemple : prep_instr 2011
	
	
	
	*group data by 3-year period: lagged prices
	use temp_`year', clear
	save temp_mod_`year', replace
	
	
	local i=1
	
	if `year' == 1964 local laglist 1
	if `year' == 1965 local laglist 1/2
	if `year' >= 1966 local laglist 1/3
	
	foreach lag of numlist `laglist' {
		
		local year_lag = `year'-`lag'
		
		use temp_`year_lag', clear
		assert year==`year_lag'
		keep iso_o iso_d prod_unit sitc4 qty_token qty_unit uv_presente ms_secteur ms_pays
		local vars uv_presente ms_secteur ms_pays
		foreach v of local vars {
			rename `v' `v'_lag_`lag'
		}
		gen year=`year'
		joinby iso_o iso_d year prod_unit sitc4 qty_token qty_unit using temp_mod_`year', unmatched(using)
		drop _merge 
		
		
		
		save temp_mod_`year', replace
	}
	use temp_mod_`year', clear
	joinby iso_o year using tmp_pwt81_`year', unmatched(master)
	drop _merge
	save temp_mod_`year', replace
end



***********************************************************
*run different specifications: save coefs and std errors 
***********************************************************
capture program drop first_stage_instr
program first_stage_instr
	syntax, year(integer) liste_instr(string) /*instr*/
	*years: 1965-2011
	*instr: gdpo i k 
	*exemple : first_stage_instr, year(1965) liste_inst(gdpo i k)
	
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

	if `year' == 1964 local laglist 1
	if `year' == 1965 local laglist 1/2
	if `year' >= 1966 local laglist 1/3
	
	
	foreach lag of numlist `laglist' {
		gen double ln_uv_lag_`lag'=ln(uv_presente_lag_`lag')
		foreach instr of local liste_instr {
			gen double ln_`instr'_lag_`lag'=ln(rel_`instr'_lag_`lag')
		}
	}
	
	*add info on one lag or two lag exporter price level for specifications in which two lags are used
	*reformulate as per year changes:
	
	foreach instr of local liste_instr {
		foreach lag of numlist `laglist' {
		
			gen double ln_rel_`instr'_lag`lag'=ln(rel_`instr'_lag_`lag')
		*	gen double ln_`instr'_lag2=ln(rel_`instr'_`i'/rel_`instr'_`iprime')
		}
	}
	

	*drop if iso_o=="USA"
	**run simple lag specifications and store coefs and std errors: uv and instr in some year
	*local k 3
	
	
	encode prod_unit, generate (prod_unit_num)
	
	foreach lag of numlist `laglist' {
	
		local var_explicatives
		foreach instr of local liste_instr {
				local var_explicatives `var_explicatives' ln_rel_`instr'_lag`lag'
		}
		
		
		
		gen explained = ln_uv - ln_uv_lag_`lag'
		reg explained `var_explicatives' /*, noconstant*/ 
		
		predict explained_predict
		gen ln_uv_instr_`lag'lag = explained_predict + ln_uv_lag_`lag'
		drop explained explained_predict
		
		outreg2 using "$dir/Résultats/Troisième partie/first_stage_results", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
		corr  ln_uv ln_uv_instr_`lag'lag ln_uv_lag_`lag'
		gen uv_instr_`lag'lag = exp(ln_uv_instr_`lag'lag)
		
		local predict_for_corr `predict_for_corr' uv_instr_`lag'lag
		local var_for_corr `var_for_corr' uv_presente_lag_`lag'
		
	
	
	}
	
	
	
	
	corr  uv_presente `var_for_corr' `predict_for_corr'
	/*
	
	***2 lags
	replace explained = ln_uv - ln_uv_`iprime'
	reg explained i.prod_unit_num#c.rel_`instr'_`iprime', noconstant 
	
	predict explained_predict
	gen ln_uv_instr_`instr'_2lag = explained_predict + ln_uv_`iprime'
	drop explained_predict
	*/
	
	/*
	***3 lags
	replace explained = ln_uv - ln_uv_`i'
	reg explained i.prod_unit_num#c.rel_`instr'_`i', noconstant 
	
	predict explained_predict
	gen ln_uv_instr_`instr'_3lag = explained_predict + ln_uv_`i'
	*/
	**Ici, nous allons sauver les résultats.
	
	
	
	
	
	
/*
	foreach t of numlist `i'/`j' {
	
	
	
	
		xi: areg ln_uv I.iso_d ln_uv_`t' ln_`instr'_`t', absorb(prod_unit) cluster(iso_o)
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
			capture generate double coef_`v'=_b[`v'_`t']
			capture generate double se_`v'=_se[`v'_`t']
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
	
*/	
	
	
	
/*	
	

	**run combined lag specifications (first and second lag) and store coefs and std errors: uv and instr in two years
	xi: areg ln_uv I.iso_d ln_uv_`j' ln_uv_`iprime' ln_`instr'_`j' ln_`instr'_lag1, absorb(prod_unit) cluster(iso_o)
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
		capture generate double coef_`v'_year1=_b[`v'_`j']
		capture generate double se_`v'_year1=_se[`v'_`j']
		capture generate double coef_`v'_year2=_b[`v'_`iprime']
		capture generate double se_`v'_year2=_se[`v'_`iprime']
	}
	capture generate double coef_ln_`instr'_year1=_b[ln_`instr'_`j']
	capture generate double se_ln_`instr'_year1=_se[ln_`instr'_`j']
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
	xi: areg ln_uv I.iso_d ln_uv_`iprime' ln_uv_`i' ln_`instr'_`iprime' ln_`instr'_lag2, absorb(prod_unit) cluster(iso_o)
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
		capture generate double coef_`v'_year1=_b[`v'_`iprime']
		capture generate double se_`v'_year1=_se[`v'_`iprime']
		capture generate double coef_`v'_year2=_b[`v'_`i']
		capture generate double se_`v'_year2=_se[`v'_`i']
	}
	capture generate double coef_ln_`instr'_year1=_b[ln_`instr'_`iprime']
	capture generate double se_ln_`instr'_year1=_se[ln_`instr'_`iprime']
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
	
	*/
	
	
 
* drop *`i' *`j' *`iprime' explained* ln_`instr'*

save "$dir/Résultats/Troisième partie/first_stage_`year'_`instr'.dta", replace

	
	
	
end

*instrumenting: for early years, inclusion of product-unit and destination fixed effects adds marginal explanatory power
*but matters for std errors: estimation more precise for gdpo-i-k without product-unit fixed effects (only matters for gdpo-i-k precision)
*use of further lags problematic: cost shocks no longer significant: only lagged prices still work
*hence: use 1;2;3; 1-2; 2-3 lags as alternative instrumenting approaches
*hence: use gdpo, i, k as alternative exporter-level variables


/*
**check results before running instrumented specification: graph coefs and std errors: price level instrument flips sign in 90s!
capture program drop vres
program vres
	args instr 
	*instr: gdpo i k
	use instr_coef_`instr'_baseline, clear
	graph twoway (scatter coef_ln_uv se_ln_uv year if lag_nbr==1) (scatter coef_ln_uv se_ln_uv year if lag_nbr==2) (scatter coef_ln_uv se_ln_uv year if lag_nbr==3)
	*coef on lagged uv very stable: with more lags; over whole sample
	graph twoway (scatter coef_ln_`instr' se_ln_`instr' year if lag_nbr==1), legend(label(1 "coef 1 lag") label(2 "se 1 lag")) 
	local instr k
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
	local instr k
	graph twoway (scatter coef_ln_`instr'_year1 se_ln_`instr'_year1 year if gap==1, msymbol(smcircle plus)) (scatter coef_ln_`instr'_year2 se_ln_`instr'_year2 year if gap==1, msymbol(smcircle plus)), legend(label(1 "coef 1 lag") label(2 "se 1 lag") label(3 "coef 2 lag") label(4 "se 2 lag")) 
	local instr k
	graph twoway (scatter coef_ln_`instr'_year1 se_ln_`instr'_year1 year if gap==2, msymbol(smcircle plus)) (scatter coef_ln_`instr'_year2 se_ln_`instr'_year2 year if gap==2, msymbol(smcircle plus)), legend(label(1 "coef 2 lag") label(2 "se 2 lag") label(3 "coef 3 lag") label(4 "se 4 lag")) 
	*combined: gdpo works for 2d and 3d lag in 1970-1988 (pos, sign) but then tends to flip sign (sometimes pos; sometimes neg)
	*combined: i, k: works for 2d and 3d lag until (roughly) 2000s, then flips sign
end

*/
**bottom line: lagged uv strongly positively linked to current uv (cost or unobserved quality?)
*doesn't alleviate pb of unobserved quality?
*price level instrument is often imprecisely estimated (b/c std errors are clustered by iso_o: otherwise enormous t-stat on lagged uv)
*important: price level flips sign from before to after 1990s...


*NOTES:
*?*redo estimation after dropping iso_o==USA (changes slightly point estimate on price levels) and without clustering by iso_o (precision of price level estimation)
*?*redo estimation for balanced sample (pairs present in each year)
*?*sectoral dimension: estimate sectoral sigmas and change in sectoral sigmas over time using predicted uv
*?*then aggregate to bilat elasticities; aggregate to world elasticity; decompose: composition (between sectors-pairs)/substitution (within sector-pair) 
*why? check whether substitution effects fudged by composition effects





foreach n of numlist 1963/2011 {
	calc_ms `n'
}



foreach n of numlist 1964/2011 {
	prep_instr `n'
}

/*

foreach year of numlist 1964/2011 {
	erase temp_`year'.dta
}


*/


* local instr gdpo /* i k */

foreach n of numlist 1964/2011 {
	local k 1
		first_stage_instr, year(`n') liste_instr(gdpo i k)
	
	
	if `k'!=1 merge 1:1  iso_d-ln_uv using "$dir/Résultats/Troisième partie/first_stage_`n'.dta"
	if `k'!=1 drop _merge
	save "$dir/Résultats/Troisième partie/first_stage_`n'.dta", replace	
	local k = `k'+1
	
}




