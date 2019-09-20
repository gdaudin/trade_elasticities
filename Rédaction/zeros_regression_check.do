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
*on my laptop:
global dir "C:\Documents and Settings\Liza\My Documents\My Dropbox\SITC_Rev1_adv_query_2011"
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
*global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*global dir "D:\ARCHANSKAIA\My Dropbox\SITC_Rev1_adv_query_2011"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
cd "$dir\Résultats Guillaume"
capture program drop zdesc
program zdesc
use Nbrdezerosv3, clear
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
graph export share_zeros_tot_trade_`1'.eps, replace
restore
**What I need next is the regression for zero trade flows in bilateral 
**as a first shot, without fixed effects
gen real_ms=commerce_paire/commerce_destination
gen ln_ms=ln(real_ms)
gen interaction=ln_ms*year
gen ln_ztfshare_`1'=ln(propor_biens_sscommerce_`1')
reg ln_ztfshare_`1' ln_ms year, robust 
reg ln_ztfshare_`1' ln_ms year interaction, robust 
outreg2 ln_ms year interaction using ztf_corr`1', addnote(The proportion of zeros is computed at the SITC `1'-digit level.) title("Proportion of zeros as a function of market share") tex(frag) bdec(4) replace
**with destination fixed effects, destination and destination-year fixed effects
keep iso_d iso_o ln_ztfshare_`1' ln_ms year interaction
xi: reg ln_ztfshare_`1' ln_ms year interaction I.iso_d, robust 
outreg2 ln_ms year interaction using ztf_corr`1'_fe, addtext(Destination FE, YES) addnote(The proportion of zeros is computed at the SITC `1'-digit level.) title("Proportion of zeros, with fixed effects") tex(frag) bdec(4) replace
egen couple=group(iso_d year)
*quietly tab couple, gen(destyear)
*I have difficulty running estimation with all of the fixed effects: pb of matrix size
*xi: reg ln_ztfshare_`1' ln_ms year interaction I.couple I.iso_d, robust 
*outreg2 ln_ms year interaction using ztf_corr`1'_morefe, addnote(The proportion of zeros is computed at the SITC `1'-digit level, destination and destination-year fixed effects included.) title("Proportion of zeros, with fixed effects") tex(frag) bdec(4) replace
clear
end
zdesc 4
zdesc 1

************POISSON******************
**The problem with the above is that I drop observations where there are no 0s which is problematic, particularly at 1-digit level
*so I redo the same thing but in poisson
set mem 500M
set matsize 1000
set more off
*on my laptop:
global dir "C:\Documents and Settings\Liza\My Documents\My Dropbox\SITC_Rev1_adv_query_2011"
*global dir "G:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*at OFCE:
*global dir "F:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
*global dir "D:\ARCHANSKAIA\My Dropbox\SITC_Rev1_adv_query_2011"
*at ScPo:
*global dir "E:\LIZA_WORK\GUILLAUME_DAUDIN\COMTRADE_Stata_data"
cd "$dir\Résultats Guillaume"
capture program drop zdescpois
program zdescpois
use Nbrdezerosv3, clear
gen real_ms=commerce_paire/commerce_destination
gen ln_ms=ln(real_ms)
gen interaction=ln_ms*year
*gen ln_ztfshare_`1'=ln(propor_biens_sscommerce_`1')
poisson propor_biens_sscommerce_`1' ln_ms year, robust 
estimates store Basic`1'
outreg2 ln_ms year using ztfpois_`1'digit, addnote(The proportion of zeros is computed at the SITC `1'-digit level.) title("Proportion of zeros at the `1'-digit level as a function of market share") tex(frag) bdec(4) sdec(4) replace
poisson propor_biens_sscommerce_`1' ln_ms year interaction, robust 
estimates store Binter`1'
outreg2 ln_ms year interaction using ztfpois_`1'digit, title("Proportion of zeros at the `1'-digit level as a function of market share") tex(frag) bdec(4) sdec(4) append 
*outreg2 ln_ms year interaction using ztfpois_corr`1', addnote(The proportion of zeros is computed at the SITC `1'-digit level.) title("Proportion of zeros as a function of market share") tex(frag) bdec(4) replace
**with destination fixed effects
keep iso_d iso_o propor_biens_sscommerce_`1' ln_ms year interaction
xi: poisson propor_biens_sscommerce_`1' ln_ms year I.iso_d, robust 
estimates store Fixed`1'
outreg2 ln_ms year using ztfpois_`1'digit, title("Proportion of zeros at the `1'-digit level as a function of market share") tex(frag) bdec(4) sdec(4) append 
xi: poisson propor_biens_sscommerce_`1' ln_ms year interaction I.iso_d, robust 
estimates store Feinter`1'
outreg2 ln_ms year interaction using ztfpois_`1'digit, addnote(The proportion of zeros is computed at the SITC `1'-digit level.) title("Proportion of zeros as a function of market share") tex(frag) bdec(4) append 
*outreg2 ln_ms year interaction [Basic Binter Fixed Feinter] using ztfpois_`1'digit, addtext(Destination FE, YES) addnote(The proportion of zeros is computed at the SITC `1'-digit level, estimation in poisson.) title("Proportion of zeros at the 4-digit level") tex(frag) bdec(4) replace

***Compute predicted evolution of proportion of zero trade flows for exporters with different ms
**look at predicted values of ztf for mean exporter (has 0.0002 ms)
drop _I*
*estimates restore Binter`1'
poisson propor_biens_sscommerce_`1' ln_ms year interaction, robust 
mfx, at(-8.51 1962 -16696.62)
scalar define expmean1962=e(Xmfx_y)
**predicted ztf: .948
mfx, at(-8.51 2009 -17096.59)
scalar define expmean2009=e(Xmfx_y)
**predicted ztf: .825
**look at predicted values of ztf for exporter 2 std dev above mean (has 0.2865 ms)
mfx, at(-1.25 1962 -2452.5328)
scalar define exptwostdv1962=e(Xmfx_y)
**predicted ztf: .692
mfx, at(-1.25 2009 -2511.2836)
scalar define exptwostdv2009=e(Xmfx_y)
**predicted ztf: .625
**look at predicted values of ztf for exporter at 1% ms
mfx, at(-4.605 1962 -9035.3439)
**predicted ztf: .80
scalar define exponepct1962=e(Xmfx_y)
mfx, at(-4.605 2009 -9251.7869)
**predicted ztf: .71
scalar define exponepct2009=e(Xmfx_y)
**look at predicted values of ztf for exporter at 10% ms
mfx, at(-2.303 1962 -4517.672)
**predicted ztf: .724
scalar define exptenpct1962=e(Xmfx_y)
mfx, at(-2.303 2009 -4625.8935)
**predicted ztf: .651
scalar define exptenpct2009=e(Xmfx_y)
clear
set obs 1
local name expmean1962 expmean2009 exptwostdv1962 exptwostdv2009 exponepct1962 exponepct2009 exptenpct1962 exptenpct2009
foreach n of local name {
	gen `n'=`n'
}
gen digit=`1'
reshape long expmean exptwostdv exponepct exptenpct, i(digit) j(year)
save zdescpois`1', replace
clear
end
zdescpois 4
zdescpois 1

**outsheet tables of predicted ztf in .tex format
use zdescpois4, clear
mkmat year expmean exptwostdv exponepct exptenpct, matrix(zdesc4) 
outtable using zdesc4, mat(zdesc4) replace norowlab f(%9.0f %9.2f %9.2f %9.2f %9.2f) caption("Predicted share of ztf for exporters with different market share, 4-digit level") center
use zdescpois1, clear
mkmat year expmean exptwostdv exponepct exptenpct, matrix(zdesc1) 
outtable using zdesc1, mat(zdesc1) replace norowlab f(%9.0f %9.2f %9.2f %9.2f %9.2f) caption("Predicted share of ztf for exporters with different market share, highest aggregation level") center

***NOTES:
**descriptive stats on ms overall: mean real_ms: mean.009; median .0003; stdv .0372
**therefore in real_ms distribution mean exporter has approx. 1%ms, while 2 std dev above mean exporter has 10% ms
**but in ln_ms: mean ln_ms=-8.51(approx. .02%), and 2 stdv above corresponds to ln_ms=-1.25(approx 28.65%)
**therefore I compute descriptive stats on these 4 market share values: min=.02%, 1%, 10%, max=28.7%)

***DOING GRAPHS ON LOG SCALES BUT WITH UNDERLYING VALUES OF VARs:
**to do a graph on logscale, but displaying real values of variable
*do some regression:
local 1 4
xi: reg ln_ztfshare_`1' ln_ms year interaction I.iso_d, robust 
predict ln_ztfhat1
gen ztfhat1=exp(ln_ztfhat1)
cumul ztfhat1, gen(cdf1)
gen lnrevcdf1=ln(1-cdf1)
scatter lnrevcdf1 ztfhat1, xscale(log) xlabel(0(.25)4) xtick(0(.25)4)
**to store several columns: "eststo:" to run regression storing results and then "esttab using ...tex" to take all the results obtained with eststo
**I opt for exporting several columns: without interaction, with interaction, with destination fixed effects

***INTERPRETATION**********
**Magnitude interpretation: multiplicative model is assumed, the coefficients are directly elasticities
**simple interpretation of interaction effect: for a given ms, effect on year is: coef_year+coef_interaction*ln_ms
**the bigger the market share, and the bigger is this second attenuating component 
**this means that for 1% exporter, the full year effect at 4-digit level is  -.00251499
**this means that for 10% exporter, the full year effect is -.00227875
**reduction is stronger for small guys
**as a second step, I use the mfx to predict ztf for exporters with different market share in end years
**I can then construct the percentage point change in ms for each

**ADDITIONAL POSSIBILITIES FOR ILLUSTRATION:
*do graphs on cdf to show why we expect potential for reduction in ztf to be stronger for small
**at higher aggregation levels: for big exporters, potential for reduction reduced at higher aggregation levels
