**This file uses "baci_forestim_`year'" and "baci_sectorprices_`year'"
*to construct hierarchically aggregated relative prices for country composite goods 
*first compute price at the 6-digit aggreg level,
*use that to compute price at 5-digit aggreg level, and so on until
*getting the relative price of the composite good

*varnames: *i=iso_o; j=iso_d; t=year; v=value, uv=unit value; hs6=product 
**VALUE is total value per product per pair (tot_pair_product in sitc4 data)

*****************************************
**THIS FILE: build relative price of composite good  
*****************************************
****This file uses "baci_forestim_`year'.dta"
****it constructs "baci_relprice_`year'.dta" which stores 
***relative prices of the composite good computed at each aggregation level 
***for each pair where the levels are: 6,5,4,3,2,1,0
**the weighted average price for all products in this `baci'-level category, aggregated to comp_good relative price
**for products where trade is observed but uv is not observed, existing weighted mean price is applied 
**for products where uv and trade are not observed, existing weighted mean price is applied without imputing trade


****************************************
*set directory*
****************************************
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities local"

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



****************************************
*prepare file with relative prices at highest disaggregation level
****************************************
capture program drop relprice
program relprice
args year

use baci_forestim_`year', clear
*tot_value_`year': tot value of imports in hs6*dest across all partners
*tot_valueuv_`year': tot value of imports for existing uv in hs6*dest
*share_taken=share of imports in hs6*dest with uv 
/*in previous file: I dropped products with share_taken<.25 */
*sect_price=weighted average price in hs6*dest
drop share_taken
drop if uv_`year'==.
capture drop uv_share
**relative price by product
gen double rel_price_6=uv_`year'/sect_price_`year'
save baci_relprice_`year', replace
end



********************************************************************************

****************************************
*prepare files at each aggregation level*
*and do hierarchical aggregation of prices*
****************************************
*in test version: use seed and sample to reduce file to 10% of obs
*set seed 447293
*sample 10

capture program drop relprice_hier
program relprice_hier
args year

use baci_relprice_`year', clear
*set seed 447293
*sample 10
format product %06.0f
tostring product, gen(hs6) usedisplayformat
drop year product uv_`year' sect_price_`year' tot_value_`year' tot_valueuv_`year'

**compute total trade of destination in each hs6 
**included in computation of relative price
by iso_d hs6, sort: egen tot_value_`year'_dig6=total(value_`year')
foreach n of numlist 0(1)5 {
	/*Identify products of same level of aggregation*/
	gen hs6_dig`n'=substr(hs6,1,`n')
	by iso_d hs6_dig`n', sort: /*
	*/ egen tot_value_`year'_dig`n'=total(value_`year')
}
save tmp_A, replace

foreach n of numlist 5(-1)0 {
	/*Identify adjacent more disaggregated level at each step*/
	local dig_before = `n'+1

	/*Collapse to get relative price by product*pair at each aggregation level
	written so that value of trade by pair*product preserved in each step*/
	collapse tot_value_`year'_dig`n' (mean) /*
	*/rel_price_`dig_before' [iw=tot_value_`year'_dig`dig_before'], /*
	*/by(iso_o iso_d hs6_dig0-hs6_dig`n')
	rename rel_price_`dig_before' rel_price_`n'
	save tmp_B, replace
	preserve

	/*Collapse to get relative price by pair for all products at each level: 
	gives relative price of the composite good at each step if aggregation*/
	collapse (mean) rel_price_`n' [iw=tot_value_`year'_dig`n'],/*
	*/by(iso_o iso_d) 
	save tmp_result_dig`n', replace
	restore
}

**add the collapse at most disaggregated level (hs6)
use tmp_A, clear
collapse (mean) rel_price_6 [iw=tot_value_`year'_dig6], by(iso_o iso_d) 
save tmp_result_dig6, replace

/*Merge data for all aggregation levels*/
use tmp_result_dig6, clear
foreach n of numlist 5(-1)0 {
	*merge 1:1 iso_o iso_d using tmp_result_dig`n'
	merge iso_o iso_d using tmp_result_dig`n', unique sort
	drop _merge
}

/*Save final file for this year*/
generate year=`year'
*erase tmp_A
*erase tmp_B
save baci_relprice_hier_`year', replace
end

***

foreach n of numlist 1995(1)2016 {
	relprice `n'
}


foreach n of numlist 1995(1)2016 {
	relprice_hier `n'
}
**********
**erase tmp* files
foreach n of numlist 6(-1)0 {
	erase tmp_result_dig`n'.dta
}
erase tmp_A.dta
erase tmp_B.dta

**NEXT FILE: market share and benchmark equation estimation
***************************
*****NOT DONE: IMPUTED PRICES; MIX HIERARCHICAL AGGREGATION-IMPUTATION
***************************
