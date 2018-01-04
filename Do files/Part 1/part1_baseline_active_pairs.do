*This program is no longer used: replaced by "pour graphique coverage partie 1.do"

**This program was written in May 2013
**adapted to follow revision in Nov 2013
**this program computes additional stats on active pairs reported in paper
**to answer questions from jie referees

*****************************
***set directory and matsize
*****************************
clear all
*set mem 700M
set matsize 800
set more off
**at laptop
global dir "G:\LIZA_WORK"
**at OFCE
*global dir "F:\LIZA_WORK"
cd "$dir\GUILLAUME_DAUDIN\REVISION_nov_2013_data"
**directory to save results: "$dir\GUILLAUME_DAUDIN\REVISION_nov_2013_data\filename.dta"
***previously: results saved in "SITC_Rev1_adv_query_2011\REVISION_SPRING_2013\part1"

*******************************
**stats on share zero trade obs
*******************************
capture program drop active
program active
**file2bis: list pairs per year, total trade per pair
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\file2bis", clear
**first store nb of active-inactive observations per year 
assert tot_pair!=.
drop if tot_pair==0
drop if iso_o==iso_d
drop quantity share_uv
by iso_o iso_d year, sort: assert _N==1
foreach n of numlist 1962(1)2009 {
	preserve
	keep if year==`n'
	drop tot_pair
	fillin iso_d iso_o year
	drop if iso_o==iso_d
	by _fillin, sort: egen pairs_year=count(_fillin)
	drop iso_o iso_d 
	by _fillin, sort: drop if _n!=1
	label define _fillin 0 "active" 1 "inactive"
	label values _fillin _fillin
	decode _fillin, gen(active)
	drop _fillin
	if `n'!=1962 {
		append using nb_active_full
	}
	save nb_active_full, replace
	restore
}
*fluctuations in country names in 1990-1992: DDR-FRG/DEU (1990); SUN(1990); CSH(1992)
*therefore: list of active pairs out of potential pairs computed for 1963-1990
**and then for 1993-2009
**create nb potential pairs in 1963-1990
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\file2bis", clear
keep if year<1991
drop if year==1962
drop if tot_pair==0
drop year quantity tot_pair share_uv
by iso_o iso_d, sort: drop if _n!=1
fillin iso_o iso_d
drop if iso_o==iso_d
by _fillin, sort: egen pairs_year=count(_fillin)
drop iso_o iso_d 
by _fillin, sort: drop if _n!=1
label define _fillin 0 "active" 1 "inactive"
label values _fillin _fillin
scalar define nba_6390=pairs_year[1]
scalar define nbia_6390=pairs_year[2]
**same for 1993-2009
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\file2bis", clear
keep if year>1992
drop if tot_pair==0
drop year quantity tot_pair share_uv
by iso_o iso_d, sort: drop if _n!=1
fillin iso_o iso_d
drop if iso_o==iso_d
by _fillin, sort: egen pairs_year=count(_fillin)
drop iso_o iso_d 
by _fillin, sort: drop if _n!=1
label define _fillin 0 "active" 1 "inactive"
label values _fillin _fillin
scalar define nba_9309=pairs_year[1]
scalar define nbia_9309=pairs_year[2]
**same thing but without subperiods
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\file2bis", clear
drop if year==1962
drop if tot_pair==0
replace iso_o="DEU" if iso_o=="FRG" | iso_o=="DDR"
replace iso_d="DEU" if iso_o=="FRG" | iso_o=="DDR"
replace iso_o="CSH" if iso_o=="CZE" | iso_o=="SVK"
replace iso_d="CSH" if iso_o=="CZE" | iso_o=="SVK"
drop if iso_o=="SUN" | iso_d=="SUN"
drop year quantity tot_pair share_uv
by iso_o iso_d, sort: drop if _n!=1
fillin iso_o iso_d
drop if iso_o==iso_d
by _fillin, sort: egen pairs_year=count(_fillin)
drop iso_o iso_d 
by _fillin, sort: drop if _n!=1
label define _fillin 0 "active" 1 "inactive"
label values _fillin _fillin
scalar define nba_6309=pairs_year[1]
scalar define nbia_6309=pairs_year[2]
**combine data on active pairs in subperiod and do graph
use nb_active_full, clear
drop if year==1962
gen double sub_active=.
replace sub_active=nba_6390 if year<1991
replace sub_active=nba_9309 if year>=1993
gen double sub_not=.
replace sub_not=nbia_6390 if year<1991
replace sub_not=nbia_9309 if year>=1993
by year, sort: egen double potential_year=total(pairs_year)
keep if active=="active"
drop active
gen double active=nba_6309 
label var potential_year "tot nb possible pairs in year"
label var active "tot nb active pairs in sample"
label var sub_active "tot nb active pairs in subperiod"
label var sub_not "tot nb never active pairs in subperiod"
label var pairs_year "nb active pairs in year" 
save stats_active_pairs, replace
erase nb_active_full.dta
**graph reported in paper
use stats_active_pairs, clear
capture drop if year==1962
gen double share_year=pairs_year/potential_year
gen double share_period=pairs_year/sub_active
gen double share_sample=pairs_year/active
gen double nb_active=pairs_year/1000
**this graph reports evolution very similar to shape of number of pairs out of total number pairs: not reported
graph twoway (spike nb_active year, lcolor(blue) lpattern(dot) ytitle("number pairs (in thousand)")) /*
*/ (line share_year year, lcolor(red) yaxis(2)) /*
*/ (line share_sample year, lcolor(blue) cmissing(n) yaxis(2)), title("Trading pairs in COMTRADE (1963-2009)") /*
*/ legend(order (1 3 2) label(1 "active pairs") label(2 "share of potential pairs in year") label(3 "share of active in sample"))
**this graph reports evolution of share of active pairs by subsample: more interesting
graph twoway (spike nb_active year, lcolor(blue) lpattern(dot) ytitle("number pairs (in thousand)")) /*
*/ (line share_year year, lcolor(red) yaxis(2)) /*
*/ (line share_period year, lcolor(blue) cmissing(n) yaxis(2)), /*
*/ legend(order (1 3 2) label(1 "active pairs") label(2 "share of potential pairs in year") label(3 "share of subperiod active"))
graph export part1_active_pairs.eps, as(eps) preview(on) replace
clear
end
active

