*Does one instrumentation

****************************************
*set directory*
****************************************
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/2007 OFCE Substitution Elasticities local/"
	global dirgit "~/Documents/Recherche/2007 OFCE Substitution Elasticities local/Git/"
    cd "$dir/Data_Interm/Third_Part/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	global dirgit "/Users/liza/Documents/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013_in2018"
}



***********************************************************
*run different specifications: save coefs and std errors 
***********************************************************
*modif ici pour garder coefs et std_errors dans fichier .dta

capture program drop first_stage_instr
program first_stage_instr
	syntax, year(integer) /*instr*/

	*years: 1963-2013
	*instr: x
	*exemple : first_stage_instr, year(1965)
*local year 1965 
	
	use For_instru_`year', clear
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

	/*
	if `year' == 1963 local laglist 1
	if `year' == 1964 local laglist 1/2
	if `year' >= 1965 local laglist 1/3
	*/
	
	local laglist 1
	
	foreach lag of numlist `laglist' {
		drop if uv_presente_lag_`lag' ==.
		gen double ln_uv_lag_`lag'=ln(uv_presente_lag_`lag')
		gen uv_evolution_lag_`lag' = uv_presente/uv_presente_lag_`lag'-1
		gen	weight_lag_`lag' = value_lag_`lag'/uv_presente_lag_`lag'
		
	}

	
** Remove when the number of peer markets is not at least two

bys iso_o prod_unit : drop if _N <=3
	
	
	
**To organize a loop over iso_o x iso_d x prod_unit
**So that we can compute the uv evolution over iso_o x produ_unit 
**except for that one iso_d

egen iso_o_iso_d_prod_unit=group(iso_o iso_d prod_unit)
su iso_o_iso_d_prod_unit, meanonly
generate iso_o_prod_unit = iso_o+"_"+prod_unit

**To compute the weighte (by quantities in lag) mean of the evolution of uv
**in other iso_d for a given iso_o x iso_d x prod_unit



*****************************************************
***Cela semble marcher, mais c'est très lent...
/*
forvalues i = 1/`r(max)' {
quietly levelsof iso_o_prod_unit if iso_o_iso_d_prod_unit == `i', local(iso_o_prod_unit) 
quietly levelsof iso_d if iso_o_iso_d_prod_unit == `i', local(iso_d) 
*display `iso_d'
*display `iso_o_prod_unit'
foreach lag of numlist `laglist' {
	gen evolution_to_weight_`lag' = uv_evolution_lag_`lag' if iso_o_prod_unit==`iso_o_prod_unit' ////
				& iso_d !=`iso_d'
	gen weight_`lag' = weight_lag_`lag' if iso_o_prod_unit==`iso_o_prod_unit' ////
				& iso_d !=`iso_d'
	gen blif = evolution_to_weight_`lag' * weight_`lag'
	egen blouk = total(blif)
	egen blik = total(weight_`lag')
	replace evolution_other_markets_lag_`lag' = blouk/blik if iso_o_iso_d_prod_unit == `i'
	drop blif blouk blik evolution_to_weight_`lag' weight_`lag'
	}

/*
***Pour vérifier que tout va bien	
	if runiformint(1,100) ==1 {
		br if iso_o_prod_unit==`iso_o_prod_unit'
		display `iso_d'
		blif 
	}
*/
}
*/
***************************************************

****J'essaye une autre méthode

foreach lag of numlist `laglist' {
	gen blif = uv_evolution_lag_`lag' * weight_lag_`lag'
	egen blouk = total(blif), by(iso_o prod_unit)
	egen blik = total(weight_lag_`lag'), by (iso_o prod_unit)
	gen evolution_other_markets_lag_`lag' = (blouk-blif)/(blik-weight_lag_`lag')
	gen evolution_moy_lag_`lag' = blouk/blik
}




summarize evolution_other_markets_lag_1, det
drop if evolution_other_markets_lag_1 >=r(p90)
summarize evolution_other_markets_lag_1, det
drop if evolution_other_markets_lag_1 <=r(p10)

summarize uv_evolution_lag_1, det
drop if uv_evolution_lag_1 >=r(p90)
summarize uv_evolution_lag_1, det
drop if uv_evolution_lag_1 <=r(p10)






reg uv_evolution_lag_1 evolution_other_markets_lag_1
reg uv_evolution_lag_1 evolution_other_markets_lag_1 [aweight=weight_lag_1]



end
/*
blif












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
		
		preserve
		keep in 1
		keep year
		foreach v of local var_explicatives {
			gen coef_`v'=_b[`v']
			ge se_`v'=_se[`v']
			if `lag'!=1 {
				joinby year using tmp_coefs_`liste_instr'_`year', unmatched(none)
			}
			save tmp_coefs_`liste_instr'_`year', replace
		}
		restore
		
		predict explained_predict
		gen ln_uv_`liste_instr'_`lag'lag = explained_predict + ln_uv_lag_`lag'
		drop explained explained_predict
		
		if strmatch("`c(username)'","*daudin*")==1 {
			outreg2 using "$dir/Résultats/Troisième partie/first_stage_results", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
		}
		if "`c(hostname)'" =="LAmacbook.local" {
			outreg2 using "first_stage_results", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
		}
		corr  ln_uv ln_uv_`liste_instr'_`lag'lag ln_uv_lag_`lag'
		gen uv_`liste_instr'_`lag'lag = exp(ln_uv_`liste_instr'_`lag'lag)
		
		local predict_for_corr `predict_for_corr' uv_`liste_instr'_`lag'lag
		local var_for_corr `var_for_corr' uv_presente_lag_`lag'
		
	
	
	}
	
	
	
	
	corr  uv_presente `var_for_corr' `predict_for_corr'
	
	
	
end
*/

*PROGRAMS FIRST STAGE:

first_stage_instr, year(1963)
first_stage_instr, year(1986)
first_stage_instr, year(2005)




/*

foreach year of numlist 1963/2013 {
	local k 1
		first_stage_instr, year(`year') 
		if strmatch("`c(username)'","*daudin*")==1 {
			if `k'!=1 merge 1:1  iso_d-ln_uv using "$dir/Résultats/Troisième partie/first_stage_OM_`year'.dta"
			if `k'!=1 drop _merge
			save "$dir/Résultats/Troisième partie/first_stage_OM_`year'.dta", replace

		if "`c(hostname)'" =="LAmacbook.local" {
			if `k'!=1 merge 1:1  iso_d-ln_uv using "first_stage_OM_`year'.dta"
			if `k'!=1 drop _merge
			save "first_stage_`year'_OM.dta", replace
		}
		local k = `k'+1
	}
}

** keep all estimated coefs in one file (per instrument: gdpo, i)
local liste_instr gdpo i
capture erase tmp_coefs_`instr', replace
foreach instr of local liste_instr {
	foreach year of numlist 1963/2013 {
		use tmp_coefs_`instr'_`year', clear
		if `year'!=1963 {
			append using tmp_coefs_`instr'
		}
		save tmp_coefs_`instr', replace
		erase tmp_coefs_`instr'_`year'.dta
	}
}

*recap graph: scheme s2mono 
local liste_instr gdpo i
foreach instr of local liste_instr {
	use tmp_coefs_`instr', clear
	foreach lag of numlist 1/3 {
		gen low_`lag'=coef_ln_rel_`instr'_lag`lag'-2*se_ln_rel_`instr'_lag`lag'
		gen high_`lag'=coef_ln_rel_`instr'_lag`lag'+2*se_ln_rel_`instr'_lag`lag'
		if "`instr'"=="gdpo" {
			graph twoway (rarea low_`lag' high_`lag' year, fintensity(inten20) lpattern(dot) lwidth(thin)) ///
			(connected coef_ln_rel_`instr'_lag`lag' year, lwidth(medthin) lpattern(solid) msymbol(smcircle_hollow) msize(small)) ///
			(fpfit coef_ln_rel_`instr'_lag`lag' year, est(degree(4)) lwidth(thin) lpattern(dash) lcolor(red)), ///
			legend(order (`lag') label(1 "95% confidence interval" ) label( 2 "pass-through") label(3 "fractional polynomial fit")) title("lag `lag' [GDP]") /// 
			scheme(s1mono) saving(`instr'`lag')
		}
		if "`instr'"=="i"  {
			graph twoway (rarea low_`lag' high_`lag' year, fintensity(inten20) lpattern(dot) lwidth(thin)) ///
			(connected coef_ln_rel_`instr'_lag`lag' year, lwidth(medthin) lpattern(solid) msymbol(smcircle_hollow) msize(small)) ///
			(fpfit coef_ln_rel_`instr'_lag`lag' year, est(degree(4)) lwidth(thin) lpattern(dash) lcolor(red)), ///
			 legend(order (`lag') label(1 "95% confidence interval" ) label( 2 "pass-through") label(3 "fractional polynomial fit")) title("lag `lag' [I]") ///
			 scheme(s1mono) saving(`instr'`lag')
		}
	}
}
graph combine gdpo1.gph gdpo2.gph gdpo3.gph i1.gph i2.gph i3.gph, iscale(.5) ///
	scheme(s1mono) rows(2) ycommon xcommon note("Note: [GDP] stands for GDP price level, [I] stands for investment price level",justification(center))
graph export firststage.eps, replace

graph export "$dirgit/trade_elasticities/Rédaction/tex/firststage.pdf", replace


local liste_instr gdpo i
foreach instr of local liste_instr {
	foreach lag of numlist 1/3 {
		erase `instr'`lag'.gph
	}
}

**alternative: use scheme(s1color); order legend differently (pass-through, then CI, then fit?)
