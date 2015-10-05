*v2 : ajusté pour intérgrer les données collectées en 2015
*v1.1. : ajusté to work for Guillaume
*Fait à partir de full_part3_prepar_relprices.do
*Removed everything after the save of prepar_full

*LA: Sept.10: This file follows "preparations des donnees.do" pour obtenir a la fin les fichiers "prepar_full_`year'.dta"
*mais les noms de fichiers de donnees SITC 4 de 2015 s'appellent "sitcrev1_4dgt_`year'.txt" et non pas "cepii-4D-`year'.txt"

**This file constructs "prepar_full_`year'" files for the full sample

****************************************
*prepare data files*
****************************************
clear all
set mem 500M
set matsize 800
set more off
*on my laptop:
global dir "/Users/liza/Documents/LIZA_WORK"
cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
*Guillaume
*global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
*cd "$dir\SITC_Rev1_adv_query_2011"
*GD
*cd "$dir"

**first I pre-prepare data files keeping for each year the data I will need
**I keep lacking quantity data in the preparatory files because I will need them later
capture program drop prepar
program prepar
args year ini fin
*eg prepar 1962 62 90
*eg prepare 1962 91 06
*local year 1962
*local ini 62
*local fin 90

*use All-4D-`1', clear
*GD

*use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`year'.dta", clear
insheet using sitcrev1_4dgt_`year'.txt, clear	

drop if iso_o=="All"
drop if iso_d=="All"
drop if product==.
drop if trade_value==.

**procedure for correspondence
**to change all ERI-ETH variations to ETH only
capture replace iso_d="ETH" if iso_d=="ERI"
capture replace iso_o="ETH" if iso_o=="ERI"

**to change all BEL-LUX variations to BEL only
capture replace iso_d="BEL" if iso_d=="LUX"
capture replace iso_o="BEL" if iso_o=="LUX"

*Liza's corresp files: 62-90; 91-06
joinby iso_d using "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_d_`ini'_`fin'", unmatched(none)
drop iso_d
rename ccode_cepii iso_d
joinby iso_o using "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_o_`ini'_`fin'", unmatched(none)
drop iso_o
rename ccode_cepii iso_o

*give same name (DEU) to Germany bef/aft 1991: needed so that price series for Germany uninterrupted
capture replace iso_d="DEU" if iso_d=="FRG"
capture replace iso_o="DEU" if iso_o=="FRG"

**Preparing Germany (que chez Guillaume)
*replace iso_d= "DEU_avt91" if `year' <=1990 & iso_d=="DEU"
*replace iso_o= "DEU_avt91" if `year' <=1990 & iso_o=="DEU"
*replace iso_d= "DEU_apr91" if `year' >=1991 & iso_d=="DEU"
*replace iso_o= "DEU_apr91" if `year' >=1991 & iso_o=="DEU"

**Remplacer
*rename iso_d iso
*joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
*rename cepii iso_d
*drop iso

*rename iso_o iso
*joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
*rename cepii iso_o 
*drop iso


assert qty_token!=.
replace quantity=. if quantity<0 
replace quantity=. if  quantity==0
*assert quantity!=. if qty_token!=1
*assert qty_unit!=""
*assert quantity!=. if qty_unit!="N.Q."


**compute unit_value per product (based only on trade_value for non_zero quantity)
gen double uv=trade_value/quantity
assert uv!=. if quantity!=.

local name trade_value quantity
foreach n of local name {
	by iso_o iso_d product qty_unit, sort: egen double tot_`n'=total(`n') if quantity!=.
}

gen double uv_share=trade_value/tot_trade_value
replace uv_share=uv*uv_share
by iso_o iso_d product qty_unit, sort: egen uv_final=total(uv_share) if quantity!=.

drop quantity tot_quantity uv_share uv tot_trade_value
rename uv_final uv

**construct total trade value per pair per product per quantity unit
by iso_o iso_d product qty_unit, sort: egen double tot_value_pair_product=total(trade_value)

sort iso_o iso_d product qty_unit tot_value_pair_product uv

**in data: for small trade values for certain pairs, same trade value corresponds to various products
**corresponds to 10% of observations in 1962
**for this first estimation I keep them
**in data: sometimes for same pair-product, several obs. in same qty_unit
**but never several obs. for same pair-product in different units

by iso_o iso_d product qty_unit, sort: drop if _n!=1

drop trade_value 
rename tot_value_pair_product value

**"value" corresponds to total pair trade for a given product by quantity unit
**generate value_product (value by pair for product for all quantity units)
by iso_o iso_d product, sort: egen double tot_pair_product=total(value)

**generate total trade per pair (value by pair for all products for all quantity units)
by iso_o iso_d, sort: egen double tot_pair_full=total(value)

**generate total trade by destination(value for iso_d of trade for all partners)
by iso_d, sort: egen double tot_dest_full=total(value)

local name uv value tot_pair_product tot_pair_full tot_dest_full
foreach n of local name {
	rename `n' `n'_`year'
}

save prepar_full_`year', replace
erase "sitcrev1_4dgt_`year'.txt"
*GD
*save "$dir/Data/For Third Part/prepar_full_`year'", replace
clear
end

*prepar 1962 62 90
*prepar 2009 91 06

foreach n of numlist 1962/1990 {
	prepar `n' 62 90
}
foreach n of numlist 1991/2013 {
	prepar `n' 91 06
}
*GD
*foreach i of numlist 1962(1)2013 {
*	prepar `i'
*}

****************************************************************************************************





