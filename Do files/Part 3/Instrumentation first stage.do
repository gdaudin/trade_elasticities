*This version adjusted so that data cleaning for each lag is independent

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

*for office laptop
if "`c(username)'" =="archael" {
	global dir "P:\ECFIN Public\Orbis\sitc"
	global dirgit "P:\ECFIN Public\Orbis\sitc"
	cd "P:\ECFIN Public\Orbis\sitc"
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
*local liste_instr uv gdpo om
	
use For_instru_`year', clear
*T5* this selection eliminated: objective is to use as much info as possible on iso_o prod_unit to instrument ln_uv
* destination-supplier selection (if any) should be done directly in second stage
/*
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
*/
	
	
	*construct logged variables in each year: current and lagged
gen double ln_uv=ln(uv_presente)

if `year' == 1963 local laglist 1
if `year' == 1964 local laglist 1/2
if `year' >= 1965 local laglist 1/3
	
	
foreach lag of numlist `laglist' {
	gen double ln_uv_lag_`lag'=ln(uv_lag_`lag')
	gen double explained_lag_`lag' = ln_uv - ln_uv_lag_`lag'
	gen	double weight_lag_`lag' = value_lag_`lag'/uv_lag_`lag'
	label var weight_lag_`lag' "Poids pour l'instrumentation par le prix des autres marchés"
	foreach instr of local liste_instr {
		if "`instr'" != "om" & "`instr'" != "uv"{
			gen double ln_rel_`instr'_lag`lag'=ln(rel_`instr'_lag_`lag')
		}
		if "`instr'" == "uv" {
			gen double ln_`instr'_lag`lag'=ln(`instr'_lag_`lag')
		}
		if "`instr'" == "om" {
** Pour calculer l'évolution du prix dans les autres marchés
			gen double blif = explained_lag_`lag' * weight_lag_`lag'
			egen double blouk = total(blif), by(iso_o prod_unit)
			egen double blik = total(weight_lag_`lag'), by (iso_o prod_unit)
			gen double ln_rel_`instr'_lag`lag' = (blouk-blif)/(blik-weight_lag_`lag')
			gen double evolution_ln_moy_lag_`lag' = blouk/blik
*Je calcule evolution_ln_moy_lag_`lag' par curiosité : c'est l'évolution de tous les prix, y compris celui qui va être instrumenté	
*T2 inserted here: control on nb other markets present in construction of "om": id_om`lag'=1 if nbr_markets>2
** create id_om`lag' to pin down obs to keep when particular lag used (and liste_instr contains om)
		preserve
		keep if ln_rel_`instr'_lag`lag'!=.
		bys iso_o prod_unit: gen nbr_markets=_N
*NB* there are quite a few obs for which uv_lag is absent but rel_`instr'_lag`lag' is defined (!)
** construct ln_uv_om_lag`lag' (by iso_o prod_unit); eventually to replace lacking uv_lag_`lag'
		gen double comp_uv=ln_uv_lag_`lag'*weight_lag_`lag'
		egen double tot_comp=total(comp_uv), by(iso_o prod_unit)
		egen double tot_weight=total(weight_lag_`lag'), by(iso_o prod_unit)
		gen double ln_uv_om_lag`lag'=tot_comp/tot_weight
		drop comp_uv tot_comp tot_weight
		bys iso_o prod_unit: drop if _n!=1
		keep iso_o prod_unit nbr_markets ln_uv_om_lag`lag'
		save tmp, replace
		restore
		joinby iso_o prod_unit using tmp, unmatched(both)
		replace nbr_markets=0 if _merge==1
		drop blif blouk blik _merge		
		erase tmp.dta
*NB* define sample for basic regression: id_om_lag`lag'=1 only if ln_rel_om_lag`lag' is defined & nb_markets>2
		gen id_`instr'`lag'=0
		replace id_`instr'`lag'=1 if (nbr_markets>2 & ln_rel_`instr'_lag`lag'!=.)
*NB* explained_lag`lag' defined to follow convention with other variables: no underscore between lag`lag'
		gen double explained_lag`lag' = explained_lag_`lag'
		drop nbr_markets
		}
	}
}
	


**run simple lag specifications and store coefs and std errors: uv and instr in some year
*local k 3
	
*NB*the lines below do not do anything, b/c "`instr'" is not defined [removed]	
/*
	if "`instr'" == "om" {
*T2 implemented* this check removed (done above)..Remove when the number of peer markets is not at least two
*NB* this line does not guarantee that uv growth is observed on at least 3 markets (uv/uv_lag could be .)
*		bys iso_o prod_unit : drop if _N <=3
		egen iso_o_iso_d_prod_unit=group(iso_o iso_d prod_unit)
*NB* what is this "su ..., meanonly" for?
		su iso_o_iso_d_prod_unit, meanonly
		generate iso_o_prod_unit = iso_o+"_"+prod_unit
	}
*/	
	
encode prod_unit, generate (prod_unit_num)
	
display "`liste_instr'"

foreach lag of numlist `laglist' {
	local var_explicatives
	foreach instr of local liste_instr {
		if "`instr'" == "uv" {
*T1 implemented here: no "_" in ln_`instr'_lag`lag'
			local var_explicatives `var_explicatives' ln_`instr'_lag`lag'
		}
		if "`instr'" != "uv" {
			local var_explicatives `var_explicatives' ln_rel_`instr'_lag`lag'
		}		
		if "`instr'" == "om" {
**Pour enlever les évolutions extrêmes
*T3 implemented here* same sample to define all r(p1) and r(p99), specific to lag
*T6 implemented here: run regression on lag-specific subset of obs; no data dropping
*NB* reviewed to have thresholds for ln_rel_`instr' and explained_lag defined on same sample
*and to create id that keeps memory of cropped obs for specific lag (no obs dropped)				
*id_var_crop_lag`lag' crops distribution of uv_growth on other markets
			summarize ln_rel_`instr'_lag`lag' if id_`instr'`lag'==1, det
			scalar define rel_p99_lag`lag'=r(p99)
			scalar define rel_p01_lag`lag'=r(p1)
			gen id_var_crop_lag`lag'=0
			replace id_var_crop_lag`lag'=1 if id_`instr'`lag'==1 & ln_rel_`instr'_lag`lag'>=rel_p01_lag`lag' & ln_rel_`instr'_lag`lag'<=rel_p99_lag`lag'
*id_var_cropcrop_lag`lag' crops distribution of own growth in specific market
			summarize explained_lag`lag' if id_`instr'`lag'==1, det
			scalar define expl_p99_lag`lag'=r(p99)
			scalar define expl_p01_lag`lag'=r(p1)
			gen id_var_cropcrop_lag`lag'=0
			replace id_var_cropcrop_lag`lag'=1 if id_`instr'`lag'==1 & explained_lag`lag'>=expl_p01_lag`lag' & explained_lag`lag'<=expl_p99_lag`lag'
*id_var_lag`lag': most restrictive identifier; to be used in regression 
** this approach leaves 91% of obs in regression in 1995 (minimizes loss v-a-v non-instrumented)
			gen id_var_lag`lag'=0
			replace id_var_lag`lag'=1 if id_var_crop_lag`lag'==1 & id_var_cropcrop_lag`lag'==1
		}
	}

		
	display "`var_explicatives'"
*NB* destination-supplier selection not done in first stage
** no price indices computed here, so not clear why sample should be restricted to markets with sufficiently many products

*T6 implemented here* regression run on subsample of obs (nbr_markets>2; cropping); and predict in sample (!)	
	if strpos("`liste_instr'","uv")==0 {
		reg explained_lag`lag' `var_explicatives' if id_var_lag`lag'==1 
	}
		
	if strpos("`liste_instr'","uv")!=0 {
		reg ln_uv `var_explicatives' if id_var_lag`lag'==1
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
		
*NB* specify that prediction is restricted to subsample on which estimation carried out		
	predict predict if e(sample)
		
	local liste_instr = subinstr("`liste_instr'"," ","_",.)
		
	if strpos("`liste_instr'","uv")==0 {
		gen double ln_uv_`liste_instr'_`lag'lag = predict + ln_uv_lag_`lag'
		drop predict
	}
	if strpos("`liste_instr'","uv")!=0 {
		rename predict ln_uv_`liste_instr'_`lag'lag
	}
		
		
	drop explained_lag_`lag' explained_lag`lag'
		
	if strmatch("`c(username)'","*daudin*")==1 {
		outreg2 using "$dir/Résultats/Troisième partie/first_stage_results_`liste_instr'_`lag'", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
	}
	if "`c(hostname)'" =="LAmacbook.local" | "`c(username)'"=="archael" {
		outreg2 using "first_stage_results_`liste_instr'_`lag'", excel ctitle(`year'_`lag'lag) adds(F-test, `e(F)', Nbr obs, `e(N)')
	}
	corr  ln_uv ln_uv_`liste_instr'_`lag'lag ln_uv_lag_`lag'
	gen double uv_`liste_instr'_`lag'lag = exp(ln_uv_`liste_instr'_`lag'lag)
		
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
*NB*capture cannot work: corrected
capture erase tmp_coefs_`instr'.dta
foreach year of numlist 1963/2013 {
	use "tmp_coefs_`liste_instr'_`year'.dta",clear
	if `year'!=1963 append using "tmp_coefs_`liste_instr'.dta"
	save "tmp_coefs_`liste_instr'.dta", replace
*NB* suppressed: regressions for specific instruments not run
/*foreach instr of local liste_instr {
		use "tmp_coefs_`instr'_`year'.dta", clear
		if `year'!=1963 append using "tmp_coefs_`instr'.dta"
		save "tmp_coefs_`instr'.dta", replace
	}
*/
}



foreach year of numlist 1963/2013 {
	erase "tmp_coefs_`liste_instr'_`year'.dta"
*NB* suppressed: regressions for specific instruments not run
/*
foreach instr of local liste_instr {
		erase "tmp_coefs_`instr'_`year'.dta"
	}
*/
}

*recap graph: scheme s2mono 
*local liste_instr uv gdpo om 
*local liste_instr uv


end



capture program drop graphs
program  graphs
syntax, liste_instr(string) regression(string)
*regression is either "full" or "individual"

*NB* adjustment here: "_" removed in coef_ln_uv_lag`lag' and se_ln_uv_lag`lag'
local list_graph
if "`regression'" == "full" use "tmp_coefs_`liste_instr'.dta", clear
foreach instr of local liste_instr {
	if "`regression'" == "individual" use "tmp_coefs_`instr'.dta", clear
	foreach lag of numlist 1/3 {
		if "`instr'"=="uv" {
			rename coef_ln_uv_lag`lag' coef_ln_rel_`instr'_lag`lag'
			rename se_ln_uv_lag`lag' se_ln_rel_`instr'_lag`lag'
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
		if "`instr'"!="uv" local list_graph  `list_graph' `instr'`lag'.gph
	}
	 if "`regression'" == "full" use "tmp_coefs_`liste_instr'.dta", clear
}

local nbr_of_rows=wordcount("`liste_instr'")-1
graph combine `list_graph', iscale(.5) ///
	scheme(s1mono) rows(`nbr_of_rows') ycommon xcommon note("Note: [GDP] stands for GDP price level, [OM] for the price evolution in other markets",justification(center))
*[I] stands for investment price level," "
graph export "firststage_reg`regression'_`liste_instr'_non_uv.eps", replace
*NB*adjusted to work on office laptop:
if strmatch("`c(username)'","*daudin*")==1 | "`c(hostname)'" =="LAmacbook.local" {
	graph export "$dirgit/trade_elasticities/Rédaction/tex/firststage_reg`regression'_`liste_instr'_non_uv.pdf", replace
}
if "`c(username)'"=="archael" {
	graph export "firststage_reg`regression'_`liste_instr'_non_uv.pdf", replace
}


graph combine uv1.gph uv2.gph uv3.gph, iscale(.5) ///
	scheme(s1mono) rows(1) ycommon xcommon note("Note: [UV] stands for unit values",justification(center))
graph export "firststage_reg`regression'_`liste_instr'_uv.eps", replace

*NB*adjusted to work on office laptop:
if strmatch("`c(username)'","*daudin*")==1 | "`c(hostname)'" =="LAmacbook.local" {
	graph export "$dirgit/trade_elasticities/Rédaction/tex/firststage_reg`regression'_`liste_instr'_uv.pdf", replace
}
if "`c(username)'"=="archael" {
	graph export "firststage_reg`regression'_`liste_instr'_uv.pdf", replace
}





**** When I am ready to erase

*local liste_instr gdpo i om uv
foreach instr of local liste_instr {
	foreach lag of numlist 1/3 {
		erase `instr'`lag'.gph
	}
}


**alternative: use scheme(s1color); order legend differently (pass-through, then CI, then fit?)
end

*PROGRAMS FIRST STAGE:


*first_stage_instr, year(1970) liste_instr(uv)



*NB* order of instruments changed .om. has to come after .uv. to create required variables in right order
local liste_instr uv gdpo om



*local liste_instr uv

local startyear 1963
local start_instr = word("`list_instr'",1)

foreach year of numlist 1963/2013 {
***********************Tous les instruments ensemble
	first_stage_instr, year(`year') liste_instr(`liste_instr')
	if strmatch("`c(username)'","*daudin*")==1 {
		save "$dir/Résultats/Troisième partie/first_stage_`liste_instr'_`year'.dta", replace
	}
	if "`c(hostname)'" =="LAmacbook.local" | "`c(username)'"=="archael" {
		save "first_stage_`liste_instr'_`year'.dta", replace
	}
/*
*NB* suppressed: not clear why instruments would be used one by one
******************************Instruments un par un
	 foreach instr of local liste_instr {
		first_stage_instr, year(`year') liste_instr(`instr')
		if strmatch("`c(username)'","*daudin*")==1 {
			merge 1:1  iso_d-ln_uv using "$dir/Résultats/Troisième partie/first_stage_`liste_instr'_`year'.dta"
			drop _merge
			save "$dir/Résultats/Troisième partie/first_stage_`liste_instr'_`year'.dta", replace
		}
	if "`c(hostname)'" =="LAmacbook.local" | "`c(username)'"=="archael"{
			merge 1:1  iso_d-ln_uv using "first_stage_`liste_instr'_`year'.dta"
			drop _merge
			save "first_stage_`liste_instr'_`year'.dta", replace
		}	
	}
*/
}

concatenate, liste_instr(`liste_instr')
/*
*NB*this suppressed: individual regression not run (only makes sense for gdpo and om)
graphs, liste_instr(`liste_instr') regression(individual)
*/
graphs, liste_instr(`liste_instr') regression(full)

