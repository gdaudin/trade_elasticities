**This file works with data extracted from UN COMTRADE via WITS interface (bulk download procedure)
**and downloaded into stata to produce a set of statistics about the data
**comparison file1: nb reporters per year, nb pairs per year, tot trade, tot uv trade, nb product lines (all pairs, aggregating by sitc4 (all qty_units))
**comparison file2: list pairs per year, total trade per pair, share of trade with uv per pair (not take unattributed)
**comparison file3: list reporters per year
**comparison file4: keeps only reporter identifier and nb years reporter is present

//the .do proceeds in 3 steps: 
//construct comparison files for new data, construct same files for old data,
//then compare the two data extractions

****************************************
*construct initial comparison files: file1, file2, file3
*the files I work with are: All_4D_`year'.dta
****************************************
capture program drop coverage_bulk
program coverage_bulk

set mem 500M
set matsize 800
set more off
*on my laptop:
global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
*global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
use All_4D_1962, clear
drop if iso_d=="WLD"
drop if iso_o=="WLD"
*nb reporters
preserve
keep iso_d year
by iso_d, sort: drop if _n!=1 
gen nb_rep=_N
keep in 1
drop iso_d
save file1, replace
restore
*nb pairs
preserve
keep iso_o iso_d year
by iso_o iso_d, sort: drop if _n!=1 
gen nb_pairs=_N
keep in 1
drop iso_d iso_o
joinby year using file1, unmatched(both) 
drop _merge
save file1, replace
restore
*total trade
preserve
collapse (sum) trade_value
rename trade_value tot_trade
gen year=1962
joinby year using file1, unmatched(both) 
drop _merge
save file1, replace
restore
*uv coverage
preserve
keep if uv!=.
collapse (sum) trade_value
rename trade_value tot_uv
gen year=1962
joinby year using file1, unmatched(both) 
drop _merge
gen share_uv=tot_uv/tot_trade
save file1, replace
restore
*nb product lines (by sitc4)
keep iso_o iso_d product year
by iso_o iso_d product, sort: drop if _n!=1
gen nb_lines=_N
keep nb_lines year
keep in 1
joinby year using file1, unmatched(both)
drop _merge
save file1, replace
clear

foreach i of numlist 1963(1)2009 {
	*cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
	use All_4D_`i', clear
	drop if iso_d=="WLD"
	drop if iso_o=="WLD"
*nb reporters
	preserve
	keep iso_d year
	by iso_d, sort: drop if _n!=1 
	gen nb_rep=_N
	keep in 1
	drop iso_d
	append using file1
	save file1, replace	
	restore
*nb pairs
	preserve
	keep iso_o iso_d year
	by iso_o iso_d, sort: drop if _n!=1 
	gen nb_pairs=_N
	keep in 1
	drop iso_d iso_o
	joinby year using file1, unmatched(both) update 
	drop _merge
	save file1, replace
	restore
*total trade
	preserve
	collapse (sum) trade_value
	rename trade_value tot_trade
	gen year=`i'
	joinby year using file1, unmatched(both) update 
	drop _merge
	save file1, replace
	restore
*uv coverage
	preserve
	keep if uv!=.
	collapse (sum) trade_value
	rename trade_value tot_uv
	gen year=`i'
	joinby year using file1, unmatched(both) update
	drop _merge
	replace share_uv=tot_uv/tot_trade if share_uv==.
	save file1, replace
	restore
*nb product lines (by sitc4)
	keep iso_o iso_d product year
	by iso_o iso_d product, sort: drop if _n!=1
	gen nb_lines=_N
	keep nb_lines year
	keep in 1
	joinby year using file1, unmatched(both) update
	drop _merge
	save file1, replace
	clear
}
**comparison file2: list pairs per year, total trade per pair, share of trade with uv per pair (I do not take unattributed when some attributed and some not)
cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
use All_4D_1962, clear
drop if iso_d=="WLD"
drop if iso_o=="WLD"
drop if iso_o==iso_d
by iso_o iso_d, sort: egen tot_pair=total(trade_value)
by iso_o iso_d, sort: egen tot_pair_uv=total(trade_value) if uv!=.
gen share_uv=tot_pair_uv/tot_pair
replace share_uv=0 if tot_pair_uv==.
drop tot_pair_uv
by iso_o iso_d, sort: drop if _n!=1
drop qtytoken product trade_value uv id
save file2, replace
foreach i of numlist 1963(1)2009 {
	*cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
	use All_4D_`i', clear
	drop if iso_d=="WLD"
	drop if iso_o=="WLD"
	drop if iso_o==iso_d
	by iso_o iso_d, sort: egen tot_pair=total(trade_value)
	by iso_o iso_d, sort: egen tot_pair_uv=total(trade_value) if uv!=.
	gen share_uv=tot_pair_uv/tot_pair
	replace share_uv=0 if tot_pair_uv==.
	drop tot_pair_uv
	by iso_o iso_d, sort: drop if _n!=1
	drop qtytoken product trade_value uv id
	append using file2
	save file2, replace
	clear
}
*uv coverage by pair has more than half pairs with coverage close to total trade covered
*with mean around .8 in 60s; .7 in 70s; .8 in 80s, .9 in 90s
use file2, clear
collapse (mean) mean=share_uv (p50) median=share_uv, by(year)
clear

**comparison file3: list reporters per year + list stable reporters
use file2, clear
by iso_d year, sort: drop if _n!=1
drop iso_o tot_pair share_uv
by iso_d, sort: gen nb_years=_N
gen stable=0
replace stable=1 if nb_years==48
save file3, replace

**comparisonfile4bis: keeps only the reporter identifier, and the number of years it is present in data
use file3, clear
by iso_d, sort: drop if _n!=1
drop year
save file4, replace
clear
**the stable reporters are: VEN, USA, TUR, TUN, THA, SWE, SGP, PRY, PRT, PHL, NLD, MEX, 
*KOR, JPN, ITA, ISR, ISL, HKG, GRC, GBR, FRA, ESP, DNK, DEU, COL, CHL, CHE, CAN, BRA, ARG
**Beware: this list of stable reporters is from full sample: should be redone after wits_cepii correspondence
end 
coverage_bulk


****************************************
**second step: compute same statistics for initial data extraction: 1962-2006
*construct files for initial comparison: file1old, file2old, file3old
*the files I work with are: All_4D_`year'.dta
****************************************
capture program drop coverage_bulk_old
program coverage_bulk_old

set mem 500M
set matsize 800
set more off
*on my laptop:
global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
*global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
use "$dir\SITC_Rev1_4digit_leafs\All-4D-1962.dta", clear
drop if reporter=="All"
drop if partner=="All"
gen year=1962
rename reporter iso_d
rename partner iso_o

*nb reporters
preserve
keep iso_d year
by iso_d, sort: drop if _n!=1 
gen nb_rep=_N
keep in 1
drop iso_d
save file1old, replace
restore
*nb pairs
preserve
keep iso_o iso_d year
by iso_o iso_d, sort: drop if _n!=1 
gen nb_pairs=_N
keep in 1
drop iso_d iso_o
joinby year using file1old, unmatched(both) 
drop _merge
save file1old, replace
restore
*total trade
preserve
collapse (sum) trade_value
rename trade_value tot_trade
gen year=1962
joinby year using file1old, unmatched(both) 
drop _merge
save file1old, replace
restore
*uv coverage
preserve
gen uv=trade_value/quantity
keep if uv!=.
collapse (sum) trade_value
rename trade_value tot_uv
gen year=1962
joinby year using file1old, unmatched(both) 
drop _merge
gen share_uv=tot_uv/tot_trade
save file1old, replace
restore
*nb product lines (by sitc4)
keep iso_o iso_d product year
by iso_o iso_d product, sort: drop if _n!=1
gen nb_lines=_N
keep nb_lines year
keep in 1
joinby year using file1old, unmatched(both)
drop _merge
save file1old, replace
clear

foreach i of numlist 1963(1)2006 {
	*cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
	use "$dir\SITC_Rev1_4digit_leafs\All-4D-`i'.dta", clear
	drop if reporter=="All"
	drop if partner=="All"
	gen year=`i'
	rename reporter iso_d
	rename partner iso_o
*nb reporters
	preserve
	keep iso_d year
	by iso_d, sort: drop if _n!=1 
	gen nb_rep=_N
	keep in 1
	drop iso_d
	append using file1old
	save file1old, replace	
	restore
*nb pairs
	preserve
	keep iso_o iso_d year
	by iso_o iso_d, sort: drop if _n!=1 
	gen nb_pairs=_N
	keep in 1
	drop iso_d iso_o
	joinby year using file1old, unmatched(both) update 
	drop _merge
	save file1old, replace
	restore
*total trade
	preserve
	collapse (sum) trade_value
	rename trade_value tot_trade
	gen year=`i'
	joinby year using file1old, unmatched(both) update 
	drop _merge
	save file1old, replace
	restore
*uv coverage
	preserve
	gen uv=trade_value/quantity
	keep if uv!=.
	collapse (sum) trade_value
	rename trade_value tot_uv
	gen year=`i'
	joinby year using file1old, unmatched(both) update
	drop _merge
	replace share_uv=tot_uv/tot_trade if share_uv==.
	save file1old, replace
	restore
*nb product lines (by sitc4)
	keep iso_o iso_d product year
	by iso_o iso_d product, sort: drop if _n!=1
	gen nb_lines=_N
	keep nb_lines year
	keep in 1
	joinby year using file1old, unmatched(both) update
	drop _merge
	save file1old, replace
	clear
}
use file1old, clear
local names nb_lines tot_uv tot_trade nb_pairs nb_rep share_uv
foreach n of local names {
	rename `n' `n'_old
}
save file1old, replace
clear

**comparison file2bis: list pairs per year, total trade per pair, share of trade with uv per pair (I do not take unattributed when some attributed and some not)
cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
use "$dir\SITC_Rev1_4digit_leafs\All-4D-1962.dta", clear
drop if reporter=="All"
drop if partner=="All"
gen year=1962
rename reporter iso_d
rename partner iso_o
drop if iso_o==iso_d
by iso_o iso_d, sort: egen tot_pair=total(trade_value)
gen uv=trade_value/quantity
by iso_o iso_d, sort: egen tot_pair_uv=total(trade_value) if uv!=.
gen share_uv=tot_pair_uv/tot_pair
replace share_uv=0 if tot_pair_uv==.
drop tot_pair_uv
by iso_o iso_d, sort: drop if _n!=1
drop quantity qty_unit product trade_value uv 
save file2old, replace
foreach i of numlist 1963(1)2006 {
	*cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
	use "$dir\SITC_Rev1_4digit_leafs\All-4D-`i'.dta", clear
	drop if reporter=="All"
	drop if partner=="All"
	gen year=`i'
	rename reporter iso_d
	rename partner iso_o
	drop if iso_o==iso_d
	by iso_o iso_d, sort: egen tot_pair=total(trade_value)
	gen uv=trade_value/quantity
	by iso_o iso_d, sort: egen tot_pair_uv=total(trade_value) if uv!=.
	gen share_uv=tot_pair_uv/tot_pair
	replace share_uv=0 if tot_pair_uv==.
	drop tot_pair_uv
	by iso_o iso_d, sort: drop if _n!=1
	drop quantity qty_unit product trade_value uv 
	append using file2old
	save file2old, replace
	clear
}
use file2old, clear
rename tot_pair tot_pair_old
rename share_uv share_uv_old
save file2old, replace

*uv coverage by pair has more than half pairs with coverage close to total trade covered
*uv coverage in old data is similar to new data except for 2000s where new data has better uv coverage per pair
use file2old, clear
collapse (mean) mean=share_uv (p50) median=share_uv, by(year)
clear

**comparison file3bis: list reporters per year + list stable reporters
use file2old, clear
by iso_d year, sort: drop if _n!=1
drop iso_o tot_pair share_uv
by iso_d, sort: gen nb_years_old=_N
gen stable_old=0
replace stable_old=1 if nb_years_old==45
save file3old, replace
**comparisonfile4bis: keeps only the reporter identifier, and the number of years it is present in data
use file3old, clear
by iso_d, sort: drop if _n!=1
drop year
save file4old, replace

**the stable reporters are the same in both datasets: VEN, USA, TUR, TUN, THA, SWE, SGP, PRY, PRT, PHL, NLD, MEX, 
**KOR, JPN, ITA, ISR, ISL, HKG, GRC, GBR, FRA, ESP, DNK, DEU, COL, CHL, CHE, CAN, BRA, ARG
**Beware: this list of stable reporters is from full sample: should be redone after wits_cepii correspondence
end 
coverage_bulk_old

**step 3: compare the two data sets**
capture program drop comp
program comp
use file1, clear
merge 1:1 year using file1old
drop _merge

**compare total_trade
gen tot_cov=tot_trade/tot_trade_old
**total covered trade is lower in new than in old database until 1982, and becomes larger since 1988: between 2 and 5% more since 1996

**compare uv coverage
gen tot_cov_uv=tot_uv/tot_uv_old
**uv coverage is lower in new than in old data until 1979; similar between 1979 and 1988; slightly better in new data until 1999, and much better in new data in 2000-2006 (9-12% more)

**compare nb pairs
gen diff_pairs=nb_pairs-nb_pairs_old
**same finding: less pairs (between 50-100 less pairs) until 1982 in new data, then same nb, then more pairs in new data (up to 1000 more in 2000s)

**compare nb reporters
gen diff_reporters=nb_rep-nb_rep_old
**nb reporters the same in old and new data until 2000s: between 2 and 10 more in new data in 2000-2006
keep year tot_cov tot_cov_uv diff_pairs diff_reporters
save comparison1, replace
**remember that all 4 variables are computed as difference (ratio) between new and old data

**compare data by pair
use file2, clear
merge 1:1 year iso_d iso_o using file2old
**83900 pairs in new data do not merge, and 98% are posterior to 1982
**4846 pairs in old data do not merge, and half of these is posterior to 1982
keep if _merge==3
**there are 590370 obs which match
gen ratio=tot_pair/tot_pair_old
gen id=0
replace id=1 if ratio>.75 & ratio<1.25
tab id
**there are significant differences in total reported trade for 32998 out of 590370 obs., e.g. about 5.6% of data
clear
use file3, clear
merge 1:1 year iso_d using file3old
**492 reporter*year observations do not match from new data, and 5 do not match from old data
**489 reporter*year obs. from new data are posterior to 1988
**but all 5 that do not match from old data are in 2001-2004
**5444 obs. match

*for completeness, I check differences in coverage per reporter in nb of years
use file4, clear
merge 1:1 iso_d using file4old
**4 reporters are specific to new data: DDR, MNT, MYT, PSE 
**DDR is present in 6 years, MNT in 4, MYT in 10 and PSE in 10
keep if _merge==3
drop _merge
**213 reporters match
assert stable=stable_old
**the 30 stable reporters are the same
drop stable stable_old
gen diff_years=nb_years-nb_years_old
**the mean difference is 3 years, consistent with 3 more years of data
**but some gaps go from -3 to +8
clear

end
comp

**NOTES: there are discrepancies between the two data extractions of which some are unexpected
**these are: worse coverage for 1962-1988 than with initial extraction
**discrepancies for 5% of data for total reported pair-level trade
**divergences in reporter-year list
**expected differences: better uv coverage for 90s-2000s in new data, better general coverage for 2000s in new data
*the next .do checks whether these observations persist when we compare the old/new extraction after wits-cepii correspondence
