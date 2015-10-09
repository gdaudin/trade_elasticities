*Sept 10th, 2015*

*This file takes PWT data in 8.1 edition of Penn World Tables
*checks country correspondence to data extracted from UN COMTRADE
*prepares for each year the set of GDP data: lagged info for 1-2-3 years

*in PWT: countrycode is 3letter code

****************************************
*set directory*
****************************************
set more off



display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
	cd "$dir/Data/For Third Part/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}









******************************************************
*get PWT data into STATA: 
******************************************************
capture program drop pwtin
program pwtin
*insheet PWT data: change codes for 3 countries:
*ROM instead of ROU for Romania
*SER instead of SRB for Serbia
*ZAR instead of COD for Democratic Republic of Congo
**one country doesn't match: MNE (Montenegro)

if "`c(hostname)'" =="ECONCES1" {
	use13 "$dir/EKpaper_data/revision_data_2015/pwt81/pwt81.dta", clear
}


if strmatch("`c(username)'","*daudin*")==1 {
	use pwt81.dta, clear

}

replace countrycode="ROM" if countrycode=="ROU"
replace countrycode="SER" if countrycode=="SRB"
replace countrycode="ZAR" if countrycode=="COD"

save pwt81,replace


clear
end
pwtin

*******************************************************************************
*reorganize PWT 8.1 in annual files with lagged GDP-investment-cap stock price levels 
*******************************************************************************
capture program drop prepwt
program prepwt
use pwt81, clear


if "`c(hostname)'" =="ECONCES1" {
	rename countrycode iso_o
	joinby iso_o using "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_o_91_06", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}


if strmatch("`c(username)'","*daudin*")==1 {
	rename countrycode iso
	joinby iso using "../Comparaison Wits Cepii.dta", unmatched(none)
	drop iso
	rename cepii iso_o

}







*keep relevant variables: price level of domestic absorption; price level of domestic output, price level of investment, price level of capital stock
keep iso_o year pl_da pl_gdpo pl_i pl_k
drop if pl_gdpo==.
drop if year<1962
save tmp_pwt81, replace




**first approach to constructing annual files for instrumenting unit values:
*group data by 5-year period: start in 1967; finish in 2011
use tmp_pwt81, clear
foreach n of numlist 1965/2011 {
	preserve
	local i=`n'-3
	local j=`n'-1
	keep if year>=`i' & year<=`n'
	local vars da gdpo i k
	foreach v of local vars {
		rename pl_`v' `v'_
	}
	reshape wide da_ gdpo_ i_ k_, i(iso_o) j(year)
	foreach t of numlist `i'/`j' {
		foreach v of local vars {
			gen double rel_`v'_`t'=`v'_`n'/`v'_`t'
			drop `v'_`t'
		}
	}	
	foreach v of local vars {
		drop `v'_`n'
	}
	gen year=`n'
	save tmp_pwt81_`n', replace
	restore
}
erase tmp_pwt81.dta
clear
end
prepwt
*EX: tmp_pwt81_1965.dta contains price levels for 1965 rel. 1964-1962: gdp, da, i, k
*gdp-da very strongly correlated; idem for i-k; but gdp-i(k) much less correlated

