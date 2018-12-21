*This program was taken up on Sept 9 to adjust to sample: 1962-2013
*NB: program runs on latest version of cov_per_year_pair.dta (cepii names)

**This program was written in May 2013
**adapted to follow revision in Nov 2013
**this program computes additional stats on active pairs reported in paper
**to answer questions from jie referees

** Reprise 25 juin 2015 GD

*****************************
***set directory and matsize
*****************************
set more off
clear all

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/2007 OFCE Substitution Elasticities local"
	cd "$dir"

}


if "`c(hostname)'" =="ECONCES1" {
*	global dir "/Users/liza/Documents/LIZA_WORK"
*	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015"
	global dir "Y:\ELAST_NONLIN"
	cd "$dir"
}



*******************************
**stats on share zero trade obs
*******************************
capture program drop active
program active
if strmatch("`c(username)'","*daudin*")==1 {
*replace e dans resultats et premiere par e avec accent
	use "$dir/Résultats/Première partie/Coverage/cov_per_year_pair.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cov_per_year_pair, clear
}
capture erase nb_active_full.dta

**first store nb of active-inactive observations per year 
assert tot_pair!=.
drop if tot_pair==0
drop if iso_o==iso_d
drop share_uv
by iso_o iso_d year, sort: assert _N==1
foreach n of numlist 1962(1)2013 {
	display "--active-inactive obs--------`n'---------------------"
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
	capture append using nb_active_full
	save nb_active_full, replace
	restore
}
*fluctuations in country names in 1990-1992: DDR-FRG/DEU (1990); SUN(1990); CSH(1992)
*therefore: list of active pairs out of potential pairs computed for 1963-1990
**and then for 1993-2013
**create nb potential pairs in 1963-1990
if strmatch("`c(username)'","*daudin*")==1 {
*replace e dans resultats et premiere par e avec accent
	use "$dir/Résultats/Première partie/Coverage/cov_per_year_pair.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cov_per_year_pair, clear
}	
keep if year<1991
*drop if year==1962
drop if tot_pair==0
drop year tot_pair share_uv
by iso_o iso_d, sort: drop if _n!=1
fillin iso_o iso_d
drop if iso_o==iso_d
by _fillin, sort: egen pairs_year=count(_fillin)
drop iso_o iso_d 
by _fillin, sort: drop if _n!=1
label define _fillin 0 "active" 1 "inactive"
label values _fillin _fillin
scalar define nba_6290=pairs_year[1]
scalar define nbia_6290=pairs_year[2]

**same for 1993-2009
if strmatch("`c(username)'","*daudin*")==1 {
*replace e dans resultats et premiere par e avec accent
	use "$dir/Résultats/Première partie/Coverage/cov_per_year_pair.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cov_per_year_pair, clear
}
keep if year>1992
drop if tot_pair==0
drop year tot_pair share_uv
by iso_o iso_d, sort: drop if _n!=1
fillin iso_o iso_d
drop if iso_o==iso_d
by _fillin, sort: egen pairs_year=count(_fillin)
drop iso_o iso_d 
by _fillin, sort: drop if _n!=1
label define _fillin 0 "active" 1 "inactive"
label values _fillin _fillin
scalar define nba_9313=pairs_year[1]
scalar define nbia_9313=pairs_year[2]
**same thing but without subperiods
	use "$dir/Résultats/Première partie/Coverage/cov_per_year_pair.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cov_per_year_pair, clear
}	
*drop if year==1962
drop if tot_pair==0
replace iso_o="DEU" if iso_o=="FRG" | iso_o=="DDR"
replace iso_d="DEU" if iso_o=="FRG" | iso_o=="DDR"
replace iso_o="CSH" if iso_o=="CZE" | iso_o=="SVK"
replace iso_d="CSH" if iso_o=="CZE" | iso_o=="SVK"
drop if iso_o=="SUN" | iso_d=="SUN"
drop year tot_pair share_uv
by iso_o iso_d, sort: drop if _n!=1
fillin iso_o iso_d
drop if iso_o==iso_d
by _fillin, sort: egen pairs_year=count(_fillin)
drop iso_o iso_d 
by _fillin, sort: drop if _n!=1
label define _fillin 0 "active" 1 "inactive"
label values _fillin _fillin
scalar define nba_6213=pairs_year[1]
scalar define nbia_6213=pairs_year[2]

**combine data on active pairs in subperiod and do graph
use nb_active_full, clear
*drop if year==1962
gen double sub_active=.
replace sub_active=nba_6290 if year<1991
replace sub_active=nba_9313 if year>=1993
gen double sub_not=.
replace sub_not=nbia_6290 if year<1991
replace sub_not=nbia_9313 if year>=1993
by year, sort: egen double potential_year=total(pairs_year)
keep if active=="active"
drop active
gen double active=nba_6213 
label var potential_year "tot nb possible pairs in year"
label var active "tot nb active pairs in sample"
label var sub_active "tot nb active pairs in subperiod"
label var sub_not "tot nb never active pairs in subperiod"
label var pairs_year "nb active pairs in year" 
save stats_active_pairs, replace
erase nb_active_full.dta
**graph reported in paper

use stats_active_pairs, clear
*drop if year==1962
gen double share_year=pairs_year/potential_year
gen double share_period=pairs_year/sub_active
gen double share_sample=pairs_year/active
gen double nb_active=pairs_year/1000
**this graph reports evolution very similar to shape of number of pairs out of total number pairs: not reported
graph twoway (spike nb_active year, lcolor(blue) lpattern(dot) ytitle("number pairs (in thousand)")) /*
*/ (line share_year year, lcolor(red) yaxis(2)) /*
*/ (line share_sample year, lcolor(blue) cmissing(n) yaxis(2)), title("Trading pairs in COMTRADE (1963-2013)") /*
*/ legend(order (1 3 2) label(1 "active pairs") label(2 "share of potential pairs in year") label(3 "share of active in sample"))
**this graph reports evolution of share of active pairs by subsample: more interesting
graph twoway (spike nb_active year, lcolor(blue) lpattern(dot) xtitle("year" " ") ytitle( "# pairs (in thousand)" " ")) /*
*/ (line share_year year, lcolor(red) yaxis(2) r1title("share" " ")) /*
*/ (line share_period year, lcolor(blue) cmissing(n) yaxis(2)), /*
*/ legend(order (2 1 3) label(1 "# active pairs") label(2 "share of potential pairs") label(3 "share of active pairs in subperiod")) /*
*/ yscale(axis(1) range (0 30)) ylabel(0(5)30, axis(1)) yscale(axis(1) range (0 1)) ylabel(0(0.2)1, axis(2)) scheme(s1mono)
graph export "$dir/Git/trade_elasticities/Rédaction/tex/part1_active_pairs.eps, as(eps) preview(on) replace
clear
end
active

