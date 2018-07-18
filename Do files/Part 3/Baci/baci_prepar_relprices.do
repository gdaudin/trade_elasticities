**This file insheets BACI data into STATA and prepares composite good prices
**It constructs "baci_forestim_`year'", "baci_tot_`year'", and "baci_sectorprices_`year'"

***"baci_forestim_`year'" has uv data needed for estimation, including sectoral prices per hs6 product
***"baci_tot_`year'" stores information on total trade by destination and by pair (ms)
**"baci_sectorprices_`year'" stores sectoral prices by destination*product

**for 1995: 7% obs. have lacking quantity data
**for 2010: 1% obs. have lacking quantity data

*varnames: all numeric; one quantity unit for all observations
*i=iso_o; j=iso_d; t=year; v=value, q=quantity; hs6=product 
**variables are renamed in files prepared for estimation to replicate
**names used in our previous .do files for 1962-2009

*the iso_o-iso_d list matches previous un comtrade list: 225 countries






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

import delimited "$dir/Data/Baci/country_code_baci92.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)
save "$dir/Data/Baci/country_code_baci92.dta", replace
cd "$dir/Data/Baci"


****************************************
*prepare data files*
****************************************
set mem 500M
set matsize 800
set more off


**prepare data files 
**keep lacking quantity data in the preparatory files because I will need them later
capture program drop prepar
program prepar
args year

insheet using "$dir/Data/Baci/baci92_`year'.csv", clear
drop if hs6==.
drop if v==.
replace q=. if q<0 
replace q=. if  q==0
**0 for q corresponds to small share of obs in the data, but it is there
**does 0 mean very small quantity? I set such obs. to missing
**an alternative would be to set it to very small number, and get high uv: not done here

*****************
**compute unit_value per product (based only on trade_value for non_zero quantity)
**in this database: no changes in uv through this procedure
gen double uv=v/q
assert uv!=. if q!=.

local name v q
foreach n of local name {
	by i j hs6, sort: egen double tot_`n'=total(`n') if q!=.
}
gen double uv_share=v/tot_v

replace uv_share=uv*uv_share
by i j hs6, sort: egen uv_final=total(uv_share) if q!=.

drop q tot_q uv_share uv tot_v
rename uv_final uv

**check that unique observation per i j hs6 
*in this database: value corresponds to total value by pair for product
*because there is one quantity unit per product in this data
*and also: no cases where some uv is missing and some accounted for
by i j hs6, sort: assert _N==1
*by i j hs6, sort: egen double tot_pair_product=total(v)
*sort i j hs6 tot_pair_product uv
*by i j hs6, sort: drop if _n!=1
*rename tot_pair_product value
rename v value

**generate total trade per pair (value by pair for all products)
by i j, sort: egen double tot_pair_full=total(value)

**generate total trade by destination (value for j of trade with all partners)
by j, sort: egen double tot_dest_full=total(value)

local name uv value tot_pair_full tot_dest_full
foreach n of local name {
	rename `n' `n'_`year'
}

save baci_prepar_`year', replace
clear
end


**REMEMBER: relatively to sitc4 data: only one quantity unit here
**VALUE is total value per product per pair (tot_pair_product in sitc4 data)

**************
*construct file of relevant country codes: the ones in wits-cepii corresp
**************
capture program drop countries_baci
program countries_baci
*at OFCE:
use "$dir/Data/For Appendix/cepii_wits_country_list.dta", clear
rename iso_d iso3
joinby iso3 using country_code_baci92.dta, unmatched(both)
**234 match
**3 in master: Czechoslovakia; DDR; USSR: not a problem b/c no longer there in 1995-2010 data
**70 obs do not correspond to an iso3 code: "other", "not elsewhere mentioned": dropped
**1 obs corresponds to world (000): dropped
drop if _merge==1
drop if iso3==""
rename i code
keep iso3 _merge country code
sort _merge country
drop if code=="000"
**eliminate doubles in iso3 due to wits nomenclature changes
by code, sort: drop if _n!=1
**this leaves 225 which match, and 18 which don't 
**the only problematic code is 58 (blx): Belgium-Luxembourg while Belgium is 56(bel)
*in un comtrade we put Belgium and Luxembourg data together, but code it as BEL
*therefore: also adjusted here
replace iso3="BEL" if code=="058"
drop if code=="056"
replace _merge=3 if code=="058"
**final result: 225 matching codes, and 17 non-matching
save baci_corresp, replace
**we decided to use identical set of partners for estimation
*therefore, the next file drops non-merged codes
use baci_corresp, clear
drop if _merge==2
drop _merge country
destring(code), gen(i)
destring(code), gen(j)
drop code
preserve
drop i
rename iso3 iso_d
save baci_corresp_j, replace
restore
drop j
rename iso3 iso_o
save baci_corresp_i, replace
clear
end


***********************
***build data files for estimation and 
***sectoral prices by product and destination
***********************
capture program drop sectoral
program sectoral
args year

use baci_prepar_`year', clear
joinby i using baci_corresp_i, unmatched(none)
joinby j using baci_corresp_j, unmatched(none)
drop i j 
drop if iso_o==iso_d
drop if value_`year'==0
rename hs6 product
rename t year
**variables: 
*uv_`i': uv by product for iso_o in iso_d 
*value_`i': value by product for iso_o in iso_d
preserve
keep year iso_o iso_d tot*
by iso_o iso_d, sort: drop if _n!=1
save baci_tot_`year', replace
restore
drop tot*
**"tot_value_`i': total imports by destination by product  
by iso_d product, sort: egen tot_value_`year'=total(value_`year')
**"tot_value_uv_`i': total imports by destination by product, where only obs. with existing uv taken into account 
by iso_d product, sort: egen tot_valueuv_`year'=total(value_`year') if uv_`year'!=.
**share_taken: tells how much of any product*qty_unit combination is accounted for by non-imputed uv
gen double share_taken=tot_valueuv_`year'/tot_value_`year' 
**drop those obs. where share_taken <.25 of total value
drop tot_value_`year' tot_valueuv_`year'
capture assert share_taken>=.25
if _rc!=0 {
	preserve
	keep product iso_d share_taken
	by iso_d product share_taken, sort: drop if _n!=1
	keep if share_taken<.25
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
}
erase tmp_unit.dta
**for 1995: 61537 observations dropped b/c of share_taken<.25
**for 2007: 16721 obs. deleted b/c of share_taken<.25

****compute sectoral prices******
**this variable gives share of each exporter within each product where uv is available
by iso_d product, sort: egen tot_value_`year'=total(value_`year')
by iso_d product, sort: egen tot_valueuv_`year'=total(value_`year') if uv_`year'!=.
gen double uv_share=value_`year'/tot_valueuv_`year'
replace uv_share=uv_`year'*uv_share
by iso_d product, sort: egen sect_price_`year'=total(uv_share) if uv_`year'!=.
drop uv_share
save baci_forestim_`year', replace
clear	
end


***********
**construct separate file which keeps sectoral prices: hs6*destination (annual files)
***********
capture program drop synt
program synt
args year

use baci_forestim_`year', clear
drop if sect_price_`year'==.
by iso_d product sect_price_`year', sort: drop if _n!=1
keep product iso_d sect_price_`year' share_taken 
**share_taken is defined as share of trade for which uv is available for this product
rename share_taken share_taken_`year' 
save sectorprices_`year', replace
clear
end 



***NEXT FILE: constructs hierarchically aggregated prices, 
*market shares, and runs benchmark estimation

***************NOT DONE:***********
***********************************
**this part of file is needed if we want to impute lacking uv with observed uv 
**for countries with similar market share to the same destination: not done here 
**impute uv for lacking uv: qty_unit is known but no quantity present
capture program drop imp
program imp
args year

use baci_forestim_`year', clear
gen ms=value_`year'/tot_value_`year'
preserve
keep if uv_`year'==. 
keep product iso_d iso_o ms
rename iso_o partner
rename ms partner_ms
save tmp_impute1, replace
restore
preserve
joinby product iso_d using tmp_impute1, unmatched(none)
drop if uv_`year'==.
gen diff_ms=abs(ms-partner_ms)
by iso_d product, sort: egen min_diff=min(abs(ms-partner_ms))
**impute known uv when min_diff in ms less than 25 percentage points
keep if diff_ms==min_diff
keep if min_diff<.25
keep product iso_d partner uv_`year'
by iso_d partner product, sort: drop if _n!=1
joinby iso_d partner product using tmp_impute1, unmatched(none)
rename partner iso_o
save tmp_impute1_toappend, replace
**this file stores uv which can be imputed with this method
restore
erase tmp_impute1.dta
merge 1:1 iso_d iso_o product using tmp_impute1_toappend, update 
erase tmp_impute1_toappend.dta
drop tot_valueuv_`year'
drop _merge
**"tot_value_uv_`i': total imports by destination by product, where only obs. with existing uv taken into account after uv imputation
by iso_d product, sort: egen tot_valueuv_`year'=total(value_`year') if uv_`year'!=.
**this variable gives share of each exporter within each product where uv is available
gen double uv_share=value_`year'/tot_valueuv_`year'
replace uv_share=uv_`year'*uv_share
by iso_d product qty_unit, sort: egen sect_price_`year'=total(uv_share) if uv_`year'!=.
drop ms partner_ms
save baci_imp_`year', replace
clear	
end



******************
******************

*prepar 1995

countries_baci

foreach i of numlist 1995(1)2016 {
	prepar `i' 
}


foreach n of numlist 1995(1)2016 {
	sectoral `n'
}

foreach n of numlist 1995(1)2016 {
	synt `n'
}

/*

foreach n of numlist 1995(1)2016 {
	imp `n'
}
*/

**erase intermediate files
foreach n of numlist 1995(1)2016 {
	erase "baci_prepar_`n'.dta"
	erase "baci92_`n'.csv"
}
erase tmp_impute1_toappend.dta
