*March 12th, 2018*
*adjusted to pwt 9.0 and to work on liza's laptop
*Sept 10th, 2015*

*This file takes PWT data in 9.0 edition of Penn World Tables
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

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013_in2018"
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
*put data*		use "$dir/pwt90/pwt90.dta", clear
	}
	
	
	if strmatch("`c(username)'","*daudin*")==1 {
		use PWT/pwt90.dta, clear
	
	}
	
	if "`c(hostname)'" =="LAmacbook.local" {
		use "$dir/GUILLAUME_DAUDIN/pwt90/pwt90.dta", clear
	}	

	replace countrycode="ROM" if countrycode=="ROU"
	replace countrycode="SER" if countrycode=="SRB"
	replace countrycode="ZAR" if countrycode=="COD"
	
	
	cd "$dir/Data_Interm/Third_Part/PWT"
	save tmp_pwt90,replace
	
	
	clear
end
pwtin

*******************************************************************************
*reorganize PWT 9.0 in annual files with lagged GDP-investment-cap stock price levels 
*******************************************************************************
capture program drop prepwt
program prepwt
	use tmp_pwt90.dta, clear
	
	
	if "`c(hostname)'" =="ECONCES1" {
		rename countrycode iso_o
		joinby iso_o using "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_o_91_06", unmatched(none)
		drop iso_o
		rename ccode_cepii iso_o
	}
	
	
	if strmatch("`c(username)'","*daudin*")==1 {
		rename countrycode iso
		joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
		drop iso
		rename cepii iso_o
	
	}
	
	
	
	
	
	
	
	*keep relevant variables: price level of exports, price level of domestic absorption; price level of domestic output, price level of investment, price level of capital stock
	keep iso_o year pl_x pl_da pl_gdpo pl_i pl_k
	drop if pl_x==.
	drop if year<1962
	save tmp_pwt90, replace
	
	
	
	
	**first approach to constructing annual files for instrumenting unit values:
	
	foreach year of numlist 1963/2014 {
		use tmp_pwt90, clear
	
		if `year' == 1963 local laglist 1
		if `year' == 1964 local laglist 1/2
		if `year' >= 1965 local laglist 1/3
	
	
		local i = `year'-3
		
		keep if year>=`i' & year<=`year'
		local liste_instr x da gdpo i k
		foreach v of local liste_instr {	
			rename pl_`v' `v'_
		}
		
		reshape wide x_ da_ gdpo_ i_ k_, i(iso_o) j(year)
	*	blouk
		foreach lag of numlist `laglist' {
			foreach instr of local liste_instr {
				local lagyear=`year'-`lag'
				gen double rel_`instr'_lag_`lag'=`instr'_`year'/`instr'_`lagyear'
				drop `instr'_`lagyear'			
				label var rel_`instr'_lag_`lag' "Evolution of `instr' prices btw t-`lag' & t"
			}
		}
		foreach instr of local liste_instr {
			drop `instr'_`year'
		}		
		gen year=`year'
		save tmp_pwt90_`year', replace
	}
	erase tmp_pwt90.dta
end
prepwt
*EX: tmp_pwt90_1965.dta contains price levels for 1965 rel. 1964-1962: x, gdp, da, i, k
*gdp-da very strongly correlated; idem for i-k; but gdp-i(k) much less correlated

