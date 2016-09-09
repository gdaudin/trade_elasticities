*Program taken up on Sept 9 to correct path in order to work on both computers
*and to use sample to 1962-2013

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities"
	cd "$dir"

}


if "`c(hostname)'" =="ECONCES1" {
*	global dir "/Users/liza/Documents/LIZA_WORK"
*	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015"
	global dir "Y:\ELAST_NONLIN"
	cd "$dir"
}

*create list countries with indication of sample they belong to
capture program drop cntrlist
program cntrlist

if strmatch("`c(username)'","*daudin*")==1 {
	use "Data/For Appendix/cepii_wits_country_list.dta", clear
	merge m:1 iso_o using "R√©sultats/Premi√®re partie/Coverage/list_partner.dta"
	gen status ="P" if _merge==3 
	drop _merge stable
	rename nb_years nb_years_partner
	
	merge m:1 iso_d using "R√©sultats/Premi√®re partie/Coverage/list_reporter.dta"
	replace status =status + "; R" if _merge==3 
	drop _merge stable
	rename nb_years nb_years_reporting

	merge m:m iso_d using "R√©sultats/Appendice/superbal_list_1963.dta"
	bys ccode_wits : keep if _n==1
	replace status = status + "; S" if _merge==3
	drop _merge

	merge m:m iso_o using "R√©sultats/Appendice/superbal_list_1963.dta"
	bys ccode_wits : keep if _n==1
	replace status = status + "; S" if _merge==3
	drop _merge
}

if "`c(hostname)'" =="ECONCES1"  {
	use cepii_wits_country_list, clear
	merge m:1 iso_o using list_partner
	gen status ="P" if _merge==3 
	drop _merge stable
	rename nb_years nb_years_partner


	merge m:1 iso_d using list_reporter
	replace status =status + "; R" if _merge==3 
	drop _merge stable
	rename nb_years nb_years_reporting

	merge m:m iso_d using superbal_list_1963
	bys ccode_wits : keep if _n==1
	replace status = status + "; S" if _merge==3
	drop _merge

	merge m:m iso_o using superbal_list_1963
	bys ccode_wits : keep if _n==1
	replace status = status + "; S" if _merge==3
	drop _merge
}


replace status = "P; R; S" if status == "P; R; S; S"
replace status = "P; S" if status == "P; S; S"

drop ccode_wits iso_o iso_d country_cepii

drop if nb_years_partner==. & nb_years_reporting==.

drop if nb_years_partner==. & nb_years_reporting==.

export excel using "Table4.xlsx", firstrow(variables) replace



