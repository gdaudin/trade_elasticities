set mem 500M
set matsize 800
set more off

display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/OFCE Substitution Elasticities local"

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


capture program drop bench
program bench
args year
use baci_tot_`year', clear
gen double ms=tot_pair_full/tot_dest_full
keep year iso_o iso_d ms
joinby iso_o iso_d year using baci_relprice_hier_`year', unmatched(none)
gen double ln_price=ln(`2')
xi: poisson ms i.iso_o i.iso_d ln_price,  robust iterate(100) from(ln_price=-1)
capture generate ic=e(ic)
capture generate converge=e(converged)
keep if _n==1
keep year ic converge
capture generate double coef_elast_`2'=.
capture replace coef_elast_`2'= _b[ln_price]
capture generate double se_elast_`2'=.
capture replace se_elast_`2'=_se[ln_price]
capture generate double /*
*/cl_elast_`2'=coef_elast-1.96*se_elast_`2'
capture generate double /* 
*/cu_elast_`2'=coef_elast+1.96*se_elast_`2'
if `year'==1995 {
	save baci_bench_estim, replace
}
else {
	append using baci_bench_estim
	save baci_bench_estim, replace
}
	
end
*bench 1995 rel_price_0


foreach n of numlist 1995(1)2010 {
	bench `n' rel_price_0
}

**
graph twoway (lfit coef_elast year) (line cu_elast year) (line coef_elast year) (line cl_elast year)
graph export baci_elast_baseline.eps, replace
