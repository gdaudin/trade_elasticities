
version 11
/*GD 27/10/2011*/
/*Ce programme compte le nombre de produits sans prix par rapport à ceux qui ont des prix*/
/*À différents niveaux d'agrégation*/
/*Rq : on pourrait aussi le faire % au commerce total ?*/

clear all
set mem 500M
set matsize 800
set more off
*on my laptop:
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*GD

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities local"
	cd "$dir/Data/For Third Part/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}


*******************
**Pour compter les zero
********************


capture program drop compter_zeros
program compter_zeros
args year

/*eg compter_zeros 1962*/




/*Je développe le cube pour pouvoir y mettre tous les zéros, mais je le fais pays destination par pays destination*/

/*Vallist prend la liste des valeurs de iso_d. Puis on fait une boucle sur ces valeurs, avec fillin pour sortir les zéros et les autres variables d'intérêt*/
/*Avant, je rend tous les niveaux d'agrégation comparables*/




foreach agg of num 5(-1)1 {
	use "$dir/Data/For Third Part/prepar_cepii_`year'", clear
	
	capture erase "$dir/Résultats/Troisième partie/zéros/Blouk_`year'_zeros`agg'.dta"
	
		
	/*Pour pouvoir jouer avec plus tard*/
	/*Identifier les biens de la même agrégation*/
	tostring product, gen(product_s) usedisplayformat
	if `agg' !=5 {
		gen sitc_agg`agg'=substr(product_s,1,`agg')
	}
	if `agg'==5 {
		gen sitc_agg`agg'= product_s +"_"+ qty_unit
	}

	bysort iso_d 		: egen commerce_destination = total(value_`year')
	bysort iso_d iso_o 	: egen commerce_paire	    = total(value_`year')
	bysort iso_o 		: egen commerce_origine	    = total(value_`year')
	
	vallist iso_d
	foreach pays_dest in `r(list)' {
		
		preserve
		/*keep iso_o iso_d sitc_agg`agg' uv_`year'*/
		keep if iso_d=="`pays_dest'"
		
		
		/*Par agrégation, je regarde s'il y a une unit value*/
		bysort iso_o sitc_agg`agg': egen presence_unit_value=max(uv_`year')
		replace presence_unit_value=1 if presence_unit_value!=.
		
		/*Puis j'isole le commerce avec unit value*/
		generate value_`year'_avec_uv_agg`agg'= value_`year'*presence_unit_value
		
		/*Je fais la somme du trade avec uv*/
		bysort iso_o : egen /*
		*/ commerce_paire_avec_uv_agg`agg'=total(value_`year'_avec_uv_agg`agg')
	
		
		/*Puis on va compter les zeros*/
		
		/*je ne garde que les premières observations de chaque catégorie d'intérêt*/
		bysort iso_o sitc_agg`agg': keep if _n==1
		
		describe
		
		fillin iso_o iso_d sitc_agg`agg'
		
		
		fillin iso_o iso_d sitc_agg`agg'
		
		tab _fillin
		
		describe 
		
		blif
		
		
		
		
		/*Je rajoute qqch pour compter le nbr de zéros*/
		gen pour_compter_`agg' 				= 1
**pour_compter_`agg' gives total nb observations after fillin
		gen pour_compter_ssuv_`agg' 		= 1 if uv_`year'==.
**pour_compter_ssuv_`agg' gives total nb observations after fillin with lacking uv
*this includes lacking uv for existing trade but also lacking trade and uv
		gen pour_compter_sscommerce_`agg'	= 1 /*
			*/ if uv_`year'==. & value_`year'==.
**pour_compter_sscommerce_`agg' gives tot nb obs after fillin with lacking uv and trade value
*this corresponds logically to nb of obs where _fillin==1
*why not compute nb imputed simply from _fillin stats by iso_o?
		
		
	
		
		
		/*Puis je collapse pour calculer le nombre d'observations et de zéros*/
		collapse (sum) pour_compter_`agg' pour_compter_ssuv_`agg' /*
		*/ pour_compter_sscommerce_`agg' /*
		*/ (mean) commerce_paire_avec_uv_agg`agg'  /*
		*/ commerce_paire commerce_destination commerce_origine,	/*
		*/by(iso_o iso_d)
		
		
		
		
		
		/*Ici, je calcule les rapports*/
		
		generate /*
		*/share_uv_paire_agg`agg'=commerce_paire_avec_uv_agg`agg'/commerce_paire
**share_uv_paire_agg`agg' corresponds to share of uv trade out of total pair trade
		generate propor_ssuv_`agg' =/* */pour_compter_ssuv_`agg'/pour_compter_`agg'
**propor_ssuv_`agg' corresponds to nb of obs with lacking uv out of total nb obs per iso_o iso_d
*this also includes non-zero trade per pair where uv is lacking
		generate propor_sscommerce_`agg' =/* */pour_compter_sscommerce_`agg'/pour_compter_`agg'
		label var propor_sscommerce_`agg' "share of ztf"
**propor_sscommerce_`agg' corresponds to nb of imputed obs out of total nb obs per iso_o iso_d
*this corresponds to zero trade and therefore lacking uv	
		capture append using "$dir/Résultats/Troisième partie/zéros/Blouk_`year'_zeros`agg'"
		save "$dir/Résultats/Troisième partie/zéros/Blouk_`year'_zeros`agg'", replace
		display "`pays_dest'" " `year'" " zeros`agg'"
		restore
		
	}
}

/*Puis on met ensemble les calculs pour les différents niveaux d'agrégation*/

foreach agg of numlist 1(1)5 {
	use "$dir/Résultats/Troisième partie/zéros/Blouk_`year'_zeros`agg'.dta", clear
	generate year = `year'	
	if `agg'!=1 {
		merge 1:1 iso_o iso_d year  using "$dir/Résultats/Troisième partie/zéros/Nbrdezeros_`year'.dta"
		drop _merge
	}
	save  "$dir/Résultats/Troisième partie/zéros/Nbrdezeros_`year'.dta", replace
	erase "$dir/Résultats/Troisième partie/zéros/Blouk_`year'_zeros`agg'.dta"
}
end

*********************************

foreach year of num 1962(1)2013 {
	compter_zeros `year'
	use  "$dir/Résultats/Troisième partie/zéros/Nbrdezeros_`year'.dta", clear
	if `year' != 1962 {
		append using "$dir/Résultats/Troisième partie/zéros/Nbrdezeros.dta"
	}
	save "$dir/Résultats/Troisième partie/zéros/Nbrdezeros.dta", replace
	erase   "$dir/Résultats/Troisième partie/zéros/Nbrdezeros_`year'.dta"
	
}

************EXEMPLE REGRESSION:
gen real_ms=commerce_paire/commerce_destination
gen interaction=real_ms*year
reg propor_comm_ssuv_agg`agg' real_ms year interaction

***comme prevu, cela donne coef negatif sur year et real_ms et coef_positif sur interaction
**donc, avec le temps part des zeros en bilateral diminue
**donc, lorsqu'on est `gros' exportateur, on a moins de zeros
**donc, avec le temps, le lien entre part de marche et nombre de zeros s'affaiblit 
***ceci signifie que la variation entre petits et gros entre les prix observes et les prix manquants se reduit progressivement)
