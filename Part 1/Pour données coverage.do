**This file works with data extracted from UN COMTRADE via WITS interface (bulk download procedure)
**and downloaded into stata to produce a set of statistics about the data
**comparison cov_per_year: nb reporters per year, nb pairs per year, tot trade, tot uv trade, nb product lines (all pairs, aggregating by sitc4 (all qty_units))
**comparison cov_per_year_pair: list pairs per year, total trade per pair, share of trade with uv per pair (not take unattributed)
**comparison list_year_reporter: list reporters per year
**comparison list_reporter: keeps only reporter identifier and nb years reporter is present

**Reprise 25 juin 2015 : adaptation à l'ordinateur de GD + utilisation des nouvelles données
**À partir de coverage_bulk.do
** file1-> cov_per_year, file2 -> cov_per_year_pair, file3 ->list_year_reporter, file3 -> list_reporter
//the .do proceeds in 3 steps: 
//construct comparison files for new data, construct same files for old data,
//then compare the two data extractions


**Reprise Sept 06, 2016: run on econces server to get cov_per_year_pair.dta
*on econces1:
global dir "Y:\ELAST_NONLIN"
cd "$dir"

*GD
global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
cd "$dir"




****************************************
*construct initial comparison files: cov_per_year, cov_per_year_pair, list_year_reporter
*the files I work with are: All_4D_`year'.dta
****************************************
capture program drop coverage_bulk
program coverage_bulk

set mem 500M
set matsize 800
set more off

*cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"

clear


foreach i of numlist 1962(1)2013 {
	display "--cov_per_year--------`i'---------------------"
	
*	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`i'.dta", clear
	use cepii-4D-`i', clear	
	drop if iso_d=="WLD"
	drop if iso_o=="WLD"
*nb reporters
	preserve
	keep iso_d year
	by iso_d, sort: drop if _n!=1 
	gen nb_rep=_N
	label variable nb_rep "Number of reporters"
	keep in 1
	drop iso_d
	capture append using cov_per_year
	save cov_per_year, replace	
	restore
*nb pairs
	preserve
	keep iso_o iso_d year
	by iso_o iso_d, sort: drop if _n!=1 
	gen nb_pairs=_N
	keep in 1
	drop iso_d iso_o
	joinby year using cov_per_year, unmatched(both) update 
	drop _merge
	save cov_per_year, replace
	restore
*total trade
	preserve
	collapse (sum) trade_value
	rename trade_value tot_trade
	gen year=`i'
	joinby year using cov_per_year, unmatched(both) update 
	drop _merge
	save cov_per_year, replace
	restore
*uv coverage
	preserve
	generate uv = trade_value/quantity
	keep if uv!=.
	collapse (sum) trade_value
	rename trade_value tot_uv
	gen year=`i'
	joinby year using cov_per_year, unmatched(both) update
	drop _merge
	capture generate share_uv = .
	replace share_uv=tot_uv/tot_trade
	save cov_per_year, replace
	restore
*nb product lines (by sitc4)
	keep iso_o iso_d product year
	by iso_o iso_d product, sort: drop if _n!=1
	gen nb_lines=_N
	keep nb_lines year
	keep in 1
	joinby year using cov_per_year, unmatched(both) update
	drop _merge
	save cov_per_year, replace
	clear
}
**comparison cov_per_year_pair: list pairs per year, total trade per pair, share of trade with uv per pair (I do not take unattributed when some attributed and some not)


foreach i of numlist 1962(1)2013 {
	*cd "$dir\SITC_Rev1_wits_bulk\wits_june_2011"
	display "--cov_per_year_pair--------`i'---------------------"
	
*	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`i'.dta", clear
	use cepii-4D-`i', clear	
	drop if iso_d=="WLD"
	drop if iso_o=="WLD"
	drop if iso_o==iso_d
	by iso_o iso_d, sort: egen tot_pair=total(trade_value)
	generate uv = trade_value/quantity
	by iso_o iso_d, sort: egen tot_pair_uv=total(trade_value) if uv!=.
	gen share_uv=tot_pair_uv/tot_pair
	replace share_uv=0 if tot_pair_uv==.
	drop tot_pair_uv
	by iso_o iso_d, sort: drop if _n!=1
	drop qty_token product trade_value uv qty_unit quantity
	capture append using cov_per_year_pair
	save cov_per_year_pair, replace
	clear
}
*uv coverage by pair has more than half pairs with coverage close to total trade covered
*with mean around .8 in 60s; .7 in 70s; .8 in 80s, .9 in 90s
use cov_per_year_pair, clear
collapse (mean) mean=share_uv (p50) median=share_uv, by(year)
clear

**comparison list_year_reporter: list reporters per year + list stable reporters
use cov_per_year_pair, clear
by iso_d year, sort: drop if _n!=1
drop iso_o tot_pair share_uv
by iso_d, sort: gen nb_years=_N
gen stable=0
quietly tabulate year
replace stable=1 if nb_years==r(r)
keep iso_d year nb_year stable
save list_year_reporter, replace


**comparisonlist_reporterbis: keeps only the reporter identifier, and the number of years it is present in data
use list_year_reporter, clear
by iso_d, sort: drop if _n!=1
drop year
save list_reporter, replace
clear
**the stable reporters are: VEN, USA, TUR, TUN, THA, SWE, SGP, PRY, PRT, PHL, NLD, MEX, 
*KOR, JPN, ITA, ISR, ISL, HKG, GRC, GBR, FRA, ESP, DNK, DEU, COL, CHL, CHE, CAN, BRA, ARG

** pour liste partner
use cov_per_year_pair, clear
by iso_o year, sort: drop if _n!=1
drop iso_d tot_pair share_uv
by iso_o, sort: gen nb_years=_N
gen stable=0
quietly tabulate year
replace stable=1 if nb_years==r(r)
keep iso_o year nb_year stable
save list_year_partner, replace


**comparisonlist_partnersbis: keeps only the reporter identifier, and the number of years it is present in data
use list_year_partner, clear
by iso_o, sort: drop if _n!=1
drop year
save list_partner, replace
clear
**the stable reporters are: VEN, USA, TUR, TUN, THA, SWE, SGP, PRY, PRT, PHL, NLD, MEX, 
*KOR, JPN, ITA, ISR, ISL, HKG, GRC, GBR, FRA, ESP, DNK, DEU, COL, CHL, CHE, CAN, BRA, ARG






end 
coverage_bulk

