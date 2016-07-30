*10/09/2015 LA
*This file adapts "estimation non lineaire.do" to run instrumented nonlinear specification on basis of predicted unit values
*using lagged unit values and changes in price levels
**
*first constructs predicted unit values for some specification of lagged variables
*second constructs market share and prepares data for non-linear regression
*third runs non-linear estimation of sigma

*22/01/2013 Guillaume Daudin
*v2 : 14/08/2013
*v3 : 27/08/2014
*	- j'enlève le calcul de prix du programme calc_ms_prix, que du coup j'appelle calc_ms
*Je normalise les ef

*Calcul de l'estimation non-linéaire
*À partir de "Calcul ms et estimationsv2.do"

*A FAIRE : vérifier s'il n'y a pas une erreur dans le calcul des prix relatifs (niveau 4, 3, 2...)
*METTRE DES EFFETS FIXES EXPORTATEURS



****************************************
*set directory*
****************************************
clear all
set mem 2g
set matsize 800
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




****************************************************************************************************************************************************************
capture log using "logs/`c(current_time)' `c(current_date)'"
timer clear 1
timer on 1




********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************

*/
**********************************************************************
*This part modified: effective ms and sectoral expdtre; predicted uv 
**********************************************************************

**********************************************************************

program nlnonlin
*args year instr spec lag
	version 12
	su group_iso_o, meanonly	
	local nbr_iso_o=r(max)
	local nbr_var=`nbr_iso_o'+2
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iweight], at(name)
*	local lnms_pays : word 1 of `varlist'
*	local uv_presente : word 2 of `varlist'
	local lnms_pays: word 1 of `varlist'
	local pred_uv : word 2 of `varlist'


	tempvar pour_index_prix_sect_pays blouk index_prix_sect_pays prix_rel sect_share_pond sum sigma


	
	tempname lnsigmaminus1
	scalar `lnsigmaminus1' = `at'[1,1]
	generate double `sigma' = exp(`lnsigmaminus1')+1
	
	tempvar fe_iso_o
*	generate double `fe_iso_o' =1 if iso_o_1==1
	generate double `fe_iso_o' =.
	
	local n=2
	foreach i of num 1 / `nbr_iso_o' {
		tempname lnfe_iso_o_`i'
		scalar `lnfe_iso_o_`i''=`at'[1,`n']
*		local blouk = `lnfe_iso_o_`i''
*		display "`blouk'"
		local n = `n'+1
		replace `fe_iso_o'=exp(`lnfe_iso_o_`i'') if iso_o_`i'==1
	}
	
	
	
	
	generate double `pour_index_prix_sect_pays' =0

	
	foreach i of num 1 / `nbr_iso_o' {
*		replace  `pour_index_prix_sect_pays' = `fe_iso_o'*(uv_presente)^(1-`sigma') if iso_o_`i'!=
		replace  `pour_index_prix_sect_pays' = `fe_iso_o'*(pred_uv)^(1-`sigma') if iso_o_`i'!=0
	}
	
	
	egen double `blouk' = total(`pour_index_prix_sect_pays'), by (iso_d prod_unit)
/*
	generate double `index_prix_sect_pays' = `blouk'^(1/(1-`sigma'))
	generate double `prix_rel' = uv_presente/ `index_prix_sect_pays'
	generate double `sect_share_pond'= ms_secteur * `prix_rel'^(1-`sigma')

*/
*	generate double `sect_share_pond'= ms_secteur *(uv_presente)^(1-`sigma')/ `blouk'
	generate double `sect_share_pond'= ms_secteur *(pred_uv)^(1-`sigma')/ `blouk'
	
	*collapse (sum) `sum'=`sect_share_pond',by (iso_d iso_o* `lnms_pays' `fe_iso_o')
	
	
	egen double `sum'=total(`sect_share_pond'),by (iso_d iso_o)


	*bys iso_d iso_o : keep if _n==1


	foreach i of num 1 / `nbr_iso_o' {
*		replace  `lnms_pays' = ln(`fe_iso_o'*`sum') if iso_o_`i'!=0
		replace `lnms_pays' = ln(`fe_iso_o'*`sum') if iso_o_`i'!=0
	}
	
	

*	tempvar blik blif
*	generate `blik'=exp(`lnms_pays')
*	egen `blif' = total(`blik'), by(iso_d)
*	replace `lnms_pays'=ln(1-`blif') if iso_o_1==1
	***autre solution : ne pas traiter le pays 1 de manière spéciale, mais tout multiplier par le scalaire nécessaire pour que la somme soit 1 ?
*	replace `lnms_pays'=`lnms_pays'-ln(`blif')
	
	
end












*************************************************************************
*modifie: adjusted to instrumented specification
*************************************************************************

capture program drop reg_nlin
program reg_nlin
*	args year
*exemple : reg_nlin 
args year instr /*spec*/ lag
*exemple: reg_nlin 2009 gdpo /*baseline*/ 3
timer clear 2
timer on 2
 
*	use "$dir/temp_`year'", clear
	use "$dir/Résultats/Troisième partie/first_stage_`year'.dta", clear
	generate pred_uv=exp(ln_uv_instr_`instr'_`lag'lag)
	

	
	***Pour restreindre
	*keep if substr(prod_unit,1,1)=="0"
	*************************
**taken away: all data cropping done prior to instrumenting
*	bys prod_unit iso_d: egen c_95_uv = pctile(uv_presente),p(95)
*	bys prod_unit iso_d: egen c_05_uv = pctile(uv_presente),p(05)
*	bys prod_unit iso_d: egen c_50_uv = pctile(uv_presente),p(50)
*	drop if uv_presente < c_05_uv | uv_presente > c_95_uv
*	drop if uv_presente < c_50_uv/100 | uv_presente > c_50_uv*100
	
	/*
	***Pour faire un plus petit sample
	*En ne gardant que 10 ou 20% des produits et des pays
	local limite 50
	bys prod_unit : egen total_product = total(value)
	bys iso_d : egen total_iso_d = total(value)
	bys iso_o : egen total_iso_o = total(value)
	
	egen threshold_product = pctile (total_product),p(`limite')
	egen threshold_iso_d = pctile (total_iso_d),p(`limite')
	egen threshold_iso_o = pctile (total_iso_o),p(`limite')
	
	
	drop if total_iso_d <= threshold_iso_d
	drop if total_iso_o <= threshold_iso_o
	drop if total_product <= threshold_product
	
	drop total_product total_iso_d total_iso_o  threshold_product threshold_iso_d threshold_iso_o 
	
	codebook prod_unit iso_o iso_d
	
	
	*/
	***********
	
	
	


	
	
	
	**************
	egen group_iso_o=group(iso_o)
	quietly tabulate iso_o, gen(iso_o_)
	su group_iso_o, meanonly	
		local nbr_iso_o=r(max)
	egen group_prod=group(prod_unit)
	
	
	local startlnsigmaminus1 2
	
	
	local liste_variables_iso_o
	local liste_parametres_iso_o 
	local initial_iso_o
	capture su ms_tot if iso_o_1==1
	local ms_iso_1=r(mean)
	forvalue j =  1/`nbr_iso_o' {
			local liste_variables_iso_o  `liste_variables_iso_o' iso_o_`j'
			local liste_parametres_iso_o  `liste_parametres_iso_o' lnfe_iso_o_`j'
			capture su ms_tot if iso_o_`j'==1
			local fe_init = r(mean)
*			local lnfe_init=ln((`fe_init'/`ms_iso_1')^exp(`startlnsigmaminus1'))
*			L'idée ici est de normaliser les effets fixes
*			Faisons plus simple
			local lnfe_init = ln(`fe_init')
			
			local initial_iso_o  `initial_iso_o' lnfe_iso_o_`j' `lnfe_init'			
	}

	
display "`initial_iso_o'"
gen weight=0
bys iso_d iso_o	: replace weight = 1/_N
*Cela de manière 
	
*	nl nonlin @ ms_pays prix_rel_5 ms_secteur_5 `liste_variables_iso_o', eps(1e-3) iterate(100) parameters(sigma `liste_parametres_iso_o' ) initial(sigma 1.5 `initial_iso_o')
*	display "nl nonlin @ lnms_pays uv_presente `liste_variables_iso_o' [iweight=value], iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')"
	display "nl nonlin @ lnms_pays pred_uv `liste_variables_iso_o' [iweight=value], iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')"
*	nl nonlin @ lnms_pays uv_presente `liste_variables_iso_o', iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')
*	nl nonlin @ lnms_pays uv_presente `liste_variables_iso_o' [iweight=weight], iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')
	nl nonlin @ lnms_pays pred_uv `liste_variables_iso_o' [iweight=weight], iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')
	
	
	
	
**ln(.5)=-0.7

	capture predict lnms_pays_predict
	capture	generate rc=_rc
	capture	generate converge=e(converge)
	capture generate R2 = e(r2)
	capture	matrix X= e(b)
	capture matrix ET=e(V)
	local nbr_var = e(k)/2
	

	
	quietly generate sigma_est =X[1,1]
	replace sigma_est = exp(sigma)+1
	quietly generate ecart_type_lnsigmaminus1 =ET[1,1]^0.5
	generate date = "`c(current_time)' `c(current_date)'"
	
	
	timer off 2
	timer list 2
	generate time=r(t2)
	
	
if strmatch("`c(username)'","*daudin*")==1 {
	generate ordinateur="Lysandre"
}


if "`c(hostname)'" =="ECONCES1" {
	generate ordinateur = "Leuven"
}


	drop iso_o_*
		
*	save "$dir/temp_`year'_result", replace
	save "$dir/temp_`instr'_`lag'_`year'_result", replace

	keep if _n==1
	keep rc converge R2 sigma_est ecart_type_lnsigmaminus1 year ordinateur date time
*	append using "$dir/temp_result"
*	save "$dir/temp_result", replace
	append using "$dir/temp_`instr'_`lag'_result"
	save "$dir/temp_`instr'_`lag'_result", replace
*	erase "$dir/temp_`instr'_`lag'_`year'_result.dta"
*	clear	

	
end
*instr_set i baseline 2
*instr_set i combined 2
*instr_uv 1970 i baseline 2
*instr_uv 1970 i combined 2
*reg_nlin 1970 i baseline 2

*not needed* calc_ms prepar_full 1970
*not needed* calc_ms prepar_full 1990	
*reg_nlin 1970
*reg_nlin 1990

*blouk

*********************************Lancer les programmes
clear
set obs 1
gen year=.
*capture save "$dir/temp_result"
local which gdpo /*i k*/
*local what baseline /*combined*/
local lags 3
foreach instr of local which {
	foreach lag of local lags {
	clear
	gen rc=.
	capture save "$dir/temp_`instr'_`lag'_result.dta"
*	foreach spec of local what {
		foreach year of num 1966(1)2011 {
			display "`year' `instr' `lag'"
*	display "`year'"
*	display
*			instr_set `instr' `spec' `lag'
*			instr_uv `year' `instr' `spec' `lag'
			reg_nlin `year' `instr' `lag'
*	calc_ms prepar_full `year'
*	reg_nlin `year'
*	erase "$dir/temp_`year'_result.dta"
*	erase "$dir/temp_`year'.dta"
	*capture	erase temp_`spec'_`instr'_`lag'_`year'.dta
	*		erase tmp_`spec'_`lag'.dta
		}
	}	
}
	

generate one_minus_sigma = 1-sigma_est	
twoway (line one_minus_sigma year, sort) (qfit one_minus_sigma year, sort)
twoway (line one_minus_sigma year, sort) (lfit one_minus_sigma year, sort)


timer off 1
timer list 1


*log close	
capture log close

**specifications effectively used: 1965-2011, instr: gdpo and i; lag 2 for combined; lag 2 and 3 for baseline

