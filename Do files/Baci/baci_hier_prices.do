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
set mem 500M
set matsize 800
set more off
*on my laptop:
global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN"
*at OFCE:
*global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN"
*GD
*global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
cd "$dir\baci"

****************************************
*prepare file with relative prices at highest disaggregation level
****************************************
capture program drop relprice
program relprice

use baci_forestim_`1', clear
*tot_value_`1': tot value of imports in hs6*dest across all partners
*tot_valueuv_`1': tot value of imports for existing uv in hs6*dest
*share_taken=share of imports in hs6*dest with uv 
/*in previous file: I dropped products with share_taken<.25 */
*sect_price=weighted average price in hs6*dest
drop share_taken
drop if uv_`1'==.
drop uv_share
**relative price by product
gen double rel_price_6=uv_`1'/sect_price_`1'
save baci_relprice_`1', replace
end

foreach n of numlist 1995(1)2010 {
	relprice `n'
}

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

use baci_relprice_`1', clear
*set seed 447293
*sample 10
format product %06.0f
tostring product, gen(hs6) usedisplayformat
drop year product uv_`1' sect_price_`1' tot_value_`1' tot_valueuv_`1'

**compute total trade of destination in each hs6 
**included in computation of relative price
by iso_d hs6, sort: egen tot_value_`1'_dig6=total(value_`1')
foreach n of numlist 0(1)5 {
	/*Identify products of same level of aggregation*/
	gen hs6_dig`n'=substr(hs6,1,`n')
	by iso_d hs6_dig`n', sort: /*
	*/ egen tot_value_`1'_dig`n'=total(value_`1')
}
save tmp_A, replace

foreach n of numlist 5(-1)0 {
	/*Identify adjacent more disaggregated level at each step*/
	local dig_before = `n'+1

	/*Collapse to get relative price by product*pair at each aggregation level
	written so that value of trade by pair*product preserved in each step*/
	collapse tot_value_`1'_dig`n' (mean) /*
	*/rel_price_`dig_before' [iw=tot_value_`1'_dig`dig_before'], /*
	*/by(iso_o iso_d hs6_dig0-hs6_dig`n')
	rename rel_price_`dig_before' rel_price_`n'
	save tmp_B, replace
	preserve

	/*Collapse to get relative price by pair for all products at each level: 
	gives relative price of the composite good at each step if aggregation*/
	collapse (mean) rel_price_`n' [iw=tot_value_`1'_dig`n'],/*
	*/by(iso_o iso_d) 
	save tmp_result_dig`n', replace
	restore
}

**add the collapse at most disaggregated level (hs6)
use tmp_A, clear
collapse (mean) rel_price_6 [iw=tot_value_`1'_dig6], by(iso_o iso_d) 
save tmp_result_dig6, replace

/*Merge data for all aggregation levels*/
use tmp_result_dig6, clear
foreach n of numlist 5(-1)0 {
	*merge 1:1 iso_o iso_d using tmp_result_dig`n'
	merge iso_o iso_d using tmp_result_dig`n', unique sort
	drop _merge
}

/*Save final file for this year*/
generate year=`1'
*erase tmp_A
*erase tmp_B
save baci_relprice_hier_`1', replace
end

***
foreach n of numlist 1995(1)2010 {
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
