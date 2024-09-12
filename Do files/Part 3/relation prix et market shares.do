
**This file checks whether previous results were plausible
**Indeed there were strange patterns in previous estimation such as very reduced nb of zero trade flows for 
**very small ms: seems counterintuitive
**this is because I was using the wrong variable for proportion of zeros
**given the extreme skewness of the distribution for ms and for proportion of zeros, I work in logs of shares, and I use robust
**in this file I construct the zero share variable instead of using the one I thought was correct in the file
**the ms variable should be correct while i am no longer certain that the proportion of zeros variable is
**so I construct it from what I think I understand about variables in the data

set mem 500M
set matsize 800
set more off


display "`c(username)'"
if strmatch("`c(username)'","*daudin*")==1 {
	global dir "~/Documents/Recherche/2007 OFCE Substitution Elasticities local"
	global dirgit "$dir/Git/trade_elasticities"

}


if "`c(hostname)'" =="ECONCES1" {
	global dir "/Users/liza/Documents/LIZA_WORK"
	cd "$dir/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2015/sitcrev1_4dgt_light_1962_2013"
}




capture program drop relation_prix_market_shares
program relation_prix_market_shares
args year

use "$dir/Data/For Third Part/prepar_cepii_`year'", clear
gen ms=tot_pair_full_`year' / tot_dest_full_`year'
gen ln_ms=ln(ms)
gen ln_uv=ln(uv_`year')


tostring product,gen(prod_str)

gen prod_x_iso_d =prod_str+iso_d

areg ln_uv ln_ms, absorb(prod_x_iso_d)

end



foreach year of num 1962(1)2013 {
	relation_prix_market_shares `year'
}
