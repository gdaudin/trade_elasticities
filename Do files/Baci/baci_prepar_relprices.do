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
*prepare data files*
****************************************
set mem 500M
set matsize 800
set more off
*on my laptop:
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN"
*at OFCE:
global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN"
cd "$dir\baci"

**insheet data and look at variables
*insheet using "baci92_`1'.csv", clear

**prepare data files 
**keep lacking quantity data in the preparatory files because I will need them later
capture program drop prepar
program prepar

insheet using "baci92_`1'.csv", clear
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
	rename `n' `n'_`1'
}

save baci_prepar_`1', replace
clear
end

*prepar 1995

foreach i of numlist 1995(1)2010 {
	prepar `i' 
}

**REMEMBER: relatively to sitc4 data: only one quantity unit here
**VALUE is total value per product per pair (tot_pair_product in sitc4 data)

**************
*construct file of relevant country codes: the ones in wits-cepii corresp
**************
capture program drop countries_baci
program countries_baci
*at OFCE:
use "$dir\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06", clear
rename ccode_cepii_d iso3
joinby iso3 using country_codes_baci, unmatched(both)
**234 match
**3 in master: Czechoslovakia; DDR; USSR: not a problem b/c no longer there in 1995-2010 data
**70 obs do not correspond to an iso3 code: "other", "not elsewhere mentioned": dropped
**1 obs corresponds to world (000): dropped
drop if _merge==1
drop if iso3==""
keep iso3 _merge in_baci country code
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
drop _merge in_baci country
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
countries_baci

***********************
***build data files for estimation and 
***sectoral prices by product and destination
***********************
capture program drop sectoral
program sectoral
use baci_prepar_`1', clear
joinby i using baci_corresp_i, unmatched(none)
joinby j using baci_corresp_j, unmatched(none)
drop i j 
drop if iso_o==iso_d
drop if value_`1'==0
rename hs6 product
rename t year
**variables: 
*uv_`i': uv by product for iso_o in iso_d 
*value_`i': value by product for iso_o in iso_d
preserve
keep year iso_o iso_d tot*
by iso_o iso_d, sort: drop if _n!=1
save baci_tot_`1', replace
restore
drop tot*
**"tot_value_`i': total imports by destination by product  
by iso_d product, sort: egen tot_value_`1'=total(value_`1')
**"tot_value_uv_`i': total imports by destination by product, where only obs. with existing uv taken into account 
by iso_d product, sort: egen tot_valueuv_`1'=total(value_`1') if uv_`1'!=.
**share_taken: tells how much of any product*qty_unit combination is accounted for by non-imputed uv
gen double share_taken=tot_valueuv_`1'/tot_value_`1' 
**drop those obs. where share_taken <.25 of total value
drop tot_value_`1' tot_valueuv_`1'
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
by iso_d product, sort: egen tot_value_`1'=total(value_`1')
by iso_d product, sort: egen tot_valueuv_`1'=total(value_`1') if uv_`1'!=.
gen double uv_share=value_`1'/tot_valueuv_`1'
replace uv_share=uv_`1'*uv_share
by iso_d product, sort: egen sect_price_`1'=total(uv_share) if uv_`1'!=.
drop uv_share
save baci_forestim_`1', replace
clear	
end

foreach n of numlist 1995(1)2010 {
	sectoral `n'
}

***********
**construct separate file which keeps sectoral prices: hs6*destination (annual files)
***********
capture program drop synt
program synt
use baci_forestim_`1', clear
drop if sect_price_`1'==.
by iso_d product sect_price_`1', sort: drop if _n!=1
keep product iso_d sect_price_`1' share_taken 
**share_taken is defined as share of trade for which uv is available for this product
rename share_taken share_taken_`1' 
save sectorprices_`1', replace
clear
end 

foreach n of numlist 1995(1)2010 {
	synt `n'
}

**erase intermediate files
foreach n of numlist 1995(1)2010 {
	erase "baci_prepar_`n'.dta"
	erase "baci92_`n'.csv"
}
erase tmp_impute1_toappend.dta

***NEXT FILE: constructs hierarchically aggregated prices, 
*market shares, and runs benchmark estimation

***************NOT DONE:***********
***********************************
**this part of file is needed if we want to impute lacking uv with observed uv 
**for countries with similar market share to the same destination: not done here 
**impute uv for lacking uv: qty_unit is known but no quantity present
capture program drop imp
program imp
use baci_forestim_`1', clear
gen ms=value_`1'/tot_value_`1'
preserve
keep if uv_`1'==. 
keep product iso_d iso_o ms
rename iso_o partner
rename ms partner_ms
save tmp_impute1, replace
restore
preserve
joinby product iso_d using tmp_impute1, unmatched(none)
drop if uv_`1'==.
gen diff_ms=abs(ms-partner_ms)
by iso_d product, sort: egen min_diff=min(abs(ms-partner_ms))
**impute known uv when min_diff in ms less than 25 percentage points
keep if diff_ms==min_diff
keep if min_diff<.25
keep product iso_d partner uv_`1'
by iso_d partner product, sort: drop if _n!=1
joinby iso_d partner product using tmp_impute1, unmatched(none)
rename partner iso_o
save tmp_impute1_toappend, replace
**this file stores uv which can be imputed with this method
restore
erase tmp_impute1.dta
merge 1:1 iso_d iso_o product using tmp_impute1_toappend, update 
erase tmp_impute1_toappend.dta
drop tot_valueuv_`1'
drop _merge
**"tot_value_uv_`i': total imports by destination by product, where only obs. with existing uv taken into account after uv imputation
by iso_d product, sort: egen tot_valueuv_`1'=total(value_`1') if uv_`1'!=.
**this variable gives share of each exporter within each product where uv is available
gen double uv_share=value_`1'/tot_valueuv_`1'
replace uv_share=uv_`1'*uv_share
by iso_d product qty_unit, sort: egen sect_price_`1'=total(uv_share) if uv_`1'!=.
drop ms partner_ms
save baci_imp_`1', replace
clear	
end

foreach n of numlist 1995(1)2010 {
	imp `n'
}

******************
******************
