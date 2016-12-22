*This file most heavily revised on Sept 12; 2016:
*corrects for errors in construction of superbalanced sample
*adds construction of balanced sample
*adjusts code for construction of square sample
*runs on correct cepii names and updates graphs for appendix

*base years are : 1962 (full dataset) and 1965 (first year for instrumented sample)

**country coding:
*superbal sample only includes Germany b/c Soviet Union and Czechoslovakia not present as reporter in all years
*balanced sample includes some of Soviet Union and Czechoslovakia (stable partners)
*?*consider running regressions on balanced sample as well? 

*Version Juin 2015 pour Guillaume 
**This program was written in May 2013
*adapted to follow revision in Nov 2013
*this program computes sample of s%table pairs (bal-superbal-square) in 1963-2009
*prepares all graphs for appendix 1 in paper on full-superbal sample coverage

*****************************
***set directory and matsize
*****************************
clear all
set matsize 800
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities"
	cd "$dir/Data/COMTRADE_2015_lite"

}


if "`c(hostname)'" =="ECONCES1" {
*	global dir "/Users/liza/Documents/LIZA_WORK"
*	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015"
	global dir "Y:\ELAST_NONLIN"
	cd "$dir"
}


*********************************
*1*create balanced and superbalanced samples for set of years: 
*balanced: pairs trading in each year
*superbalanced: pairs trading both ways in each year
*********************************

capture program drop superbal
program superbal
**redef_full_pair_tot_trade file has total trade by pair redefined to have SUN, DEU, CSH
if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use cov_per_year_pair, clear
	

*`1' is starting year for the superbalanced sample: 1962 or 1965
*`2' is defined as a fct of `1' to drop unneeded years: nothing or 1962-1964

local 2=`1'-1
local name tot_pair tot_uv
foreach n of local name {
	forvalues i=1962(1)`2' {
		drop if year==`i'
	}
} 

**define local 3 to store total nb of years for pair present in each year
local 3=2013-`1'+1
bys iso_d iso_o : generate test_rep=_N
gen id=.
replace id=0 if test_rep<`3'
replace id=1 if test_rep==`3'
tab id
rename test_rep nb_years

bys iso_o iso_d : keep if _n==1
drop year tot_pair

histogram nb_years, width(5) xtitle("Number of years") title("Pair presence in `1'-2013") fract 
graph export nb_years_pair_presence_`1'_13.eps, replace

*--------------------------------------------------------------------------------
**construct superbalanced sample defined from some year `1' until 2013**
**defined as the set of all pairs which trade both ways in each year of the sample

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use cov_per_year_pair, clear
	
local 2=`1'-1
local name tot_pair tot_uv
foreach n of local name {
	forvalues i=1962(1)`2' {
		drop if year==`i'
	}
} 

*redefine countries that change names (Germany, Soviet Union, Czechoslovakia)
local source o d
local name RUS UKR UZB KAZ BLR AZE GEO TJK MDA KGZ LTU TKM ARM LVA EST
local germany FRG DDR
local center CZE SVK
foreach s of local source {
	foreach n of local name {
		replace iso_`s'="SUN" if iso_`s'=="`n'"
	}	
	foreach g of local germany {
		replace iso_`s'="DEU" if iso_`s'=="`g'"
	}	
	foreach c of local center {
		replace iso_`s'="CSH" if iso_`s'=="`c'"
	}	
}
*keep one obs per year-pair: pairs dropped b/c appeared several times in one year
drop if iso_d==iso_o
bysort year iso_o iso_d: drop if _n!=1

**define local 3 to store total nb of years for pair present in each year
local 3=2013-`1'+1
bys iso_d iso_o : generate test_rep=_N
gen id=.
replace id=0 if test_rep<`3'
replace id=1 if test_rep==`3'
tab id
rename test_rep nb_years

bys iso_o iso_d : keep if _n==1
drop year tot_pair share_uv

keep if id==1
drop id nb_years
saveold balanced_`1'_13, version(12) replace

preserve
*keep iso_o iso_d
if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
save list_stable_`1'_13, replace
*use list_stable_`1'_13, clear
rename iso_o partner
rename iso_d reporter
*switch the two sides
rename partner iso_d
rename reporter iso_o
save tmp_switch, replace
restore
joinby iso_d iso_o using tmp_switch, unmatched(none)
save superbal_`1'_13, replace
erase tmp_switch.dta
erase list_stable_`1'_13.dta
**create file for regressions:
use superbal_`1'_13, clear
keep iso_o iso_d
saveold superbal_list_`1', version(12) replace

end

*RUN SUPERBAL PROGRAM:
*1962: 786 pairs
*superbal 1962
*1963: 1056 pairs
*superbal 1963
*1965: 1286 pairs
*superbal 1965


**compare to 1962-2009 sample:
**there are 37 reporters(partners): 5 new relatively 1962-2009
**these additional reporters are: AUS, AUT, FIN, IRL, SLV 

**********************
*********************************
*2* create square sample for 1962-2013 (1965-2013)
*countries trading with each other country both ways in all years
*********************************
capture program drop square
program square
*local 1 1965
if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use superbal_`1'_13, clear
keep iso_o iso_d 
fillin iso_o iso_d
replace _fillin=0 if iso_o==iso_d
*compute nb of times a given reporter has 0 trade with another country of the sample
reshape wide _fillin, i(iso_d) j(iso_o) string

quietly tabulate iso_d
local i = r(r)
local liste_pays
forvalues n=1(1)`i' {
	local iso_d = iso_d[`n']
	local liste_pays "`liste_pays' `iso_d'"
}

display "`liste_pays'"

foreach c of local liste_pays {
	rename _fillin`c' `c'
}
egen som=rowtotal(`liste_pays')
gsort som
local liste ""
global num=_N
forvalues n=1(1)$num {
	local iso_d = iso_d[`n']
	local liste "`liste' `iso_d'"
}
display "`liste'"
order iso_d `liste'
*nbr countries:
quietly describe
global many=r(N)
**sequential elimination: first shot at for loop (a better loop would try all possible combinations)
*take away country with most 1s, recompute sum of 1s for remaining countries, store countries with 0
*continue until all remaining countries have 0, 
**for starters, repeat procedure 50 to check whether different squares emerge
**then keep biggest remaining squares (if several variants of same size), and check whether bigger square possible
**[alternative would be to ask stata to form all variants of the biggest possible square nullmat
**but I do not know how to do it]
foreach n of numlist 1(1)50 {
	preserve
	local circle=1
	while `circle'<$many {
		capture assert som==0
		if _rc!=0 {
			local first = iso_d[1]
			local last = iso_d[_N]
			drop `last'
			drop if _n==_N
			drop som
			local next_last = iso_d[_N]
			egen som=rowtotal(`first'-`next_last')
			gsort som
			local liste ""
			global num=_N
			forvalues n=1(1)$num {
				local iso_o = iso_d[`n']
				local liste "`liste' `iso_o'"
			}
			order iso_d `liste'
			local circle = `circle'+1
		}
		else {
			display "done at `circle'"
			local j=`j'+1
			scalar define iter`j'=`circle'
			save tmp_square_`circle'_`j', replace
			if `j'>1 {
				scalar define min_iter=min(min_iter,iter`j')
				scalar define max_iter=max(max_iter,iter`j')
			}
			else {
				scalar define min_iter=iter1
				scalar define max_iter=iter1
			}
			local circle = $many
		}
	}
	restore
	local n=`n'+1	
}
*among resulting squares, if squares differ in size, keep biggest squares
scalar define diff=max_iter-min_iter
capture assert diff>0
if _rc==0 {
	foreach n of numlist 1(1)50{
		local k=max_iter
		capture erase tmp_square_`k'_`n'.dta
	}
}

*construct set of obtained squares:
foreach n of numlist 1(1)50 {
	local k=min_iter
	capture use tmp_square_`k'_`n', clear
	if _rc==0 {
		local p=`p'+1
		keep iso_d
		gen sq_`n'=1
		if `p'==1 {
			save sq_`1', replace
		}
		else {
			joinby iso_d using sq_`1', unmatched(both)
			replace sq_`n'=0 if sq_`n'==. & _merge==1
			drop _merge
			save sq_`1', replace
		}
		capture erase tmp_square_`k'_`n'.dta
	}
}
***check whether biggest squares differ in sample of countries:
*foreach n of numlist 1(1)50 {
*	local k=min_iter
*	capture use tmp_square_`k'_`n', clear
*	if _rc==0 {
*		keep iso_d
*		gen sq`k'_`n'=iso_d
*		capture merge 1:1 iso_d using sq_`1', nogen
*		save sq_`1', replace
*		capture erase tmp_square_`k'_`n'.dta
*	}
*}
*drop squares that are identical:
use sq_`1', clear
*reshape long sq`k'_, i(iso_d) j(iter)
*drop if sq`k'==""
*by sq`k'_, sort: gen tot_iter=_N
*by iso_d tot_iter, sort: keep if _n==1
*drop iter sq
*egen double max_iter=max(tot_iter)
*gen int id=0
*replace id=1 if tot_iter==max_iter
*by iso_d id, sort: drop if _n!=1
*keep iso_d id
foreach n of numlist 1/49 {
	local i=`n'+1
	foreach s of numlist `i'/50 {
		capture assert sq_`s'==sq_`n'
		if _rc==0 {
			drop sq_`s'
		}
	}
}	
*choose square that has most frequent countries (.not satisfactory.)
*for each country keep info on nbr squares it appears in:
egen nonmiss=rownonmiss(sq*) 
*keep info on total nbr squares: relabel
reshape long sq_, i(iso_d nonmiss) j(iter)
preserve
keep iter
bysort iter: drop if _n!=1
gen id=_n
save tmp, replace
restore
joinby iter using tmp, unmatched(none)
drop iter
reshape wide sq_, i(iso_d nonmiss) j(id)
egen max_nonmiss=max(nonmiss)
*keep info on stable countries:
gen stable=0
replace stable=1 if nonmiss==max_nonmiss
*there are 18 stable and 8 unstable countries: any square can be chosen (!)
*drop squares that have non-missing the most frequently missing country
*egen nbr_miss=rowmiss(sq*)
*egen max_miss=max(nbr_miss)
*reshape long sq_, i(iso_d nbr_miss max_miss) j(iter)
*preserve
*keep if nbr_miss==max_miss
*drop if sq_==1
*keep iter
*save tmp, replace
*restore
*joinby iter using tmp, unmatched(none)
*erase tmp.dta
*drop if nbr_miss==max_miss
*drop nbr_miss max_miss
*reshape wide sq_, i(iso_d) j(iter)

*any one of these squares is acceptable but one of them has to be chosen
save sq_`1', replace
*choose sq_1 as baseline sample (improve upon this in next version)
keep iso_d sq_1
drop if sq_1==.
drop sq_1
saveold sq_list_`1', version(12) replace
*erase sq_`1'.dta
end

*RUN PROGRAM:
*square 1962
*square 1963
*square 1965
*for 1962: square sample has 19 stable countries (present in all iterations)
*and 1 unstable country: either VEN or ITA: total nbr countries is 20
*for 1963(5): square sample has 19 stable countries (present in all iterations)
*and 4 unstable countries to choose from: total nbr countries is 23

*WHY USE SUPERBAL RATHER THAN SQUARE IN PAPER:
*superbal sample is stable while several square samples can be formed in same year




*************
**use 1962 superbal sample to modify graphs in appendix of paper
*compare total trade for full; balanced; superbalanced; square samples
*1962-2013
*************
capture program drop cover
program cover
if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"

use cov_per_year_pair, clear
	
local source o d
local name RUS UKR UZB KAZ BLR AZE GEO TJK MDA KGZ LTU TKM ARM LVA EST
local germany FRG DDR
local center CZE SVK
foreach s of local source {
	foreach n of local name {
		replace iso_`s'="SUN" if iso_`s'=="`n'"
	}	
	foreach g of local germany {
		replace iso_`s'="DEU" if iso_`s'=="`g'"
	}	
	foreach c of local center {
		replace iso_`s'="CSH" if iso_`s'=="`c'"
	}	
}
drop if iso_o==iso_d

preserve
joinby iso_o iso_d using balanced_`1'_13, unmatched(none)
collapse (sum) tot_bal=tot_pair, by(year)
replace tot_bal=tot_bal*10^(-9)
*initially trade measured in thsd usd, therefore scale is trillion
save tmp_tot_bal, replace
restore

preserve
joinby iso_o iso_d using superbal_list_`1', unmatched(none)
collapse (sum) tot_superbal=tot_pair, by(year)
replace tot_superbal=tot_superbal*10^(-9)
*initially trade measured in thsd usd, therefore scale is trillion
save tmp_tot_superbal, replace
restore

preserve
**use square list to keep square sample 
use sq_list_`1', clear
gen iso_o=iso_d
fillin iso_o iso_d
drop if iso_o==iso_d
drop _fillin
save tmp_square, replace
restore

preserve
joinby iso_o iso_d using tmp_square, unmatched(none)
collapse (sum) tot_square=tot_pair, by(year)
replace tot_sq=tot_sq*10^(-9)
erase tmp_square.dta
joinby year using tmp_tot_bal, unmatched(none)
joinby year using tmp_tot_superbal, unmatched(none)
erase tmp_tot_superbal.dta
save coverage, replace
restore

collapse (sum) tot_full=tot_pair, by(year)
replace tot_full=tot_full*10^(-9)
joinby year using coverage, unmatched(none)
saveold coverage_`1', version(12) replace

**construct coverage comparison
use coverage_`1', clear
gen double cov_bal_to_full=tot_bal/tot_full
gen double cov_superbal_to_full=tot_superbal/tot_full
gen double cov_square_to_full=tot_sq/tot_full
twoway (connected cov_bal_to_full year, ytitle("Share of total trade", axis(1)) ylabel(.2(.1).8, angle(horizontal) axis(1) nogrid) lcolor(dknavy) lwidth(medium) msymbol(point) mcolor(dknavy)) /*
*/ (connected cov_superbal_to_full year,  lcolor(blue) lwidth(medium) msymbol(point) mcolor(blue)) /*
*/ (connected cov_square_to_full year,  lcolor(red) lwidth(medium) msymbol(point) mcolor(red)) /*
*/(spike tot_full year, lcolor(gs4) lpattern(shortdash) yaxis(2) ytitle("Trillions of USD", axis(2)) yscale(titlegap(medsmall) axis(2)) ylabel(0(2.5)15, angle(horizontal) grid glwidth(vthin) glcolor(bluishgray) axis(2))) , /*
*/title("Trade coverage: stable pairs")/* 
*/legend(label(1 "Balanced") label(2 "Superbalanced") label(3 "Square") label(4 "Trade in full sample [right scale]")) /*
*/ yscale(axis(2) range (0 15)) ylabel(0(3)15, axis(2)) yscale(axis(2) range (0 1)) ylabel(0(0.2)1, axis(1))

graph export trade_coverage_`1'.eps, replace
clear
erase coverage.dta
end
*RUN PROGRAM
*cover 1962
*cover 1965


******************************
**check using reciprocal trade
******************************
**how much of total annual trade covered by pairs
**which trade both ways in 1962 (1965)
capture program drop recip
program recip

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use cov_per_year_pair, clear

*local 1 1962
local 2=`1'-1900
keep iso_o iso_d tot_pair year
keep if year==`1'
drop if tot_pair==. | tot_pair==0
preserve
keep iso_o iso_d
save list_`2', replace
use list_`2', clear
rename iso_o partner
rename iso_d reporter
*switch the two sides: 
rename partner iso_d
rename reporter iso_o
save tmp_switch, replace
restore
joinby iso_d iso_o using tmp_switch, unmatched(none)
keep iso_o iso_d
save recip`2', replace
erase tmp_switch.dta

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use cov_per_year_pair, clear
	
drop share_uv
joinby iso_o iso_d using recip`2', unmatched(none)
*reshape long tot_pair, i(iso_o iso_d) j(year)
**save data on total annual trade in reciprocal sample
collapse (sum) recip_`1'=tot_pair,by(year)
replace recip_`1'=recip_`1'*10^(-9)
merge 1:1 year using coverage_`1', update replace nogen norep
saveold coverage_`1', version(12) replace
clear
end

*RUN PROGRAM
*not great for coverage b/c break when country names change
*recip 1962
*recip 1965

*add data on annual reciprocal trade:
*previously constructed file contains reciprocal trade by year
*eg if we take pairs which trade both ways in a given year, how much that is out of total trade
capture program drop annual
program annual

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use cov_per_year_pair, clear
	
keep iso_o iso_d tot_pair year
drop if tot_pair==. | tot_pair==0
preserve
keep iso_o iso_d year
save list, replace
use list, clear
rename iso_o partner
rename iso_d reporter
*switch the two sides: 
rename partner iso_d
rename reporter iso_o
save tmp_switch, replace
restore
joinby iso_d iso_o year using tmp_switch, unmatched(none)
keep iso_o iso_d year
save recip, replace
erase tmp_switch.dta

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie/Coverage/"
use cov_per_year_pair, clear
	
drop share_uv
joinby iso_o iso_d year using recip, unmatched(none)
*reshape long tot_pair, i(iso_o iso_d) j(year)
**save data on total annual trade in reciprocal sample
collapse (sum) recip=tot_pair,by(year)
replace recip=recip*10^(-9)
merge 1:1 year using coverage_1962, update replace nogen norep
saveold coverage_1962, version(12) replace

*graph for paper on reciprocal trade
*add info on recip65:
use coverage_1965, clear
keep recip_1965 year 
merge 1:1 year using coverage_1962, update replace nogen norep
gen double cov_recip65=recip_1965/tot_full
gen double cov_recip62=recip_1962/tot_full
gen double cov_recipannual=recip/tot_full
twoway (connected cov_recip62 year, ytitle("Coverage reciprocal trade") ylabel(.4(.1)1, angle(horizontal) grid glwidth(vthin) glcolor(bluishgray)) lcolor(blue) lwidth(medium) msymbol(point) mcolor(blue)) /*
*/ (connected cov_recip65 year, ytitle("Coverage reciprocal trade") ylabel(.4(.1)1, angle(horizontal) grid glwidth(vthin) glcolor(bluishgray)) lcolor(red) lwidth(medium) msymbol(point) mcolor(red)) /*
*/ (connected cov_recipannual year, lpattern(solid) lcolor(black) lwidth(medthick) msymbol(point) mcolor(black)), /*
*/title("Reciprocal trade share")/* 
*/legend(label(1 "Reciprocal 1962") label(2 "Reciprocal 1965") label(3 "Reciprocal annual"))
graph export recip_coverage_62_65.eps, replace
end
*RUN PROGRAM
*annual
*coverage in reciprocal sample based on some year decreases more steeply
*than coverage in superbal sample b/c no name adjustment

*RUN PROGRAMS:
local year 1962 1963 1965
foreach y of local year {
	superbal `y'
	square `y'
	cover `y'
	recip `y'
}
