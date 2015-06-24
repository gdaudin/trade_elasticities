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
**at Dell laptop
*global dir "G:\LIZA_WORK"
*previously: "...\REVISION_nov_2013_data"
*cd "$dir\GUILLAUME_DAUDIN\REVISION_jan14_data"
**at Mac laptop
*cd "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/REVISION_jan14_data"
global dir "/Volumes/VERBATIM HD/LIZA_WORK"
cd "$dir/GUILLAUME_DAUDIN/REVISION_jan14_data"
**directory to save results: "$dir\GUILLAUME_DAUDIN\REVISION_jan14_data\filename.dta"
***previously: results saved in "SITC_Rev1_adv_query_2011\REVISION_SPRING_2013\part1"

***********************************************
**1a**weights for each category: world
***********************************************
**create file with world weights in some year: 1963 here 
capture program drop weightyear
program weightyear
*`1': year which weights used as stable weights
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\All-4D-`1'.dta", clear
drop if iso_d=="All"
drop if iso_o=="All"
**procedure for correspondence
**change all ERI-ETH variations to ETH only; idem YUG-SER and BEL-LUX
capture replace iso_d= YUG if iso_d=="SER"
capture replace iso_o= YUG if iso_o=="SER"
capture replace iso_d= BEL if iso_d=="LUX"
capture replace iso_o= BEL if iso_o=="LUX"
capture replace iso_d=ETH if iso_d=="ERI"
capture replace iso_o=ETH if iso_o=="ERI"
**for me: keep only attributed trade in our sample (pairs; products)
if `1'<1991 {
	joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_62_90.dta", unmatched(none)
	drop iso_d
	rename ccode_cepii iso_d
	joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_62_90.dta", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}
else {
	joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06.dta", unmatched(none)
	drop iso_d
	rename ccode_cepii iso_d
	joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_91_06.dta", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}
drop if iso_o==iso_d
*fillin iso_d iso_o
*drop _fillin
*drop if iso_d==iso_o
*replace trade_value=0 if trade_value==.
collapse (sum) trade_value, by(product)
egen tot=total(trade_value)
gen double share_world_`1'=trade_value/tot
drop trade_value tot
save weight_`1'_full, replace
clear
end
weightyear 1963
weightyear 1970
***********************************************
**1b**weights for each category: country
***********************************************
*apply country definitions as in superbalanced sample b/c I don't want partners to disappear b/c
**of country dislocation or reunification: gives 151 partners in 1963
capture program drop countryyear
program countryyear
*`1': year which weights used as stable weights
use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\All-4D-`1'.dta", clear
drop if iso_d=="All"
drop if iso_o=="All"
**procedure for correspondence
**change all ERI-ETH variations to ETH only; idem YUG-SER and BEL-LUX
capture replace iso_d= YUG if iso_d=="SER"
capture replace iso_o= YUG if iso_o=="SER"
capture replace iso_d= BEL if iso_d=="LUX"
capture replace iso_o= BEL if iso_o=="LUX"
capture replace iso_d=ETH if iso_d=="ERI"
capture replace iso_o=ETH if iso_o=="ERI"
**for me: keep only attributed trade in our sample (pairs; products)
if `1'<1991 {
	joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_62_90.dta", unmatched(none)
	drop iso_d
	rename ccode_cepii iso_d
	joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_62_90.dta", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}
else {
	joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06.dta", unmatched(none)
	drop iso_d
	rename ccode_cepii iso_d
	joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_91_06.dta", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}
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
save weight_country_`1'_full, replace
clear
end
countryyear 1970
countryyear 1963
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
*on dell:
*use "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\All-4D-`year'.dta", clear
*on mac:
use "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2011/All-4D-`year'.dta", clear
drop if iso_d=="All"
drop if iso_o=="All"
**procedure for correspondence
**change all ERI-ETH variations to ETH only; idem YUG-SER and BEL-LUX
capture replace iso_d= YUG if iso_d=="SER"
capture replace iso_o= YUG if iso_o=="SER"
capture replace iso_d= BEL if iso_d=="LUX"
capture replace iso_o= BEL if iso_o=="LUX"
capture replace iso_d=ETH if iso_d=="ERI"
capture replace iso_o=ETH if iso_o=="ERI"
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
if `year'<1991 {
	*for mac:
	joinby iso_d using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_d_62_90.dta", unmatched(none)
	*for dell: joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_62_90.dta", unmatched(none)
	drop iso_d
	rename ccode_cepii iso_d
	*for mac:
	joinby iso_o using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_o_62_90.dta", unmatched(none)
	*for dell: joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_62_90.dta", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}
else {
	*for mac:
	joinby iso_d using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_d_91_06.dta", unmatched(none)
	*for dell: joinby iso_d using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_d_91_06.dta", unmatched(none)
	drop iso_d
	rename ccode_cepii iso_d
	*for mac:
	joinby iso_o using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_4digit_leafs/rolling/wits_cepii_corresp_o_91_06.dta", unmatched(none)
	*for dell: joinby iso_o using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_4digit_leafs\rolling\wits_cepii_corresp_o_91_06.dta", unmatched(none)
	drop iso_o
	rename ccode_cepii iso_o
}
drop if iso_o==iso_d
*fillin iso_d iso_o
*drop _fillin
*drop if iso_d==iso_o
*replace trade_value=0 if trade_value==.
if "`weightyear'"!="current" {
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
*on mac:
joinby iso_o iso_d using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/DO_FILES_PREVIOUS_WORK/dist_final.dta", unmatched(none)
*on dell: joinby iso_o iso_d using "$dir\GUILLAUME_DAUDIN\DO_FILES_PREVIOUS_WORK\dist_final.dta", unmatched(none)
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
	*for mac:
	joinby iso_o iso_d year using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2011/FTA_2011/Results_fta.dta", unmatched(none)
	*for dell: joinby iso_o iso_d year using "$dir\GUILLAUME_DAUDIN\COMTRADE_Stata_data\SITC_Rev1_adv_query_2011\FTA_2011\Results_fta.dta", unmatched(none)
}
**updated fta file for superbal sample and for composition effect with country weights: fta_mod.dta
if ("`fta'"=="big" | "`fta'"=="small") & ("`balanced'"!="full" | "`country'"!="current") {
	*for mac:
	joinby iso_o iso_d year using "/Volumes/VERBATIM HD/LIZA_WORK/GUILLAUME_DAUDIN/COMTRADE_Stata_data/SITC_Rev1_adv_query_2011/FTA_2011/fta_mod.dta", unmatched(none)
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
if year!=1963 {
	append using  part1_`method'_`balanced'_`fta'_`weightyear'_`countryyear'
}
save part1_`method'_`balanced'_`fta'_`weightyear'_`countryyear', replace
display "`year' done"
end
**EXTRA ESTIMATION FILES FOR PART 1:
*1970 country composition effect and full and ftas:
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(current) countryyear(1970)  
}
*1970 country composition effect and full
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(1970)  
}

*1970 country composition effect and superbal and ftas
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1970) fta(big) weightyear(current) countryyear(1970)  
}
*1970 superbalanced and country composition effect for 1970 instead of 1963
*very similar pattern to 1963-1963 fixing
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1970) fta(nofta) weightyear(current) countryyear(1970)  
}
*1970 superbalanced and ftas:
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1970) fta(big) weightyear(current) countryyear(current)  
}
*1970 superbalanced (sample)
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1970) fta(nofta) weightyear(current) countryyear(current)  
}
*1970 composition effect (world)
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(1970) countryyear(current)  
}

**BASIC ESTIMATION FILES FOR PART 1:
**baseline estimation: full sample, no fta, no reweight
*file with results: "part1_ppml_full_nofta_current_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(current)  
}
**fix world composition of goods: full sample, no fta, reweight 1963
*file with results: "part1_ppml_full_nofta_1963_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(1963) countryyear(current)
}
**fix world composition of trade partners: superbal sample, no fta, no reweight
*file with results: "part1_ppml_1963_nofta_current_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1963) fta(nofta) weightyear(current) countryyear(current) 
}
**allow for FTAs: full sample, fta, no reweight
*file with results: "part1_ppml_full_big_current_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(current) countryyear(current)
}
**two-by-two effects: sample and composition
*file with results: "part1_ppml_1963_nofta_1963_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1963) fta(nofta) weightyear(1963) countryyear(current)
}
**two-by-two effects: sample and FTAs, no reweight
*file with results: "part1_ppml_1963_big_current_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1963) fta(big) weightyear(current) countryyear(current)
}
**two-by-two effects: composition and FTAs (full, big and reweight 1963)
*file with results: "part1_ppml_full_big_1963_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(1963) countryyear(current)
}
**all combined: superbal 1963, FTA, reweight 1963
*file with results: "part1_ppml_1963_big_1963_current.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1963) fta(big) weightyear(1963) countryyear(current)  
}
**ALL BASELINE SPECIFICATION RESULTS CONFORM TO THOSE REPORTED IN PAPER
*POINT OUT THAT DISTANCE PUZZLE IS NOT A COMPOSITION EFFECT, BUT RATHER WITHIN-STABLE-SET EFFECT
*JUSTIFIES FOCUS ON HETEROGENEITY RATHER THAN ON SET OF COUNTRIES OR DISTANCE FUNCTION
*FURTHER CHECKS (NEXT PROGRAM) TO PUSH IDEA THAT DISTANCE PUZZLE IS A WITHIN-STABLE-SET EFFECT

****************************************************
**3**additional composition effect: country bundle 
****************************************************
*fix composition of country-specific product bundle 
****************************************************
*pure country bundle composition effect: enhances distance puzzle
*file with results: "part1_ppml_full_nofta_current_1963.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(nofta) weightyear(current) countryyear(1963)  
}
**sample+country bundle composition effect: enhances distance puzzle (slightly)
*file with results: "part1_ppml_1963_nofta_current_1963.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1963) fta(nofta) weightyear(current) countryyear(1963)  
}
**fta+country bundle composition effect: 
*file with results: "part1_ppml_full_big_current_1963.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(full) fta(big) weightyear(current) countryyear(1963)  
}
*sample+fta+country bundle composition effect:
*file with results: "part1_ppml_1963_big_current_1963.dta"
foreach i of numlist 1963(1)2009 {
	baseline, year(`i') method(ppml) balanced(1963) fta(big) weightyear(current) countryyear(1963)  
}
***********************************************************
*next file: fix distance distribution of trade within/outside of ftas: puzzle robust!
*produce additional decomposition table: conclude on product-driven // distance-driven effects
**PREP GRAPHS FOR PAPER: REPLACE CURRENT
**THEN: prep extra graphs on stability distance distribution of trade (power law)
**THEN: rework part about choice of estimator: choice of ppml, of cross-section, show effect on extensive margin using Egger procedure 
**FOR NOW: drop specification which controls for FTA endogeneity with Egger procedure (too far from what we do / does not converge with basic controls)

**TO DO NEXT: 
*reproduce graphs in part 1 for 1963-2009 and table (use trend code) 
**keep dist_coef instead of its absolute value and check that same vertical scale on graphs
**rewrite introduction: extra references / explicit discussion distance function/heterogeneity
**rewrite part 1 using new graphs and in footnote discuss why choice ppml and cross-section
*for ppml refer to additional SST papers: best available estimator
*+refer to appendix on Egger et al.: variant with two-part Poisson
*discuss precision tradeoff ppml vs loglinear in terms of precision: not nb obs but use of robust: report precision if no robust)
*(report results for test of proportionality assumption for baseline regression in same footnote?)
**in core paper include footnote on why robust cannot be dispensed with: (reference Manning&Mullahy and SST)
**efficiency loss due to implementing correction for unknown form of heteroscedasticity, cross section/panel not helpful
**justify choice of cross-section: add footnote on Baldwin & Taglioni (panel drawback)/no added value in terms of precision
**rewrite appendix on twopart model: drop zip
*modify appendix1 to report cleanly motivation behind choice of ppml (SST, Fally) + results for extensive margin/two-step procedure (Egger et al.) 
**go over Egger code to prepare material for appendix on extensive/intensive margins

**then proceed to part 3: rewrite justification of baseline estimation procedure
**reformulate equation: bias from quality? bias from unaccounted trade costs? 
**write additional estimation procedures: motivation...derivation

**figure out how to decompose mvmt in aggregate elasticity in:
*increase in substitutability: within-sectoral increase in product substitutability
*increase in bundle similarity: similar set of exported goods
*aggregation bias: dampening effect from composition differences?
*SHOW THAT CORE OF DISTANCE PUZZLE IS HOMOGENEIZATION, NOT DISTANCE FUNCTION
*EG PUZZLE STRONGEST FOR STABLE SET OF COUNTRIES-PRODUCTS


*******************
*VARIANT NOT DONE: recode outcome variable as 0 when pair never trades and 1 if it trades at least once in sample
*estimate impact of covariates on state zero/poisson (logit) >> report results in terms of odds ratios?
*separately estimate ppml on observations which are in poisson state (keeping zeros of the poisson state) >> comment on results
*******************
*misspecification of distance function explains puzzle? (piecewise linear/ fractional polynomial?)

**********ZIP**********
*zip estimation: yes, sensitive to scale of depvar b/c overdispersion modelled through presence of two regimes
**changing scale of variable  
**if our focus is on impact of distance on probability of trade (extensive margin), no need for zip
**sufficient to do simple logit(probit) on outcome variable and compute odds ratios in each year
**GD suggests: odds ratio for increase of 1000 km at sample median)
**in appendix: either just report logit results or reproduce Egger et al. method: this would be best...
**proba in first step and second step estimation with inclusion of first step score
**if I can master that, I could also cross-check fta explanation by correcting for fta endogeneity
**capture noisily xi: zip trade_value i.iso_d i.iso_o `varexpl' , inflate (i.iso_d i.iso_o `varexpl') iterate(30) robust from(lndist=-0.6 /*
*	*/ contig=0.4 comlang_off=0 comlang_ethno=0.3 colony=0.1 comcol=0 curcol=1.7 col45=0.5 smctry=0.4)  /*technique (nr bhhh dfp bfgs)*/
*postestim: compute full effect of lndist on predicted trade (nb events)
*margins, dydx(lndist) predict(n)
*margins eydx(lndist) predict(n)
**gives overall elasticity? impact of distance on expected volume of trade? (-1.45 for 1970)
**observe: if I rescale trade_value to higher(lower) unit, zip no longer converges
**in other years does not converge even if no rescaling is done
**while when it converges, it is very close to ppml estimate
**drop discussion of vuong test: not clear to me that referee correct in saying vuong not relevant for pml
**but useless test if we cannot use zip as a robustness check on ppml results (if unit dependency) 
*why zip interesting? b/c impact of distance on expected trade when trade is positive..alternative procedure
*but if zip is unit dependent, we never learn anything about second step results
**therefore: modify appendix to report results of first step in all years: simple logit estimation
**interpretation of raw coefficient? compute odds ratio? 
*simplest logit specification (so that reports directly odds ratio):
*gen double outcome=0
*replace outcome=1 if trade_value>0
*xi: logit outcome i.iso_o i.iso_d `varexpl', robust or
*margins, eydx(lndist)
**how is this different from Egger et al. procedure: should Egger et al. be implemented instead to have 2part ppml?
