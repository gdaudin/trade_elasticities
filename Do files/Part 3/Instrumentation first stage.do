*Does one instrumentation
*assumption: cost shocks to the economy are absorbed relatively quickly: use 1-2-3 lags

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
	syntax, year(integer) liste_instr(string) /*instr*/

	*years: 1963-2013
	*instr: x
	*exemple : first_stage_instr, year(1965) liste_instr(x)
*local year 1965 
*local liste_instr gdpo
	
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

	if `year' == 1963 local laglist 1
	if `year' == 1964 local laglist 1/2
	if `year' >= 1965 local laglist 1/3
	
	
	foreach lag of numlist `laglist' {
		gen double ln_uv_lag_`lag'=ln(uv_lag_`lag')
		gen explained_lag_`lag' = ln_uv - ln_uv_lag_`lag'
		gen	weight_lag_`lag' = value_lag_`lag'/uv_lag_`lag'
		label var weight_lag_`lag' "Poids pour l'instrumentation par la prix des autres marchés"
		foreach instr of local liste_instr {
			if "`instr'" != "om" & "`instr'" != "uv"{
				gen double ln_rel_`instr'_lag`lag'=ln(rel_`instr'_lag_`lag')
			}
			if "`instr'" == "uv" {
				gen double ln_`instr'_lag`lag'=ln(`instr'_lag_`lag')
			}
			if "`instr'" == "om" {
				** Pour calculer l'évolution du prix dans les autres marchés
				gen blif = explained_lag_`lag' * weight_lag_`lag'
				egen blouk = total(blif), by(iso_o prod_unit)
				egen blik = total(weight_lag_`lag'), by (iso_o prod_unit)
				gen ln_rel_`instr'_lag`lag' = (blouk-blif)/(blik-weight_lag_`lag')
				gen evolution_ln_moy_lag_`lag' = blouk/blik
				drop blif blouk blik			
			}
		}
	}
	


	**run simple lag specifications and store coefs and std errors: uv and instr in some year
	*local k 3
	
	if "`instr'" == "om" {
		** Remove when the number of peer markets is not at least two
		bys iso_o prod_unit : drop if _N <=3
		egen iso_o_iso_d_prod_unit=group(iso_o iso_d prod_unit)
		su iso_o_iso_d_prod_unit, meanonly
		generate iso_o_prod_unit = iso_o+"_"+prod_unit
	}
	
	encode prod_unit, generate (prod_unit_num)
	
	display "`liste_instr'"

	foreach lag of numlist `laglist' {
		local var_explicatives
		foreach instr of local liste_instr {
				if "`instr'" == "uv" {
					local var_explicatives `var_explicatives' ln_`instr'_lag_`lag'
				}
				if "`instr'" != "uv" {
				local var_explicatives `var_explicatives' ln_rel_`instr'_lag`lag'
				}
				
				if "`instr'" == "om" {
					**Pour enlever les évolutions extrêmes
					summarize ln_rel_`instr'_lag`lag', det
					drop if ln_rel_`instr'_lag`lag' >=r(p99)
					summarize ln_rel_`instr'_lag`lag', det
					drop if ln_rel_`instr'_lag`lag' <=r(p1)

					summarize explained_lag_`lag', det
					drop if explained_lag_`lag' >=r(p99)
					summarize explained_lag_`lag', det
					drop if explained_lag_`lag' <=r(p1)			
			}
		}

		
		display "`var_explicatives'"
	*	blouf
		
		if strpos("`liste_instr'","uv")==0 {
			reg explained_lag_`lag' `var_explicatives' /*, noconstant*/ 
		}
		
		if strpos("`liste_instr'","uv")!=0 {
			reg ln_uv `var_explicatives'
		}
			
		preserve
		keep in 1
		keep year
		foreach v of local var_explicatives {
			gen coef_`v'=_b[`v']
			ge se_`v'=_se[`v']
			if `lag'!=1 {
				joinby year using "tmp_coefs_`liste_instr'_`year'.dta", unmatched(none)
			}
			save "tmp_coefs_`liste_instr'_`year'.dta", replace
		}
		restore
		
		predict predict
		
		local liste_instr = subinstr("`liste_instr'"," ","_",.)
		
		if strpos("`liste_instr'","uv")==0 {
			gen ln_uv_`liste_instr'_`lag'lag = predict + ln_uv_lag_`lag'
			drop predict
		}
		if strpos("`liste_instr'","uv")!=0 {
			rename predict ln_uv_`liste_instr'_`lag'lag
		}
		
		
		drop explained_lag_`lag'
		
		if strmatch("`c(username)'","*daudin*")==1 {
			outreg2 using "$dir/Résultats/Troisième partie/first_stage_results_`liste_instr'_`lag'", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
		}
		if "`c(hostname)'" =="LAmacbook.local" {
			outreg2 using "first_stage_results_`liste_instr'_`lag'", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
		}
		corr  ln_uv ln_uv_`liste_instr'_`lag'lag ln_uv_lag_`lag'
		gen uv_`liste_instr'_`lag'lag = exp(ln_uv_`liste_instr'_`lag'lag)
		
		local predict_for_corr `predict_for_corr' uv_`liste_instr'_`lag'lag
		local var_for_corr `var_for_corr' uv_lag_`lag'
		
		
		local liste_instr = subinstr("`liste_instr'","_"," ",.)
	
	
	}
	
	
	
	
	corr  uv_presente `var_for_corr' `predict_for_corr'


end



capture program drop concatenate
program  concatenate
syntax, liste_instr(string)



** keep all estimated coefs in one file (per instrument: gdpo, i, om)
*local liste_instr gdpo om uv
*local liste_instr uv
capture erase tmp_coefs_`instr', replace
foreach year of numlist 1963/2013 {
	use "tmp_coefs_`liste_instr'_`year'.dta",clear
	if `year'!=1963 append using "tmp_coefs_`liste_instr'.dta"
	save "tmp_coefs_`liste_instr'.dta", replace
	erase "tmp_coefs_`liste_instr'_`year'.dta"
	foreach instr of local liste_instr {
		use "tmp_coefs_`instr'_`year'.dta", clear
		if `year'!=1963 append using "tmp_coefs_`instr'.dta"
		save "tmp_coefs_`instr'.dta", replace
		erase "tmp_coefs_`instr'_`year'.dta"
	}
}

*recap graph: scheme s2mono 
*local liste_instr uv gdpo om 
*local liste_instr uv

end

capture program drop graphs
program  graphs
syntax, liste_instr(string)


local list_graph
foreach instr of local liste_instr {
	use tmp_coefs_`instr', clear
	foreach lag of numlist 1/3 {
		if "`instr'"=="uv" {
			rename coef_ln_uv_lag_`lag' coef_ln_rel_`instr'_lag`lag'
			rename se_ln_uv_lag_`lag' se_ln_rel_`instr'_lag`lag'
			local graph_title lag `lag' [LP]
		}
		gen low_`lag'=coef_ln_rel_`instr'_lag`lag'-2*se_ln_rel_`instr'_lag`lag'
		gen high_`lag'=coef_ln_rel_`instr'_lag`lag'+2*se_ln_rel_`instr'_lag`lag'
		if "`instr'" == "gdpo" local graph_title lag `lag' [GDP]
		if "`instr'" == "i" local graph_title lag `lag' [I]
		if "`instr'" == "om" local graph_title lag `lag' [OM]
		if "`instr'" == "uv" local graph_title lag `lag' [UV]
		
		graph twoway (rarea low_`lag' high_`lag' year, fintensity(inten20) lpattern(dot) lwidth(thin)) ///
		(connected coef_ln_rel_`instr'_lag`lag' year, lwidth(medthin) lpattern(solid) msymbol(smcircle_hollow) msize(small)) ///
		(fpfit coef_ln_rel_`instr'_lag`lag' year, est(degree(4)) lwidth(thin) lpattern(dash) lcolor(red)), ///
		legend(order (`lag') label(1 "95% confidence interval" ) label( 2 "pass-through") label(3 "fractional polynomial fit")) title("`graph_title'") /// 
		scheme(s1mono) saving(`instr'`lag', replace)
		if "`instr'"!="uv" local list_graph `list_graph'`instr'`lag'.gph
	}
}
graph combine `list_graph', iscale(.5) ///
	scheme(s1mono) rows(3) ycommon xcommon note("Note: [GDP] stands for GDP price level, [I] stands for investment price level," "[OM] for the price evolution in other markets",justification(center))
graph export firststage_a.eps, replace

graph export "$dirgit/trade_elasticities/Rédaction/tex/firststage_`liste_instr'_a.pdf", replace


graph combine uv1.gph uv2.gph uv3.gph, iscale(.5) ///
	scheme(s1mono) rows(1) ycommon xcommon note("Note: [UV] stands for unit values",justification(center))
graph export firststage_b.eps, replace

graph export "$dirgit/trade_elasticities/Rédaction/tex/firststage_`liste_instr'_b.pdf", replace




**** When I am ready to erase
/*
*local liste_instr gdpo i om uv
foreach instr of local liste_instr {
	foreach lag of numlist 1/3 {
		erase `instr'`lag'.gph
	}
}



foreach year of numlist 1963/2013 {
	erase "tmp_coefs_`liste_instr'_`year'.dta"
	foreach instr of local liste_instr {
		erase "tmp_coefs_`instr'_`year'.dta"
	}
}
*/

**alternative: use scheme(s1color); order legend differently (pass-through, then CI, then fit?)
end

*PROGRAMS FIRST STAGE:


*first_stage_instr, year(1970) liste_instr(uv)



local liste_instr gdpo om uv
*local liste_instr uv

foreach year of numlist 1963/2013 {
	local k 1
***********************Tous les instrumets ensemble
	first_stage_instr, year(`year') liste_instr(`liste_instr')
	if strmatch("`c(username)'","*daudin*")==1 {
		save "$dir/Résultats/Troisième partie/first_stage_together_`liste_instr'_`year'.dta", replace
	}
	if "`c(hostname)'" =="LAmacbook.local" {
		if `k'!=1 merge 1:1  iso_d-ln_uv using "first_stage_together_`liste_instr'_`year'.dta"
		if `k'!=1 drop _merge
		save "first_stage_together_`liste_instr'_`lag'_`year'.dta", replace
	}
******************************Instruments un par un
	 foreach instr of local liste_instr {
		first_stage_instr, year(`year') liste_instr(`instr')
		if strmatch("`c(username)'","*daudin*")==1 {
			if `k'!=1 merge 1:1  iso_d-ln_uv using "$dir/Résultats/Troisième partie/first_stage_`instr'_`year'.dta"
			if `k'!=1 drop _merge
			save "$dir/Résultats/Troisième partie/first_stage_`instr'_`year'.dta", replace
		}
		if "`c(hostname)'" =="LAmacbook.local" {
			if `k'!=1 merge 1:1  iso_d-ln_uv using "first_stage_`instr'_`year'.dta"
			if `k'!=1 drop _merge
			save "first_stage_`instr'_`lag'_`year'.dta", replace
		}
		local k = `k'+1
	}
}

concatenate, liste_instr(`liste_instr')
graphs, liste_instr(`liste_instr')
