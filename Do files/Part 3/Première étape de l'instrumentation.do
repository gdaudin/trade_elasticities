*March 19th, 2018*
*adjusted to work on liza laptop

*Sept 10th, 2015*

*This file combines unit value data with lagged unit values and info on price level changes from PWT
*to instrument observed unit values prior to running non-linear estimation of Armington elasticity
*assumption: cost shocks to the economy are absorbed relatively quickly: use 1-2-3 lags

****************************************
*set directory*
****************************************
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
	cd "$dir/Data_Interm/Third_Part/"

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
	if strmatch("`c(username)'","*daudin*")==1 {
		use "$dir/Data/For Third Part/prepar_cepii_`year'", clear
	}
	if "`c(hostname)'" =="LAmacbook.local" {
		use prepar_cepii_`year', clear
	}
	
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
	
	
	use temp_`year', clear
	save temp_mod_`year', replace
	
	
	local i=1
	
	if `year' == 1963 local laglist 1
	if `year' == 1964 local laglist 1/2
	if `year' >= 1965 local laglist 1/3
	
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
	if strmatch("`c(username)'","*daudin*")==1 {
		joinby iso_o year using "$dir/Data_Interm/Third_Part/PWT/tmp_pwt90_`year'", unmatched(master)
	}
	if "`c(hostname)'" =="LAmacbook.local" {
		joinby iso_o year using "tmp_pwt90_`year'", unmatched(master)
	}
	drop _merge
	save temp_mod_`year', replace
end



***********************************************************
*run different specifications: save coefs and std errors 
***********************************************************
capture program drop first_stage_instr
program first_stage_instr
	syntax, year(integer) liste_instr(string) /*instr*/

	*years: 1963-2013
	*instr: x
	*exemple : first_stage_instr, year(1965) liste_inst(x)
	
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

	if `year' == 1963 local laglist 1
	if `year' == 1964 local laglist 1/2
	if `year' >= 1965 local laglist 1/3
	
	
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


*PROGRAMS FIRST STAGE:

foreach n of numlist 1962/2013 {
	calc_ms `n'
}



foreach n of numlist 1963/2013 {
	prep_instr `n'
}



local liste_instr gdpo i

foreach year of numlist 1963/2013 {
	local k 1
	 foreach instr of local liste_instr {
	
		first_stage_instr, year(`year') liste_instr(`instr')
		if strmatch("`c(username)'","*daudin*")==1 {
			if `k'!=1 merge 1:1  iso_d-ln_uv using "$dir/Résultats/Troisième partie/first_stage_`year'.dta"
			if `k'!=1 drop _merge
			save "$dir/Résultats/Troisième partie/first_stage_`year'.dta", replace
		}
		if "`c(hostname)'" =="LAmacbook.local" {
			if `k'!=1 merge 1:1  iso_d-ln_uv using "first_stage_`year'.dta"
			if `k'!=1 drop _merge
			save "first_stage_`year'.dta", replace
		}
		local k = `k'+1
	}
}




