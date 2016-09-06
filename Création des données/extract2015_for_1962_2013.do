*June 29th : on se borne à ce qui est dans le cepii (_v2GD)
*June 15th, 2015*This file insheets 1962-2013 data extracted from UN COMTRADE via WITS interface (advanced query procedure)
*there are some discrepancies with previous extraction in 2005-2009: therefore I extract 2000-2013
*I don't extract 2014 b/c nbr rows decreases significantly (from 1 bio to 750 mio in each file) 
**query in WITS suspended if I take all possible obs: hence, split in two reporter groups A-K; L-Z
**This .do gets all data from .txt files for 2000-2013

****************************************
*set directory*
****************************************
*capture program drop advquery_in_stata
*program advquery_in_stata
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities"
	cd "$dir/Data/COMTRADE_2015_lite"

}


if "`c(hostname)'" =="ECONCES1" {
*	global dir "/Users/liza/Documents/LIZA_WORK"
	global dir "Y:\ELAST_NONLIN"
	cd "$dir"
*	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015"
}



********************************************************
*insheet data: 2000-2013
********************************************************
*sitcrev1_4dgt_`year'_`id'.txt
*local year=2000/2013
*local id=1/2
capture program drop crdata

program crdata
insheet using "sitcrev1_4dgt_`1'.txt", clear
save All-4D-`1', replace
assert year==`1'
*assert tradeflowcode==5
*drop if reporteriso3=="All"
*drop if partneriso3=="All"
*drop if reporteriso3=="EUN"
*drop if partneriso3=="EUN"
*rename reporteriso3 iso_d
*rename partneriso3 iso_o
drop if iso_d==iso_o
*rename tradevalue trade_value
drop if trade_value==.
drop if product==.
*format productcode %04.0f
*rename productcode product=
*rename qtyunit qty_unit
*rename quantitytoken qty_token
keep trade_value product quantity qty_unit qty_token iso_o iso_d year
save All-4D-`1', replace
clear
end

capture program drop keepdatacepii
program keepdatacepii
use All-4D-`1', clear
drop if iso_d=="All"
drop if iso_o=="All"
*capture replace iso_d= YUG if iso_d=="SER"
*capture replace iso_o= YUG if iso_o=="SER"
*capture replace iso_d= ETH if iso_d=="ERI"
*capture replace iso_o= ETH if iso_o=="ERI"
*capture replace iso_d= BEL if iso_d=="LUX"
*capture replace iso_o= BEL if iso_o=="LUX"
*J'ai enlevé tous les traitements (Belgique, Serbie, Luxembourg, Allemagne...)


**Remplacer
rename iso_d iso
replace iso ="FRG" if iso=="DEU" & year<=1990
joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
replace iso  = "DEU" if iso=="FRG" & year<=1990
rename cepii cepii_d
rename iso iso_d

rename iso_o iso
replace iso = "FRG" if iso=="DEU" & year<=1990
joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
replace iso = "DEU" if iso=="FRG" & year<=1990
rename cepii cepii_o
rename iso iso_o 


drop if iso_o==iso_d
*collapse (sum) trade_value quantity, by(product qty_unit qty_token iso_o iso_d year)
save cepii-4D-`1', replace
rm All-4D-`1'.dta
clear
end







*crdata 2000
foreach year of numlist 1962/2013 {
	crdata `year'
	keepdatacepii `year'
}
