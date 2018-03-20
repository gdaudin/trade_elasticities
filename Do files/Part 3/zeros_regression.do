**This file constructs simple stats on zero trade flows which we use in part3 of paper

set mem 500M
set matsize 800
set more off
*on my laptop:
global dir "C:\Documents and Settings\Liza\My Documents\My Dropbox\SITC_Rev1_adv_query_2011"
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
*global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*global dir "D:\ARCHANSKAIA\My Dropbox\SITC_Rev1_adv_query_2011"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*cd "$dir\Résultats Guillaume"


display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities local"
	cd "$dir/Data/For Third Part/"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}








capture program drop zdesc
program zdesc
use "$dir/Résultats/Troisième partie/zéros/Nbrdezeros.dta", clear
**pour_compter_`agg': gives tot nb obs after fillin
**pour_compter_ssuv_`agg': gives tot nb obs after fillin with lacking uv (this includes lacking uv for zero and non zero trade)
**pour_compter_sscommerce_`agg': gives tot nb obs after fillin with lacking uv and trade value (corresponds to nb obs where _fillin=1)
**propor_sscommerce_`agg': nb imputed obs out of tot nb obs per iso_o iso_d
**share of zeros per pair due to zero trade is given by: 
**propor_sscommerce_`agg'=pour_compter_sscommerce_`agg'/pour_compter_`agg'
**What I need first is share of zeros in all potential observations annually
preserve
by iso_o iso_d year, sort: drop if _n!=1
by year, sort: egen tot_year_zeros=total(pour_compter_sscommerce_`1')
by year, sort: egen tot_year_obs=total(pour_compter_`1')
by year, sort: drop if _n!=1
gen share_zeros=tot_year_zeros/tot_year_obs
graph twoway connected share_zeros year
graph export share_zeros_tot_trade_`1'.pdf, replace
restore


**What I need next is the regression for zero trade flows 
**as a first shot, without fixed effects
gen real_ms=commerce_paire/commerce_destination
gen interaction=real_ms*year
reg propor_comm_ssuv_agg`1' real_ms year interaction 
outreg2 real_ms year interaction using zeros_reg`1', addnote(The proportion of zeros is computed at the SITC `1'-digit level.) title("Proportion of zeros as a function of market share") tex(frag) bdec(3) replace
**with destination fixed effects, destination and destination-year fixed effects
keep iso_d iso_o propor_comm_ssuv_agg`1' real_ms year interaction
xi: reg propor_comm_ssuv_agg`1' real_ms year interaction I.iso_d
egen couple=group(iso_d year)
xi: reg propor_comm_ssuv_agg`1' real_ms year interaction couple I.iso_d
*predict ms_hat
*histogram ms_hat

outreg2 real_ms year interaction using zeros_reg`1'_fe, addnote(The proportion of zeros is computed at the SITC `1'-digit level, destination and destination-year fixed effects included.) title("Proportion of zeros, with fixed effects") tex(frag) bdec(3) replace
clear
end
zdesc 4
*zdesc 2
zdesc 1

*NOTES:
*at all disaggregation levels: strong reduction in nb of zeros overtime
*always negative coefficient on year: proportion of ztf decreases overtime
*always negative coef on ms: higher market share associated lower share of zeros
*always positive coef on interaction: overtime, less tight link between ms and proportion of zeros
