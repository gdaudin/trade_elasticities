**This file constructs graphs at 4-digit and 1-digit level used in results' section

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
use estimpoisson, clear
**first graph: at 4-digit level
graph twoway (connected coef_elast_rel_price_4 year, msymbol(smtriangle) msize(medium) mcolor(dkgreen) lpattern(solid) lcolor(dkgreen) lwidth(medthin)) /*
*/ (lfit coef_elast_rel_price_4 year, lpattern(solid) lcolor(red) lwidth(medthin)) /*
*/ (connected cl_elast_rel_price_4 year, msymbol(none) lpattern(dash) lcolor(midgreen) lwidth(medthin))/*
*/ (connected cu_elast_rel_price_4 year, msymbol(none) lpattern(dash) lcolor(midgreen) lwidth(medthin)) /*
*/, title("Trade elasticity (4-digit level)") legend(order(1 2)label(1 coef_elast) label(2 linear fit))
graph export elast_real_4digit.eps, replace

**second graph: at 0-digit level
graph twoway (connected coef_elast_rel_price_0 year, msymbol(smtriangle) msize(medium) mcolor(gs2) lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ (lfit coef_elast_rel_price_0 year, lpattern(solid) lcolor(red) lwidth(medthin)) /*
*/ (connected cl_elast_rel_price_0 year, msymbol(none) lpattern(dash) lcolor(ebblue) lwidth(medthin))/*
*/ (connected cu_elast_rel_price_0 year, msymbol(none) lpattern(dash) lcolor(ebblue) lwidth(medthin)) /*
*/, title("Trade elasticity (0-digit level)") legend(order(1 2)label(1 coef_elast) label(2 linear fit))
graph export elast_real_0digit.eps, replace

**third graph: impact of aggregation
graph twoway (connected coef_elast_rel_price_0 year, msymbol(smtriangle) msize(medium) mcolor(gs2) lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ (lfit coef_elast_rel_price_0 year, lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ (connected coef_elast_rel_price_4 year, msymbol(smcircle) msize(medium) mcolor(ebblue) lpattern(solid) lcolor(ebblue) lwidth(medthin)) /*
*/ (lfit coef_elast_rel_price_4 year, lpattern(solid) lcolor(ebblue) lwidth(medthin)) /*
*/, title("Impact of aggregation: from 4-to 0-digit level") legend(label(1 coef_elast_aggr) label(2 linear fit aggr) label(3 coef_elast_disaggr) label(4 linear fit disaggr))
graph export elast_real_aggr_impact.eps, replace

***INSTRUMENTING GRAPHS:
use estim_instr, clear
**first graph: instrumenting with 1 lag (baseline results)
graph twoway (connected  coef_elast_p_L1 year, msymbol(smtriangle) msize(medium) mcolor(dkgreen) lpattern(solid) lcolor(dkgreen) lwidth(medthin)) /*
*/ (lfit coef_elast_p_L1 year, lpattern(solid) lcolor(red) lwidth(medthin)) /*
*/ (connected  cl_elast_p_L1 year, msymbol(none) lpattern(dash) lcolor(midgreen) lwidth(medthin))/*
*/ (connected cu_elast_p_L1 year, msymbol(none) lpattern(dash) lcolor(midgreen) lwidth(medthin)) /*
*/, title("Trade elasticity (instrumented relative price, 1 lag)") legend(order(1 2)label(1 coef_elast) label(2 linear fit))
graph export elast_instr_1lag.eps, replace

**second graph: instrumenting with 3,5 lags
graph twoway (connected coef_elast_p_L3 year, msymbol(smtriangle) msize(medium) mcolor(gs2) lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ (lfit coef_elast_p_L3 year, lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ (connected coef_elast_p_L5 year, msymbol(smcircle) msize(medium) mcolor(ebblue) lpattern(solid) lcolor(ebblue) lwidth(medthin)) /*
*/ (lfit coef_elast_p_L5 year, lpattern(solid) lcolor(ebblue) lwidth(medthin)) /*
*/, title("Trade elasticity with 3 and 5 lags") legend(label(1 coef_elast_L3) label(2 linear fit L3) label(3 coef_elast_L5) label(4 linear fit L5))
graph export elast_instr_3_5lag.eps, replace

**third graph: instrumenting with 5 and 10 lags
graph twoway (connected  coef_elast_p_L10 year, msymbol(smtriangle) msize(medium) mcolor(dkgreen) lpattern(solid) lcolor(dkgreen) lwidth(medthin)) /*
*/ (lfit coef_elast_p_L10 year, lpattern(solid) lcolor(red) lwidth(medthin)) /*
*/ (connected coef_elast_p_L5 year, msymbol(smcircle) msize(medium) mcolor(gs2) lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ (lfit coef_elast_p_L5 year, lpattern(solid) lcolor(gs2) lwidth(medthin)) /*
*/ if year>1971, title("Trade elasticity (instrumented relative price, 5 and 10 lags)") legend(order(1 2 3 4)label(1 coef_elast_L10) label(2 linear fit L10) label(3 coef_elast_L5) label(4 linear fit L5))
graph export elast_instr_5_10lag.eps, replace
clear

