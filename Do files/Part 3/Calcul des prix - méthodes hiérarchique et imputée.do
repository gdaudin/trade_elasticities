/* 
Change in 2018 : mainly vocabulary / directory change
The "imputed" method is not very interesting



v1 GD October 20, 2011
Based on estim_elast_aggrLA.v1.1.do
Two changes :
- We keep only programming relevant to relative price computation
- The price computation is hierarchical. We first compute price at the 4 aggreg level (ie. mixing different quantity units). And then we use that to compute it at the level-3 aggreg, then level-2 aggreg, etc...
In the preceeding .do, the aggregation at level 2 was done directly from the smallest existing aggregation.
*/


/*
******************
****This file uses "prep(ar)_`type'_`year'.dta files  where `type' is "full", "sq_list1962", "sqrecip_list" to construct "s`sitc'_`type'_`year'.dta" which store at each aggregation level by iso_o iso_d: tot_trade of iso_o in this iso_d across all subcategories in this product and tot_trade of dest across all sources and subcategories of this product whether or not uv is observed in each subcategory where `sitc' is 4, 3, 2, 1
[That is program ms_aggr]"
*GD: I am not sure why that is helpful.
When the market share is not "effective", the one attributed should be the straight, observed, one.


******************
****This file also uses "prep(ar)_`type'_`year'.dta files to construct at each aggregation level
**the weighted average price for all products in this `sitc'-level category, aggregated to comp_good relative price
"s`sitc'_relprice_`type'_`year'.dta"
**this means that for products where trade is observed but uv is not observed, existing weighted mean price is applied 
**but this also means that for products where uv and trade are not observed, existing weighted mean price is applied without imputing trade



*/



****************************************
*set directory*
****************************************

****************************************
*set directory*
****************************************
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/2007 OFCE Substitution Elasticities local"

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


****************************************************************************************************************************************************************

****************************************
*prepare files at each aggregation level*
****************************************
*"prep_`type'_`year'.dta" files store for each sample 
capture program drop prepar_price
program prepar_price
args year sample

*e.g. prepar_price 1962 prepar_full


use "$dir/Data/For Third Part/prepar_`sample'_`year'", clear
drop if iso_o==iso_d
drop if value_`year'==0

/***keep one flow per source-destination-product combination 
**no matter whether there is uv, one or several quantity units
format product %04.0f
*/



**********************************************************************
*******construct sectoral prices by destination by product*qty_unit only for ********existing uv and representative uv coverage


*********First, do the representative uv coverage
/*
keeping only representative uv (share_taken>.5, no uv imputation)
the variable share_taken indicates how much of total value is included in the sectoral price
*uv_`year': uv by product*qty_unit for country iso_o in country iso_d 
*value_`sample': trade value by product*qty_unit for country iso_o in country iso_d

*" tot_value_`i': total imports by destination by product*quantity unit 
*/

by iso_d product qty_unit, sort: egen tot_value_`year'=total(value_`year')

/*"tot_value_uv_`i': total imports by destination by product*quantity unit, where only obs. with existing uv taken into account after uv imputation */

by iso_d product qty_unit, sort: egen tot_valueuv_`year'=total(value_`year') if uv_`year'!=.

/*share_taken: tells how much of any product*qty_unit combination is accounted for by non-imputed uv */

gen double share_taken=tot_valueuv_`year'/tot_value_`year' if qty_unit!="N.Q."

/*share_unit: share of each qty_unit within each product*destination*/
by iso_d product, sort: egen tot_prod_dest_`year'=total(value_`year')

gen double share_unit=tot_value_`year'/tot_prod_dest_`year'

/*share_unit is always equal to 1 in 1962-1991 which means that for a given destination, all trade in this product is 
measured in the same qty_unit with all partners but not in 1992, nor in 2000-2009: for same destination sometimes a lot in N.Q., 
sometimes some value in another measurement unit I drop those where share of N.Q. >.75 of total destination imports in that product */
/*qty_token est l'unité de quantité*/

preserve
keep if share_taken==. 
keep if qty_token==1 & share_unit>.75
by iso_d product, sort: drop if _n!=1
keep iso_d product
gen holder=0
save tmp_unit, replace
restore
joinby iso_d product using tmp_unit, unmatched(both)
assert _merge!=2
drop _merge
drop if holder==0
drop holder
drop share_unit
erase tmp_unit.dta

/*I drop those where share_taken<.2 (sectoral price would not be representative)*/

drop if share_taken<.2
drop share_taken
**check that there is no uv when qty_token==1
drop if uv_`year'!=. & qty_token==1
drop if uv_`year'==.
**sectoral prices by product*qty_unit are constructed using uv in raw data file (no imputation)

****************
**compute relative and mean price at max disaggregation
********************

**this variable gives share of each exporter within each product*qty_unit where *uv is available
/*Puis cela sert à mesure le prix moyen product*qty_unit*/
gen double uv_share=value_`year'/tot_valueuv_`year'
replace uv_share=uv_`year'*uv_share
by iso_d product qty_unit, sort: egen sect_price_`year'=total(uv_share) 
drop uv_share

**relative price by product*qty_unit (ou agrégation "5")
gen double rel_price_5=uv_`year'/sect_price_`year'


save "$dir/Résultats/Troisième partie/Prix calculés/prepar_prix_`sample'_`year'", replace

end

********************************************************************************



*******************
**compute aggregated prices using relative price with hierarchical method
********************

capture program drop rel_price_aggr
program rel_price_aggr
args year 

*e.g. rel_price_agg 1962

use "$dir/Résultats/Troisième partie/Prix calculés/prepar_prix_`sample'_`year'", clear

/*Pour pouvoir jouer avec plus tard*/
tostring product, gen(sitc4) usedisplayformat

/*Calcul de tot_dest_trade by sitc_agg`agg' included in computation of relative price*/
by iso_d product qty_unit, sort: egen tot_value_`year'_agg5=total(value_`year')
foreach agg of numlist 0(1)4 {
	/*Identifier les biens de la même agrégation*/
	gen sitc_agg`agg'=substr(sitc4,1,`agg')
	by iso_d sitc_agg`agg', sort: /*
	*/ egen tot_value_`year'_agg`agg'=total(value_`year')
}



save temp_pour_calcul_prix_relatifs_A, replace

foreach agg of numlist 4(-1)0 {

	/*Identifier l'agrégation précédente (par uv si `agg'==4)*/
	local agg_before = `agg'+1

	/*Un premier collapse pour calculer le prix relatif par produit (agg) / origi / destination*/
	collapse tot_value_`year'_agg`agg' (mean)/* 
		*/rel_price_`agg_before'/*
		*/[iw=tot_value_`year'_agg`agg_before'], /*
		*/by(iso_o iso_d sitc_agg0-sitc_agg`agg')
	rename rel_price_`agg_before' rel_price_`agg'
	save temp_pour_calcul_prix_relatifs_B, replace
	preserve


	/*Puis un deuxième collapse pour calculer le prix relatif agrégé par origine / destination (pas par produits !)*/
	collapse (mean) rel_price_`agg' [iw=tot_value_`year'_agg`agg'],/*
	*/by(iso_o iso_d) 
	save temp_pour_calcul_prix_relatifs_result_agg`agg', replace
	restore
}

/*Puis on merge les données calculées pour chaque niveau d'agrégation*/
use  temp_pour_calcul_prix_relatifs_result_agg4, clear
foreach agg of numlist 3(-1)0 {
	merge 1:1 iso_o iso_d using /*
	*/ temp_pour_calcul_prix_relatifs_result_agg`agg'
*	erase "temp_pour_calcul_prix_relatifs_result_agg`agg'"	
	drop _merge
}

/*Et on sauve le fichier final pour cette année*/
generate year= `year'
*erase temp_pour_calcul_prix_relatifs_A
*erase temp_pour_calcul_prix_relatifs_B
save "$dir/Résultats/Troisième partie/Prix calculés/Prix calculés par stepwise_`sample'_`year'", replace

end

************************************************************


*******************
**compute aggregated prices using imputed prices
********************

capture program drop rel_price_imput
program rel_price_imput
args year hypo

*e.g. rel_price_imput 1962 100 where the imputed price is 100 times the mean price

use "$dir/Résultats pour la 3e partie/Prix relatifs/Prix relatifs_`sample'_`year'", clear


/*Je développe le cube pour pouvoir y mettre tous les prix imputés, mais je le fais pays destination par pays destination*/

/*Vallist prend la liste des valeurs de iso_d. Puis on fait une boucle sur ces valeurs, avec fillin pour sortir les zéros*/

vallist iso_d
capture erase "$dir/Blouk_`year'_`hypo'"
foreach pays_dest in `r(list)' {
	use "$dir/Résultats pour la 3e partie/Prix relatifs/Prix relatifs_`sample'_`year'",/*
	*/clear
	/*Je fais un fillin pour que tous les secteurs où les importateurs n'ont pas de prix apparaissent*/
	keep iso_o iso_d product qty_unit value_`year' rel_price_5
	keep if iso_d=="`pays_dest'"
	fillin iso_o iso_d product qty_unit
	
	/*Je fais l'hypothèse sur les prix*/
	/*Je rajoute qqch pour compter le nbr de zéros*/
	gen pour_compter = 1
	gen pour_compter_0 = 1 if rel_price==.
	replace rel_price_5=`hypo' if rel_price==.
	

	/*Je calcule les poids destination (commerce total par secteur)*/
	by iso_d product qty_unit, sort: egen tot_value_`year'=total(value_`year')
	
	/*Puis je collapse pour calculer la moyenne*/
	/*Puis je calcul les prix relatifs par origine par un collapse*/
	collapse (mean) rel_price_5/*
		*/[iw=tot_value_`year'], /*
		*/by(iso_o iso_d)
	
	
	/*J'appende au fichier existant*/
	capture append using "$dir/Blouk_`year'_`hypo'"
	save "$dir/Blouk_`year'_`hypo'", replace
	display "`pays_dest'" " `year'" " `hypo'"
	}
	
rename rel_price_5 rel_price_imput_`hypo'

generate year = `year'

save "$dir/Résultats pour la 3e partie/Prix relatifs/Prix relatifs par imputation_`sample'_`year'_imput`hypo'", replace
capture erase "$dir/Blouk_`year'_`hypo'"

end

************************************************************

/*

************************************************************************************
********************
**compute aggregated prices using imputed prices after some aggregation
********************

capture program drop rel_price_aggr_imput
program rel_price_aggr_imput
args year hypo_imput

/*e.g. rel_price_aggr_imput 1962 100 where the imputed price is 100 times the mean price*/

use "$dir/Résultats pour la 3e partie/Prix relatifs/Prix relatifs_`sample'_`year'", clear


/*Je commence par calculer par agrégation*/

/*Pour pouvoir jouer avec plus tard*/
tostring product, gen(sitc4) usedisplayformat


/*Calcul de tot_dest_trade by sitc_agg`agg' included in computation of relative price*/
by iso_d product qty_unit, sort: egen value_`year'_agg5=total(value_`year')
foreach agg of numlist 0(1)4 {
	/*Identifier les biens de la même agrégation*/
	gen sitc_agg`agg'=substr(sitc4,1,`agg')
	by iso_d iso_o sitc_agg`agg', sort: /*
	*/ egen value_`year'_agg`agg'=total(value_`year')
}

save temp_pour_calcul_prix_relatifs_A, replace

/*Ce bout-là calcule les prix relatifs par produits * destination*origine pour les différents niveaux d'agrégation*/

foreach agg of numlist 4(-1)0 {


	/*Identifier l'agrégation précédente (par uv si `agg'==4)*/
	local agg_before = `agg'+1

	/*Un premier collapse pour calculer le prix relatif par produit (agg) / origi / destination*/
	collapse (mean) rel_price_`agg_before'/*
		*/[iw=value_`year'_agg`agg_before'], /*
		*/by(iso_o iso_d sitc_agg0-sitc_agg`agg' /*
		*/ value_`year'_agg0-value_`year'_agg`agg')
	rename rel_price_`agg_before' rel_price_`agg'
	
	save temp_pour_calcul_prix_relatifs_`agg', replace
}

/*Puis on merge les données calculées pour chaque niveau d'agrégation*/
/*Contrairement au programme de base, on garde les chiffres */
use  temp_pour_calcul_prix_relatifs_4, clear
foreach agg of numlist 3(-1)0 {
	merge m:1 iso_o iso_d sitc_agg`agg' using /*
	*/ temp_pour_calcul_prix_relatifs_`agg'
*	erase "temp_pour_calcul_prix_relatifs_result_agg`agg'"	
	drop _merge
}

/*Et on sauve le fichier final pour cette année*/
generate year= `year'
*erase temp_pour_calcul_prix_relatifs_A
*erase temp_pour_calcul_prix_relatifs_B
save "$dir/temp_double_méthode_`year'", replace




/*Ce bout-çi calcule les prix avec imputation par fillin pour chaque niveau d'agrégation (à partir de 3*/

/*Je développe le cube pour pouvoir y mettre tous les prix imputés, mais je le fais pays destination par pays destination*/

/*Vallist prend la liste des valeurs de iso_d. Puis on fait une boucle sur ces valeurs, avec fillin pour sortir les zéros*/

use "$dir/temp_double_méthode_`year'", clear
vallist iso_d


capture erase "$dir/Blouk_`year'_aggall_imput`hypo_imput'.dta"

foreach agg of numlist 3(-1)0 {
	display "`agg'"
	local agg_before=`agg'+1
	capture erase "$dir/Blouk_`year'_agg`agg'_`hypo_imput'.dta"
	use "$dir/temp_double_méthode_`year'", clear
	vallist iso_d
	foreach pays_dest in `r(list)' {
		use "$dir/temp_double_méthode_`year'", clear				
		bysort iso_o iso_d sitc_agg`agg_before': keep if _n==1
		/*Je fais un fillin pour que tous les secteurs où les importateurs n'ont pas de prix apparaissent*/
		keep iso_o iso_d sitc_agg`agg_before' /*
		*/rel_price_`agg_before' /*
		*/value_`year'_agg`agg_before'
		keep if iso_d=="`pays_dest'"
		fillin iso_o iso_d sitc_agg`agg_before'
	
		/*Je fais l'hypothèse sur les prix*/
		replace rel_price_`agg_before'=`hypo_imput'/*
		*/ if rel_price_`agg_before'==.
	
		/*Je calcule les poids destination*/
		bysort iso_d sitc_agg`agg_before' : egen /*
		*/ tot_value_`year'_agg`agg_before'/*
		*/ = total(value_`year'_agg`aggbefore')
	
	
		/*Puis je calcul les prix relatifs par origine par un collapse*/
		collapse (mean) rel_price_`agg_before'/*
			*/[iw=tot_value_`year'_agg`agg_before'], /*
			*/by(iso_o iso_d)
		rename rel_price_`agg_before' /*
		*/ rel_price_agg`agg'_imput`hypo_imput'
		
		
		/*J'appende au fichier existant*/		
		capture append using "$dir/Blouk_`year'_agg`agg'_`hypo_imput'"
		save "$dir/Blouk_`year'_agg`agg'_`hypo_imput'", replace
		display "`pays_dest'" " `year'" " `hypo'" " `agg'"
	}

capture merge 1:1 iso_d iso_o /*
*/using "$dir/Blouk_`year'_aggall_imput`hypo_imput'.dta"
capture drop _merge
save "$dir/Blouk_`year'_aggall_imput`hypo_imput'", replace

}


generate year = `year'
save "$dir/Blouk_`year'_aggall_imput`hypo_imput'", replace


end








*/





************************************************************
***Fait tourner les programmes
************************************************************



foreach year of num 1962/*(1)2013*/ {
	prepar_price `year' cepii
}



/*





foreach year of num 1995/*(1)2016*/ {
	prepar_price `year' baci
}


foreach year of num 1995/*(1)2016*/ {
	rel_price_aggr `year' baci
}





foreach year of num 1962/*(1)2013*/ {
	prepar_price `year' cepii
}




*foreach year of num 1962(1)2009 {
*	rel_price_aggr `year' prepar_full
*	capture append using "$dir/Résultats pour 3e partie/Prix relatifs par agrégation hiérarchique"
*	save "$dir/Résultats pour 3e partie/Prix relatifs par agrégation hiérarchique", erase "$dir/Prix relatifs par imputation_`year'_imput`hypo'"
*}

*foreach year of num 1962(1)2009 {
*	local hypothese 50
*	rel_price_imput `year' `hypothese' 
*	capture append using "$dir/Prix relatifs par imput_`hypothese'"
*	save "$dir/Prix relatifs par imput_`hypothese'", replace
*	capture erase 
*}


*foreach year of num 1962(1)2009 {
* 	local hypothese 5
*	rel_price_aggr_imput `year' `hypothese'
*}

*foreach year of num 1962(1)2009 {
*	local hypo 5
*	use "$dir/Blouk_`year'_aggall_imput`hypo'", replace
*	if `year' != 1962 {
*		append using "$dir/Prix relatifs par imput_`hypo' et agregation"
*	}
*	save "$dir/Prix relatifs par imput_`hypo' et agregation", replace
*	capture erase "$dir/Blouk_`year'_aggall_imput`hypo'.dta"
*}


