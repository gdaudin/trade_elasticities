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
**at laptop
*global dir "G:\LIZA_WORK"
**at OFCE
*global dir "F:\LIZA_WORK"
*cd "$dir\GUILLAUME_DAUDIN\REVISION_nov_2013_data"
**directory to save results: "$dir\GUILLAUME_DAUDIN\REVISION_nov_2013_data\filename.dta"
***previously results saved in "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\REVISION_SPRING_2013\part1"


*GD
global dir "~/Documents/Recherche/OFCE Substitution Elasticities"
cd "$dir"






**1**create superbalanced sample for some subset of years: 
*pairs trading both ways in each year
capture program drop superbal
program superbal
**redef_full_pair_tot_trade file has total trade by pair redefined to have SUN, DEU, CSH
*use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\redef_full_pair_tot_trade", clear
use "$dir/Résultats/Première partie/Coverage/cov_per_year_pair.dta"

*`1' is starting year for the superbalanced sample: 1963 or 1970
*`2' is defined as a fct of `1' to drop unneeded years: 1962 or 1962-1969






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
**There are 2712 stable pairs (trade in each year in 1963-2009) and 29112 unstable pairs 
**The median pair is present in the sample for 15 years, IQR is 6-31 years, with mean at 19.1

bys iso_o iso_d : keep if _n==1
drop year tot_pair

histogram nb_years, width(5) xtitle("Number of years") title("Pair presence in `1'-2013") fract 
graph export nb_years_pair_presence_`1'_13.eps, replace


*--------------------------------------------------------------------------------
**construct superbalanced sample defined from some year `1' until 2013**
**defined as the set of all pairs which trade both ways in each year of the sample


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

collapse (max) id, by(iso_d iso_o)


keep if id==1
drop id
preserve
keep iso_o iso_d
save list_stable_`1'_13, replace
use list_stable_`1'_13, clear
rename iso_o partner
rename iso_d reporter
*switch the two sides
rename partner iso_d
rename reporter iso_o
save tmp_switch, replace
restore
joinby iso_d iso_o using tmp_switch, unmatched(none)
**this leaves 1056 pairs which trade both ways in 63-09 out of 1332 potential pairs (37 reporters)
save superbal_`1'_13, replace
erase tmp_switch.dta
erase list_stable_`1'_13.dta
**create file for regressions:
use superbal_`1'_13, clear
keep iso_o iso_d
save superbal_list_`1', replace


end


**compare to 1962-2009 sample:
**there are 37 reporters(partners): 5 new relatively 1962-2009
**these additional reporters are: AUS, AUT, FIN, IRL, SLV 
**there are 270 additional pairs added to initial 786 pairs
**ie 528 pairs which trade both ways in all years
*use superbal_`1'_09, clear
*by iso_d, sort: keep if _n==1
*keep iso_d
*joinby iso_d using "$dir\SITC_Rev1_adv_query_2011\superbal", unmatched(both)
*keep if _merge==1
*keep iso_d
*clear
*use superbal_`1'_09, clear
*joinby iso_o iso_d using "$dir\SITC_Rev1_adv_query_2011\superbal", unmatched(both)
*keep if _merge==1
*keep iso_o iso_d
**********************


capture program drop square
program square

**create square sample corresponding to 1963 (ou 1970)-2013


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
**sequential elimination: first shot at for loop (a better loop would try all possible combinations)
*take away country with most 1s, recompute sum of 1s for remaining countries, store countries with 0
*continue until all remaining countries have 0, 
**for starters, repeat procedure 40 times to check whether different squares emerge
**then keep biggest remaining squares (if several variants of same size), and check whether bigger square possible
**[alternative would be to ask stata to form all variants of the biggest possible square nullmat
**but I do not know how to do it]
foreach n of numlist 1(1)40 {
	preserve
	local circle=1
	while `circle'<20 {
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
			local circle = 20
		}
	}
	restore
}
***among resulting squares, keep biggest squares
*scalar define diff=max_iter-min_iter
*assert diff==1
*if _rc==0 {
foreach n of numlist 1(1)40{
	local k=max_iter
	capture erase tmp_square_`k'_`n'.dta
}
*}
***check whether biggest squares differ in sample of countries:
foreach n of numlist 1(1)40 {
	local k=min_iter
	capture use tmp_square_`k'_`n', clear
	if _rc==0 {
		keep iso_d
		gen sq`k'_`n'=iso_d
		capture merge 1:1 iso_d using sq_`1', nogen
		save sq_`1', replace
		capture erase tmp_square_`k'_`n'.dta
	}
}
reshape long sq15_, i(iso_d) j(iter)
drop if sq15==""
by sq15_, sort: gen tot_iter=_N
by iso_d tot_iter, sort: keep if _n==1
drop iter sq15_
egen double max_iter=max(tot_iter)
gen int id=0
replace id=1 if tot_iter==max_iter
by iso_d id, sort: drop if _n!=1
keep iso_d id
save sq_list_`1', replace
erase sq_`1'.dta
end
**not done: check whether some alternative would give more countries in square sample (24)
**NB: code for square not suitable when each variant has more than one excluded country: keep track of each variant
**conclude: 22*21 is stable sample (identified with id=1; 23rd country has to be chosen: either ISR or MYS)
**REMEMBER: I worked with 1970-2009 in appendix b/c 1970 is first year with more than 100 reporters
*in 1962: 71 reporters; in 1970: 112 reporters
*superbal sample is stable while several square samples can be formed in same year
*therefore: I will work with superbalanced not square in baseline 




*************
**use 1963 superbal sample to modify graphs in appendix of paper
*compare total trade for full sample; superbalanced sample; square sample
*1963-2009
*************
capture program drop cover
program cover
use "$dir/Résultats/Première partie/Coverage/cov_per_year_pair.dta"

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


preserve
joinby iso_o iso_d using superbal_list_1963, unmatched(none)
collapse (sum) tot_superbal=tot_pair, by(year)
replace tot_superbal=tot_superbal*10^(-9)
*initially trade measured in thsd usd, therefore scale is trillion
save tmp_tot_superbal, replace

restore
preserve
**use square list to keep square sample: either MYS or ISR 
*basically these two countries trade with everybody else, but not with each other
*for simplicity keep both
use sq_list_1963, clear
gen iso_o=iso_d
fillin iso_o iso_d
drop if iso_o==iso_d
drop id _fillin
save tmp_square, replace

restore
preserve
joinby iso_o iso_d using tmp_square, unmatched(none)
collapse (sum) tot_square=tot_pair, by(year)
replace tot_sq=tot_sq*10^(-9)
erase tmp_square.dta
joinby year using tmp_tot_superbal, unmatched(none)
erase tmp_tot_superbal.dta
save coverage, replace

restore
collapse (sum) tot_full=tot_pair, by(year)
replace tot_full=tot_full*10^(-9)
joinby year using coverage, unmatched(none)
save coverage, replace
**construct coverage comparison 
use coverage, clear
gen double cov_superbal_to_full=tot_superbal/tot_full
gen double cov_square_to_full=tot_sq/tot_full
drop if year==1962
twoway (connected cov_superbal_to_full year, ytitle("Share of total trade", axis(1)) ylabel(.2(.1).8, angle(horizontal) axis(1) nogrid) lcolor(dknavy) lwidth(medium) msymbol(point) mcolor(dknavy)) /*
*/ (connected cov_square_to_full year,  lcolor(red) lwidth(medium) msymbol(point) mcolor(red)) /*
*/(spike tot_full year, lcolor(blue) lpattern(shortdash) yaxis(2) ytitle("Trillions of USD", axis(2)) yscale(titlegap(medsmall) axis(2)) ylabel(0(2.5)15, angle(horizontal) grid glwidth(vthin) glcolor(bluishgray) axis(2))) , /*
*/title("Trade coverage: stable pairs")/* 
*/legend(label(1 "Superbalanced sample") label(2 "Square sample") label(3 "Trade in full sample [right scale]"))
graph export trade_coverage_1963.eps, replace

/*
**same exercise with superbal in 1970
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\redef_full_pair_tot_trade", clear
reshape long tot_pair tot_uv, i(iso_d iso_o) j(year)
drop tot_uv id nb_years
joinby iso_o iso_d using superbal_list_1970, unmatched(none)
collapse (sum) tot_superbal=tot_pair, by(year)
gen double tot_superbal70=tot_superbal*10^(-9)
drop tot_superbal
joinby year using coverage, unmatched(none)
gen double cov_superbal70=tot_superbal70/tot_full
gen double cov_superbal_to_full=tot_superbal/tot_full
gen double cov_square_to_full=tot_sq/tot_full
drop if year<1970
twoway (connected cov_superbal_to_full year, ytitle("Share of total trade", axis(1)) ylabel(.2(.1).8, angle(horizontal) axis(1) nogrid) lcolor(dknavy) lwidth(medium) msymbol(point) mcolor(dknavy)) /*
*/ (connected cov_superbal70 year,  lcolor(red) lwidth(medium) msymbol(point) mcolor(red)) /*
*/(spike tot_full year, lcolor(blue) lpattern(shortdash) yaxis(2) ytitle("Trillions of USD", axis(2)) yscale(titlegap(medsmall) axis(2)) ylabel(0(2.5)15, angle(horizontal) grid glwidth(vthin) glcolor(bluishgray) axis(2))) , /*
*/title("Trade coverage in superbalanced samples")/* 
*/legend(label(1 "Superbal 1963") label(2 "Superbal 1970") label(3 "Trade in full sample [right scale]"))
graph export trade_coverage_63_70.eps, replace
*/
end


******************************
**check using reciprocal trade
******************************
**how much of total annual trade covered by pairs
**which trade both ways in 1963(1970)
capture program drop recip
program recip
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\redef_full_pair_tot_trade", clear
keep iso_o iso_d tot_pair`1' 
drop if tot_pair`1'==. | tot_pair`1'==0
preserve
keep iso_o iso_d
save list_`2', replace
use list_`2', clear
rename iso_o partner
rename iso_d reporter
*switch the two sides
rename partner iso_d
rename reporter iso_o
save tmp_switch, replace
restore
joinby iso_d iso_o using tmp_switch, unmatched(none)
keep iso_o iso_d
save reciprocal`2', replace
erase tmp_switch.dta
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\redef_full_pair_tot_trade", clear
drop nb_years id tot_uv*
joinby iso_o iso_d using reciprocal`2', unmatched(none)
reshape long tot_pair, i(iso_o iso_d) j(year)
**save data on total annual trade in reciprocal sample
collapse (sum) recip_`1'=tot_pair,by(year)
replace recip_`1'=recip_`1'*10^(-9)
merge 1:1 year using coverage, update replace nogen norep
save coverage, replace
clear
end

*add data on annual reciprocal trade:
*previously constructed file contains reciprocal trade by year
*eg if we take pairs which trade both ways in a given year, how much that is out of total trade
capture program drop annual
program annual
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\recip_sample", clear
drop tot_uv
collapse (sum) recip_annual=tot_pair,by(year)
replace recip_annual=recip_annual*10^(-9)
merge 1:1 year using coverage, update replace nogen norep
save coverage, replace
***************************
**GRAPH FOR PAPER**RECIPROCAL TRADE**
use coverage, clear
gen double cov_recip63=recip_1963/tot_full
gen double cov_recip70=recip_1970/tot_full
gen double cov_recipannual=recip_annual/tot_full
drop if year<1963
twoway (connected cov_recip63 year, ytitle("Coverage reciprocal trade") ylabel(.4(.1)1, angle(horizontal) grid glwidth(vthin) glcolor(bluishgray)) lcolor(blue) lwidth(medium) msymbol(point) mcolor(blue)) /*
*/ (connected cov_recip70 year, lcolor(red) lwidth(medium) msymbol(point) mcolor(red)) /*
*/ (connected cov_recipannual year, lpattern(solid) lcolor(black) lwidth(medthick) msymbol(point) mcolor(black)), /*
*/title("Reciprocal trade share")/* 
*/legend(label(1 "Reciprocal 1963") label(2 "Reciprocal 1970") label(3 "Reciprocal annual"))
graph export recip_coverage_63_70.eps, replace
end








superbal 1963

*superbal 1970
square 1963

*square 1970 (ne marche pas ?)

cover


recip 1963 63
recip 1970 70

annual
