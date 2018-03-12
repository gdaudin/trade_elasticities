*v2 : ajusté pour intérgrer les données collectées en 2015
*v1.1. : ajusté to work for Guillaume
*Fait à partir de full_part3_prepar_relprices.do
*Removed everything after the save of prepar_full

**This file constructs "prepar_full_`year'", "prepar_full_imp_`year' and "sectorprices_full_`year'" files for the full sample
**these files are then used in aggregate trade elasticity estimations on the composite good (relative price in levels)
**"prepar_full_imp_`year' stores uv per pair*product*qty_unit with imputed uv for lacking uv
**"sectorprices_full_`year'" stores sectoral prices by destination*product_qty_unit

****************************************
*prepare data files*
****************************************
clear all
set mem 500M
set matsize 800
set more off


display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
	cd "$dir"

}

*for KUL server
if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data"
}

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013_in2018"
}


*****Test pour les noms de pays


local pays_a_tester FRG DEU
*BLX BEL LUX FRG DEU SER YUG CSK ETF KN1 PCZ PMY PSE SER SVR SU

foreach pays of local pays_a_tester  {
	foreach status in d o {
		local `pays'_`status'
	}
}



*Why do we not check 1962 here?
*Also, the directory used does not correspond to anything in laptop: modify?
foreach year of numlist 1962(1)2013 {
*	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`year'.dta", clear
	use "cepii-4D-`year'.dta", clear
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

clear


**first I pre-prepare data files keeping for each year the data I will need
**I keep lacking quantity data in the preparatory files because I will need them later
capture program drop prepar
program prepar
args year
*eg prepar 1962

*again here I change directory
*use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`year'.dta", clear
use "cepii-4D-`year'.dta", clear
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
	rename `n' `n'_`1'
}

*again here I change directory
*save "$dir/Data/For Third Part/prepar_cepii_`year'", replace
save "prepar_cepii_`year'", replace
clear
end



foreach i of numlist 1962(1)2013 {
	prepar `i'
}

****************************************************************************************************





