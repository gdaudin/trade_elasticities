display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/2007 OFCE Substitution Elasticities local/"
	global dirgit "~/Documents/Recherche/2007 OFCE Substitution Elasticities local/Git/"
}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}

*for laptop Liza
if "`c(hostname)'" =="LAmacbook.local" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	global dirgit "/Users/liza/Documents/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013_in2018"
}



*******Constitution de la base de données

capture erase "$dir/Data_Interm/First_Part/data_for_graph_disp.dta"
foreach year of numlist 1962(1)2013 {
	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`year'.dta", clear
	collapse (count) trade_value, by(iso_d product)
	bys iso_d : gen nbr_prod=_N
	bys iso_d : keep if _n==1
	keep iso_d nbr_prod
	gen sample ="full"
	gen year=`year'
	capture append using "$dir/Data_Interm/First_Part/data_for_graph_disp.dta"
	save "$dir/Data_Interm/First_Part/data_for_graph_disp.dta", replace
	
	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`year'.dta", clear
	merge m:1 iso_o iso_d using "$dir/Résultats/Première partie/Coverage/superbal_list_1962.dta", keep(match)
	collapse (count) trade_value, by(iso_d product)
	bys iso_d : gen nbr_prod=_N
	bys iso_d : keep if _n==1
	keep iso_d nbr_prod
	gen sample ="superbal"
	gen year=`year'
	append using "$dir/Data_Interm/First_Part/data_for_graph_disp.dta"
	save "$dir/Data_Interm/First_Part/data_for_graph_disp.dta", replace	
}


*******Faire les graphique

use "$dir/Data_Interm/First_Part/data_for_graph_disp.dta", replace	
egen standard_dev=sd(nbr_prod), by (sample year)
graph twoway (line standard_dev year if sample=="full") ///
			 (line standard_dev year if sample=="superbal") ///
			 (lfit standard_dev year if sample=="full") ///
			 (lfit standard_dev year if sample=="superbal") ///
			, legend (order(1 2) label(1 "Full sample") label(2 "Superbalanced sample")) ///
			ytitle("Standard deviation" "in the number of products" "exported by each country") ///
			caption("At SITC 4-digit, COMTRADE data, samples defined in the text") scheme(s1mono)

graph export "$dir/Résultats/Première Partie/Fall_of_SD.pdf", replace			
graph export "$dir/Git/trade_elasticities/Rédaction/tex/Fall_of_SD.pdf", replace						
			
keep if year==1970 | year==1980 | year==1990 | year==2000 | year==2010

vioplot nbr_prod  if sample=="full" ///
		, ytitle("number of exported products" "by country") title("full sample") ///
		over(year) scheme(s1mono) name(violin_full, replace)
graph export "$dir/Git/trade_elasticities/Rédaction/tex/vioplot_full.pdf", replace			

vioplot nbr_prod  if sample=="superbal" ///
		, ytitle("number of exported products" "by country") title("superbalanced sample") ///
		over(year) scheme(s1mono) name(violin_superbal, replace)
		
graph combine violin_full violin_superbal, scheme(s1mono) ycommon ///
			caption("At SITC 4-digit, COMTRADE data, samples defined in the text")
graph export "$dir/Résultats/Première Partie/vioplot.pdf", replace			
graph export "$dir/Git/trade_elasticities/Rédaction/tex/vioplot.pdf", replace	







	
	
	
