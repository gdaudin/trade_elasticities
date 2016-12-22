*this program revised on Sept 12 to run regressions for part 1 on KUL server
*adjusts previous version so as to work with cepii-4D-`year'.dta & cepii names on both computers
*adjusts weightyear to focus on 1962 (variants: 1963; 1965) 

**This program was written in May 2013 following GD "regression_partie1.do"
*is adapted to follow revision in Nov 2013
*this program runs baseline regressions in part 1 for 1963-2009
*baseline, fta: from previous
*new: composition 1963 and 1970 world; sample 1963 and 1970 superbal; combined 1963 and 1970
*composition 1963 country...
*graphs/ recap table
*****************************
***set directory and matsize
*****************************
clear all
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


***********************************************
**1a**weights for each category: world
***********************************************
**create file with world weights in some year: 1963 here 
capture program drop weightyear
program weightyear
*`1': year which weights used as stable weights
if strmatch("`c(username)'","*daudin*")==1 {
	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`1'.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cepii-4D-`1', clear
}
*use All-4D-`1', clear
*drop if iso_d=="All"
*drop if iso_o=="All"
drop iso_o iso_d
rename cepii_o iso_o 
rename cepii_d iso_d	
*	drop if iso_d=="WLD"
*	drop if iso_o=="WLD"
drop if iso_o==iso_d

**procedure for correspondence
**change all ERI-ETH variations to ETH only; idem YUG-SER and BEL-LUX
replace iso_d= "YUG" if iso_d=="SER"
replace iso_o= "YUG" if iso_o=="SER"
replace iso_d= "BEL" if iso_d=="LUX"
replace iso_o= "BEL" if iso_o=="LUX"
replace iso_d= "ETH" if iso_d=="ERI"
replace iso_o= "ETH" if iso_o=="ERI"

**for me: keep only attributed trade in our sample (pairs; products)
*if `1'<1991 {
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_62_90.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_d using wits_cepii_corresp_d_62_90, unmatched(none)
*	}	

*	drop iso_d
*	rename ccode_cepii iso_d
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_62_90.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_o using wits_cepii_corresp_o_62_90, unmatched(none)
*	}	
*	drop iso_o
*	rename ccode_cepii iso_o
*}
*else {
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_d using wits_cepii_corresp_d_91_06, unmatched(none)
*	}	
*	drop iso_d
*	rename ccode_cepii iso_d
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_91_06.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_o using wits_cepii_corresp_o_91_06, unmatched(none)
*	}	
*	drop iso_o
*	rename ccode_cepii iso_o
*}
*fillin iso_d iso_o
*drop _fillin
*drop if iso_d==iso_o
*replace trade_value=0 if trade_value==.
collapse (sum) trade_value, by(product)
egen tot=total(trade_value)
gen double share_world_`1'=trade_value/tot
drop trade_value tot

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Data_Interm/First_Part"
save weight_`1'_full, replace
clear
end
weightyear 1962
weightyear 1963
weightyear 1965

***********************************************
**1b**weights for each category: country
***********************************************
*apply country definitions as in superbalanced sample b/c I don't want partners to disappear b/c
**of country dislocation or reunification: gives 151 partners in 1963
capture program drop countryyear
program countryyear
*`1': year which weights used as stable weights
if strmatch("`c(username)'","*daudin*")==1 {
	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`1'.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cepii-4D-`1', clear
}	
*use All-4D-`1', clear
*drop if iso_d=="All"
*drop if iso_o=="All"
drop iso_o iso_d
rename cepii_o iso_o 
rename cepii_d iso_d	
*	drop if iso_d=="WLD"
*	drop if iso_o=="WLD"
drop if iso_o==iso_d

**procedure for correspondence
**change all ERI-ETH variations to ETH only; idem YUG-SER and BEL-LUX
replace iso_d= "YUG" if iso_d=="SER"
replace iso_o= "YUG" if iso_o=="SER"
replace iso_d= "BEL" if iso_d=="LUX"
replace iso_o= "BEL" if iso_o=="LUX"
replace iso_d= "ETH" if iso_d=="ERI"
replace iso_o= "ETH" if iso_o=="ERI"

**for me: keep only attributed trade in our sample (pairs; products)
*if `1'<1991 {
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_62_90.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_d using wits_cepii_corresp_d_62_90, unmatched(none)
*	}	

*	drop iso_d
*	rename ccode_cepii iso_d
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_62_90.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_o using wits_cepii_corresp_o_62_90, unmatched(none)
*	}	
*	drop iso_o
*	rename ccode_cepii iso_o
*}
*else {
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_d using wits_cepii_corresp_d_91_06, unmatched(none)
*	}	
*	drop iso_d
*	rename ccode_cepii iso_d
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_91_06.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_o using wits_cepii_corresp_o_91_06, unmatched(none)
*	}	
*	drop iso_o
*	rename ccode_cepii iso_o
*}
*drop if iso_o==iso_d

local source o d
local name RUS UKR UZB KAZ BLR AZE GEO TJK MDA KGZ LTU TKM ARM LVA EST
local germany FRG DDR DEU
local center CZE SVK
foreach s of local source {
	foreach n of local name {
		quietly replace iso_`s'="SUN" if iso_`s'=="`n'"
	}	
	foreach g of local germany {
		quietly replace iso_`s'="DEU" if iso_`s'=="`g'"
	}	
	foreach c of local center {
		quietly replace iso_`s'="CSH" if iso_`s'=="`c'"
	}	
}
drop if iso_o==iso_d
collapse (sum) trade_value, by(product iso_o)
by iso_o, sort: egen tot=total(trade_value)
gen double share_country_`1'=trade_value/tot
drop trade_value tot
if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Data_Interm/First_Part"
save weight_country_`1'_full, replace
clear
end
countryyear 1962
countryyear 1963
countryyear 1965
**this country reweight: only includes products in joint set
**hence, this reweight evaluates evolution of substitutability within set of stable goods:
**goods present in base year and each subsequent year, with base year weights
**distance elasticity has increased by more for this common set: perceived substitutability?
**but remember also these are less differentiated goods
**TO DO: figure out how to decompose mvmt in aggregate elasticity in:
*increase in substitutability: within-sectoral increase in product substitutability
*increase in bundle similarity: similar set of exported goods
*aggregation bias: dampening effect from composition differences?
*SHOW THAT CORE OF DISTANCE PUZZLE IS HOMOGENEIZATION, NOT DISTANCE FUNCTION
*EG PUZZLE STRONGEST FOR STABLE SET OF COUNTRIES-PRODUCTS

**************************************************
**2**baseline regressions: single/combined effects
**************************************************
**reproduces table in JIE version of paper but with 1963 reweight and superbal 1963 not square
**includes specifications for second type of composition effect (country weights instead of world weights)
capture program drop baseline
program baseline
syntax, year(int) method(string) [fta(string) balanced(string) weightyear(string) countryyear(string)]
if strmatch("`c(username)'","*daudin*")==1 {
	use "$dir/Data/COMTRADE_2015_lite/cepii-4D-`year'.dta", clear
}
if "`c(hostname)'" =="ECONCES1"  {
	use cepii-4D-`year', clear
}

*use All-4D-`year', clear 
*drop if iso_d=="All"
*drop if iso_o=="All"
drop iso_o iso_d
rename cepii_o iso_o 
rename cepii_d iso_d	
*	drop if iso_d=="WLD"
*	drop if iso_o=="WLD"
drop if iso_o==iso_d

**procedure for correspondence
**change all ERI-ETH variations to ETH only; idem YUG-SER and BEL-LUX
replace iso_d= "YUG" if iso_d=="SER"
replace iso_o= "YUG" if iso_o=="SER"
replace iso_d= "BEL" if iso_d=="LUX"
replace iso_o= "BEL" if iso_o=="LUX"
replace iso_d= "ETH" if iso_d=="ERI"
replace iso_o= "ETH" if iso_o=="ERI"

*******************
**for Guillaume: prepare Germany
*replace iso_d= "DEU_avt91" if `year' <=1990 & iso_d=="DEU"
*replace iso_o= "DEU_avt91" if `year' <=1990 & iso_o=="DEU"
*replace iso_d= "DEU_apr91" if `year' >=1991 & iso_d=="DEU"
*replace iso_o= "DEU_apr91" if `year' >=1991 & iso_o=="DEU"
**for Guillaume: replace with correct identifiers
*rename iso_d iso
*joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
*rename cepii iso_d
*drop iso
*rename iso_o iso
*joinby iso using "$dir/Data/Comparaison Wits Cepii.dta", unmatched(none)
*rename cepii iso_o
*drop iso
*******************
**for me: prepare Germany
*if `year'<1991 {
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_62_90.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_d using wits_cepii_corresp_d_62_90, unmatched(none)
*	}	

*	drop iso_d
*	rename ccode_cepii iso_d
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_62_90.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_o using wits_cepii_corresp_o_62_90, unmatched(none)
*	}	
*	drop iso_o
*	rename ccode_cepii iso_o
*}
*else {
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_d using wits_cepii_corresp_d_91_06, unmatched(none)
*	}	
*	drop iso_d
*	rename ccode_cepii iso_d
*	if strmatch("`c(username)'","*daudin*")==1 {
*		joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_91_06.dta", unmatched(none)
*	}
*	if "`c(hostname)'" =="ECONCES1"  {
*		joinby iso_o using wits_cepii_corresp_o_91_06, unmatched(none)
*	}	
*	drop iso_o
*	rename ccode_cepii iso_o
*}
*drop if iso_o==iso_d
*fillin iso_d iso_o
*drop _fillin
*drop if iso_d==iso_o
*replace trade_value=0 if trade_value==.

if "`weightyear'"!="current" {
	if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Data_Interm/First_Part"
	joinby product using weight_`weightyear'_full, unmatched(none)
	egen double tot=total(trade_value)
	by product, sort: egen double tot_product=total(trade_value)
	capture generate double share_product_`year'=tot_product/tot
	gen double trade_value_weight=trade_value*share_world_`weightyear'/share_product_`year'
	drop trade_value
	rename trade_value_weight trade_value
}
if "`countryyear'"!="current" {
*redefine country names according to file with stable weights
	local source o d
	local name RUS UKR UZB KAZ BLR AZE GEO TJK MDA KGZ LTU TKM ARM LVA EST
	local germany FRG DDR DEU
	local center CZE SVK
	foreach s of local source {
		foreach n of local name {
			quietly replace iso_`s'="SUN" if iso_`s'=="`n'"
		}	
		foreach g of local germany {
			quietly replace iso_`s'="DEU" if iso_`s'=="`g'"
		}	
		foreach c of local center {
			quietly replace iso_`s'="CSH" if iso_`s'=="`c'"
		}	
	}
	drop if iso_o==iso_d
**link data to file with stable country-specific weights for each product
	if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Data_Interm/First_Part"
	joinby iso_o product using weight_country_`countryyear'_full, unmatched(none)
	by iso_o, sort: egen double tot=total(trade_value)
	by iso_o product, sort: egen double tot_product=total(trade_value)
	gen double share_product_`year'=tot_product/tot
**reweigh data so that total country trade in that year remains unchanged
	gen double trade_value_weight=trade_value*share_country_`countryyear'/share_product_`year'
	drop trade_value
	rename trade_value_weight trade_value
}
**after all possible reweighting procedures: construct total trade per pair sample:
collapse (sum) trade_value, by(iso_d iso_o)
fillin iso_d iso_o
drop _fillin
drop if iso_d==iso_o
replace trade_value=0 if trade_value==.

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Data/"

if "`balanced'"!="full" {
**I redefine countries before keeping only stable reporters and partners 
	local source o d
	local name RUS UKR UZB KAZ BLR AZE GEO TJK MDA KGZ LTU TKM ARM LVA EST
	local germany FRG DDR DEU
	local center CZE SVK
	foreach s of local source {
		foreach n of local name {
			quietly replace iso_`s'="SUN" if iso_`s'=="`n'"
		}	
		foreach g of local germany {
			quietly replace iso_`s'="DEU" if iso_`s'=="`g'"
		}	
		foreach c of local center {
			quietly replace iso_`s'="CSH" if iso_`s'=="`c'"
		}	
	}
**keep sample of stable pairs for specific base year (superbal)



	joinby iso_o iso_d using superbal_list_`balanced', unmatched(none)
	**no fillin done here b/c pairs may actually exist in some years
	collapse (sum) trade_value, by(iso_d iso_o)
	drop if iso_d==iso_o
}
**add data on bilateral distance:


	joinby iso_o iso_d using dist_final, unmatched(none)

generate year = `year'
sort iso_o iso_d year
generate double lndist=ln(dist)
egen double covered_trade=total(trade_value)
**list of regressors (trade cost controls) in baseline estimation:
local varexpl lndist contig comlang_off comlang_ethno colony comcol curcol col45 smctry 
**add data on FTAs:
*full set of ftas:
if "`fta'"=="big"  {
	local varexpl `varexpl' /*
	*/gatt comecon ec efta eea cacm cacm2 caricom patcra cer can mercosur asean cefta nafta comesa cis eaec cez sparteca /*
	*/sapta pafta cemac waemu eac sacu sadc oct euceec eftaceec eftaspain usisr ecandorra domcausa transpac /*
	*/eftasacu ecsyr ectur ecpal ecfar ectun ecmor ecisr ecsafr eftatur eftaisr eftapal eftamor
}
***reduced set of ftas (not implemented):
***if "`fta'"=="small" {
***	**This variation is for fta_small_bis estimation:
***	local varexpl `varexpl' nafta asean ec gatt mercosur efta comecon
***}
**updated fta file for full sample: Results_fta.dta
if ("`fta'"=="big" | "`fta'"=="small") & "`balanced'"=="full" & "`country'"=="current" {
	
	
	if strmatch("`c(username)'","*daudin*")==1 {
		joinby iso_o iso_d using  "FTA_2011/Results_fta.dta", unmatched(none)
	}
	*for mac:
	else joinby iso_o iso_d year using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2011/FTA_2011/Results_fta.dta", unmatched(none)
	*for dell: joinby iso_o iso_d year using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\FTA_2011\Results_fta.dta", unmatched(none)
}
**updated fta file for superbal sample and for composition effect with country weights: fta_mod.dta
if ("`fta'"=="big" | "`fta'"=="small") & ("`balanced'"!="full" | "`country'"!="current") {
	
	
	if strmatch("`c(username)'","*daudin*")==1 {
		joinby iso_o iso_d using  "FTA_2011/fta_mod.dta", unmatched(none)
	}
	*for mac:
	else joinby iso_o iso_d year using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2011/FTA_2011/fta_mod.dta", unmatched(none)
	*for dell: joinby iso_o iso_d year using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\FTA_2011\fta_mod.dta", unmatched(none)
}
**we have checked that there is no pb of spurious convergence:
**when I check for baseline specification, no evidence of overfitting (but not done systematically)
**estimation could also be conducted with ppml instead of poisson to check existence
**but pb of ppml is absence of macro to keep track of dropped regressors (not convenient)
**ppml advises rescaling of depvar to speed up estimation and avoid spurious convergence
**not done here b/c speed satisfactory and no evidence of overfitting 
if "`method'"=="ppml" {
	xi: poisson trade_value i.iso_d i.iso_o `varexpl', robust iterate(100) from(lndist=-0.6)
**alternative command to check for overfitting: computes Huber-White std errors by default
*quietly xi: ppml trade_value i.iso_d i.iso_o `varexpl', iterate (100) from(lndist=-.6)
}
**postestimation stats:
***fitted values of trade
predict fitted
***correlation between trade and fitted values
qui cor fitted trade
*R2 computed as square of correlation between trade and fitted values
*di as txt " R-squared   "  (`r(rho)')^2
generate  aR_squ=(`r(rho)')^2	
keep if _n==1
keep year covered_trade
generate converged=e(converged)
foreach i of local varexpl {
**the number in front of coef indicates nb of estimated equation
**only #1 active when ppml is run
	capture generate double coef_`i'=[#1]_b[`i'] if converged ==1
	capture generate double coef_`i'_logit=[#2]_b[`i'] if converged ==1
	capture generate double se_`i'=[#1]_se[`i'] if converged ==1
	capture generate double se_`i'_logit=[#2]_se[`i'] if converged ==1
}

if strmatch("`c(username)'","*daudin*")==1 cd "$dir/Résultats/Première partie"

if year!=1962 {
	append using  part1_`method'_`balanced'_`fta'_`weightyear'_`countryyear'
}
save part1_`method'_`balanced'_`fta'_`weightyear'_`countryyear', replace
display "`year' done"
end

*********************************************
**ESTIMATION FILES FOR PART 1: SEPT 13, 2016
*********************************************
*ok*baseline estimation: full sample, no fta, no reweight
*file with results: "part1_ppml_full_nofta_current_current.dta"
*results are marginally different from file that used All-4D-`year' (results kept in file with extension "_init")
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(current)  
}
*ok*fix world composition of goods: full sample, no fta, reweight 1962
*file with results: "part1_ppml_full_nofta_1962_current.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(1962) countryyear(current)
}
*ok*same specification with weightyear 1963
*file with results: "part1_ppml_full_nofta_1963_current.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(1963) countryyear(current)
}
*ok*same specification with weightyear 1965
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(1965) countryyear(current)
}

*ok*fix world composition of trade partners: superbal 1962, no fta, no reweight
*file with results: "part1_ppml_1962_nofta_current_current.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1962) fta(nofta) weightyear(current) countryyear(current) 
}
*ok*same specification but with superbal sample on basis 1963-2013, no fta, no reweight
*file with results: "part1_ppml_1963_nofta_current_current.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1963) fta(nofta) weightyear(current) countryyear(current) 
}
*ok*same specification with superbal sample on basis 1965-2013, no fta, no reweight
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1965) fta(nofta) weightyear(current) countryyear(current) 
}
*not updated*allow for FTAs: full sample, fta, no reweight
*file with results: "part1_ppml_full_big_current_current.dta"
*foreach i of numlist 1963(1)2009 {
*	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(current) countryyear(current)
*}
*ok*two-by-two effects: sample and composition (1962)
*file with results: "part1_ppml_1962_nofta_1962_current.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1962) fta(nofta) weightyear(1962) countryyear(current)
}
*ok*same specification but with sample and composition effects on basis 1963
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1963) fta(nofta) weightyear(1963) countryyear(current)
}
*ok*same specification with sample and composition effects on basis 1965
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1965) fta(nofta) weightyear(1965) countryyear(current)
}
*not updated*two-by-two effects: sample and FTAs, no reweight
*file with results: "part1_ppml_1963_big_current_current.dta"
*foreach i of numlist 1963(1)2009 {
*	baseline, year(`i') method(ppml) balanced(1963) fta(big) weightyear(current) countryyear(current)
*}
*not updated*two-by-two effects: composition and FTAs (full, big and reweight 1963)
*file with results: "part1_ppml_full_big_1963_current.dta"
*foreach i of numlist 1963(1)2009 {
*	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(1963) countryyear(current)
*}
*not updated*all combined: superbal 1963, FTA, reweight 1963
*file with results: "part1_ppml_1963_big_1963_current.dta"
*foreach i of numlist 1963(1)2009 {
*	baseline, year(`i') method(ppml) balanced(1963) fta(big) weightyear(1963) countryyear(current)  
*}

****************************************************
**ADDITIONAL COMPOSITION EFFECT: COUNTRY BUNDLE 
*fix composition of country-specific product bundle 
****************************************************
*ok*country bundle composition effect: for 1962
*file with results: "part1_ppml_full_nofta_current_1962.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(1962)  
}
*ok*same specification but with 1963 as basis year for country-specific bundles
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(1963)  
}
*ok*same specification but with 1965 as basis year for country-specific bundle
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(1965)  
}

*ok*sample+country bundle composition effect in 1962
*file with results: "part1_ppml_1962_nofta_current_1962.dta"
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1962) fta(nofta) weightyear(current) countryyear(1962)  
}
*ok*same specification but bundle and sample effects on basis 1963
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1963) fta(nofta) weightyear(current) countryyear(1963)  
}
*ok*same specification but bundle and sample effects on basis 1965
foreach i of numlist 1962(1)2013 {
	baseline, year(`i') method(ppml) balanced(1965) fta(nofta) weightyear(current) countryyear(1965)  
}

*not updated*fta+country bundle composition effect: 
*file with results: "part1_ppml_full_big_current_1963.dta"
*foreach i of numlist 1963(1)2009 {
*	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(current) countryyear(1963)  
*}
*not updated*sample+fta+country bundle composition effect:
*file with results: "part1_ppml_1963_big_current_1963.dta"
*foreach i of numlist 1963(1)2009 {
*	baseline, year(`i') method(ppml) balanced(1963) fta(big) weightyear(current) countryyear(1963)  
*}
***********************************************************
