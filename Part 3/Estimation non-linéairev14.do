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
*on my laptop:
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*cd "$dir\SITC_Rev1_adv_query_2011"
*GD
global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
cd "$dir"


****************************************************************************************************************************************************************
capture log using "logs/`c(current_time)' `c(current_date)'"
timer clear 1
timer on 1



****************************************
*Calcul market share et prix
****************************************

*"prep_`type'_`year'.dta" files store for each sample 
capture program drop calc_ms
program calc_ms
args sample year
*e.g. calc_ms prepar_full 1970


*capture erase "$dir/ms"

display "`year'"

/*On va chercher les données*/
use "$dir/Data/For Third Part/`sample'_`year'", clear
drop if iso_o==iso_d
drop if value_`year'==0

*keep if iso_d=="USA"

/*Pour pouvoir jouer avec plus tard*/
tostring product, gen(sitc4) usedisplayformat


generate prod_unit = sitc4+"_"+qty_unit


*****Fillin : pas indispensable ici ?
/*
fillin prod_unit iso_o iso_d year
replace value_`year'=0 if _fillin==1
replace uv_`year'=. if _fillin==1
bys iso_d iso_o : egen tot_fillin=total(_fillin)
bys iso_d iso_o :drop if tot_fillin==_N
drop _fillin tot_fillin
*/

*bys iso_d iso_o : egen uv_presente = total(uv_`year')
generate uv_presente= uv_`year'
drop if uv_presente==0



save "$dir/temp_`year'", replace
end 


********************************************************************
********************************************************************
********************************************************************
********************************************************************
********************************************************************



**********************************************************************

program nlnonlin
	version 12
	su group_iso_o, meanonly	
	local nbr_iso_o=r(max)
	local nbr_var=`nbr_iso_o'+2
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iweight], at(name)
	local lnms_pays : word 1 of `varlist'
	local uv_presente : word 2 of `varlist'


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
		replace  `pour_index_prix_sect_pays' = `fe_iso_o'*(uv_presente)^(1-`sigma') if iso_o_`i'!=0
	}
	
	
	egen double `blouk' = total(`pour_index_prix_sect_pays'), by (iso_d prod_unit)
/*
	generate double `index_prix_sect_pays' = `blouk'^(1/(1-`sigma'))
	generate double `prix_rel' = uv_presente/ `index_prix_sect_pays'
	generate double `sect_share_pond'= ms_secteur * `prix_rel'^(1-`sigma')

*/
	generate double `sect_share_pond'= ms_secteur *(uv_presente)^(1-`sigma')/ `blouk'
	*collapse (sum) `sum'=`sect_share_pond',by (iso_d iso_o* `lnms_pays' `fe_iso_o')
	
	
	egen double `sum'=total(`sect_share_pond'),by (iso_d iso_o)


	*bys iso_d iso_o : keep if _n==1


	foreach i of num 1 / `nbr_iso_o' {
		replace  `lnms_pays' = ln(`fe_iso_o'*`sum') if iso_o_`i'!=0
	}
	
	

*	tempvar blik blif
*	generate `blik'=exp(`lnms_pays')
*	egen `blif' = total(`blik'), by(iso_d)
*	replace `lnms_pays'=ln(1-`blif') if iso_o_1==1
	***autre solution : ne pas traiter le pays 1 de manière spéciale, mais tout multiplier par le scalaire nécessaire pour que la somme soit 1 ?
*	replace `lnms_pays'=`lnms_pays'-ln(`blif')
	
	
end


capture program drop reg_nlin
program reg_nlin
	args year
*exemple : reg_nlin 2009
timer clear 2
timer on 2
 
	use "$dir/temp_`year'", clear
	
	***Pour restreindre
	*keep if substr(prod_unit,1,1)=="0"
	*************************
	
	bys prod_unit iso_d: egen c_95_uv = pctile(uv_presente),p(95)
	bys prod_unit iso_d: egen c_05_uv = pctile(uv_presente),p(05)
	bys prod_unit iso_d: egen c_50_uv = pctile(uv_presente),p(50)
	drop if uv_presente < c_05_uv | uv_presente > c_95_uv
	drop if uv_presente < c_50_uv/100 | uv_presente > c_50_uv*100
	
	
	***Pour faire un plus petit sample
	*En ne gardant que 10 ou 20% des produits et des pays
/*	local limite 50
	bys prod_unit : egen total_product = total(value_`year')
	bys iso_d : egen total_iso_d = total(value_`year')
	bys iso_o : egen total_iso_o = total(value_`year')
	
	egen threshold_product = pctile (total_product),p(`limite')
	egen threshold_iso_d = pctile (total_iso_d),p(`limite')
	egen threshold_iso_o = pctile (total_iso_o),p(`limite')
	
	
	drop if total_iso_d <= threshold_iso_d
	drop if total_iso_o <= threshold_iso_o
	drop if total_product <= threshold_product
	
	drop total_product total_iso_d total_iso_o  threshold_product threshold_iso_d threshold_iso_o 
	
	codebook prod_unit iso_o iso_d
	
*/
	
	
	*****Calcul des ms
	*Par pays expt chez un import
	rename value_`year' value
	bys iso_d : egen tot_import=total(value)
	bys iso_d iso_o : egen tot_import_export = total(value)
	bys iso_o : egen tot_export = total(value)
	egen tot_trade = total(value)
	*Market share d'un pays par destination 
	generate ms_pays = tot_import_export / tot_import
	generate lnms_pays = ln( tot_import_export / tot_import)
	
	*Par exportateur dans de commerce mondial
	generate ms_tot = tot_export/tot_trade

	*On enlève les tout petits exportateurs
	drop if ms_tot < (1/1000)
	drop tot_import tot_trade
	bys iso_d : egen tot_import=total(value)
	egen tot_trade = total(value)
	replace ms_tot = tot_export/tot_trade
	


	*Par secteur chez un importateur
	bys iso_d prod_unit : egen tot_import_secteur = total(value)
	generate ms_secteur = tot_import_secteur / tot_import

	
	
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
bys iso_d iso_o	: replace weight = value/_N
*Cela de manière 
	
*	nl nonlin @ ms_pays prix_rel_5 ms_secteur_5 `liste_variables_iso_o', eps(1e-3) iterate(100) parameters(sigma `liste_parametres_iso_o' ) initial(sigma 1.5 `initial_iso_o')
	display "nl nonlin @ lnms_pays uv_presente `liste_variables_iso_o' [iweight=value], iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')"
*	nl nonlin @ lnms_pays uv_presente `liste_variables_iso_o', iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')
	nl nonlin @ lnms_pays uv_presente `liste_variables_iso_o' [iweight=weight], iterate(100) parameters(lnsigmaminus1 `liste_parametres_iso_o' ) initial(lnsigmaminus1 `startlnsigmaminus1' `initial_iso_o')
	
	
	
	
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
	
	timer off 2
	timer list 2
	generate time=r(t2)
	generate ordinateur="Lysandre"
	drop iso_o_*
		
	save "$dir/temp_`year'_result", replace
	keep if _n==1
	keep rc converge R2 sigma_est ecart_type_lnsigmaminus1
	append using "$dir/temp_result"
	save "$dir/temp_result", replace
	

	
end

*calc_ms prepar_full 1970
*calc_ms prepar_full 1990	
*reg_nlin 1970
*reg_nlin 1990

*blouk

*********************************Lancer les programmes
clear
set obs 1
gen year=.
capture save "$dir/temp_result"
foreach year of num 1962(2)1980 {
	display "`year'"
	display
	calc_ms prepar_full `year'
	reg_nlin `year'
*	erase "$dir/temp_`year'_result.dta"
	erase "$dir/temp_`year'.dta"
}
	

*twoway (line coef_sigma year, sort) (qfit coef_sigma year, sort)
*twoway (line coef_sigma year, sort) (lfit coef_sigma year, sort)


timer off 1
timer list 1


log close	




