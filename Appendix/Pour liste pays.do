global dir "~/Documents/Recherche/OFCE Substitution Elasticities/"
cd "$dir"


use "Data/For Appendix/cepii_wits_country_list.dta", clear



merge m:1 iso_o using "Résultats/Première partie/Coverage/list_partner.dta"
gen status ="P" if _merge==3 
drop _merge stable
rename nb_years nb_years_partner


merge m:1 iso_d using "Résultats/Première partie/Coverage/list_reporter.dta"
replace status =status + "; R" if _merge==3 
drop _merge stable
rename nb_years nb_years_reporting

merge m:m iso_d using "Résultats/Appendice/superbal_list_1963.dta"
bys ccode_wits : keep if _n==1
replace status = status + "; S" if _merge==3
drop _merge

merge m:m iso_o using "Résultats/Appendice/superbal_list_1963.dta"
bys ccode_wits : keep if _n==1
replace status = status + "; S" if _merge==3
drop _merge

replace status = "P; R; S" if status == "P; R; S; S"
replace status = "P; S" if status == "P; S; S"

drop ccode_wits iso_o iso_d country_cepii

drop if nb_years_partner==. and nb_years_reporting==.

drop if nb_years_partner==. & nb_years_reporting==.

export excel using "/Users/guillaumedaudin/Documents/Recherche/OFCE Substitution Elasticities/Table4.xlsx", firstrow(variables) replace



