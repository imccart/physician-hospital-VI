set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Instruments_`logdate'.log", replace

******************************************************************
**	Title:			Instruments_Data
**	Description:	Create instrument for vertical integration indicator using
**					price shock from Dranove et al (2019) and summarize results
**					of the instrument
**	Author:			Ian McCarthy
**	Date Created:	4/26/18
**	Date Updated:	5/20/2020
******************************************************************

******************************************************************
** Preliminaries
set more off
set scheme uncluttered
cd "S:\IMC969\Temp and ado files\"
global DATA_SAS "S:\IMC969\SAS Data v2\"
global DATA_HCRIS "S:\IMC969\Stata Uploaded Data\Hospital Cost Reports\"
global DATA_AHA "S:\IMC969\Stata Uploaded Data\AHA Data\"
global DATA_ACS "S:\IMC969\Stata Uploaded Data\ACS Data\"
global DATA_PFS "S:\IMC969\Stata Uploaded Data\"
global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global CODE_FILES "S:\IMC969\Stata Code Files\Physician Agency Episodes\"

/*
******************************************************************
** Build Physician Choice Dataset
do "${CODE_FILES}IV1_ChoiceData.do"
*/

******************************************************************
/* Collect physician quantity data per hcpcs */

** from carrier file
insheet using "${DATA_SAS}HCPCS_2008.tab", tab clear
rename hcpcs_cd hcpcs
rename physician_id physician_npi
destring physician_npi, replace force
drop if physician_npi==.
drop year
save temp_office_hcpcs, replace

** from outpatient claims
insheet using "${DATA_SAS}HCPCS_OP_Physician_2008.tab", tab clear
rename value hcpcs
rename count op_ph_claims
bys physician_npi hcpcs: egen op_claims=sum(op_ph_claims)
bys physician_npi hcpcs: gen obs=_n
keep if obs==1

keep physician_npi hcpcs op_claims
save temp_op_hcpcs, replace

** combine to find substitutable codes
use temp_office_hcpcs, clear
merge 1:1 physician_npi hcpcs using temp_op_hcpcs, keep(master match) nogenerate

bys hcpcs: egen tot_carrier=total(carrier_claims)
bys hcpcs: egen tot_op=total(op_claims)

gen tot_hcpcs = tot_carrier + tot_op
gen carrier_perc = tot_carrier/tot_hcpcs
drop if carrier_perc>0.75
gen carrier_share=carrier_claims/tot_carrier
gen op_share=op_claims/tot_op

keep physician_npi hcpcs carrier_claims op_claims carrier_share op_share
save temp_quant_data, replace



******************************************************************
** Run Individual do Files

forvalues y=2008/2015 {
	global year=`y'
	do "${CODE_FILES}IV2_PH_Facility.do"
}

estout vi1_2008 vi1_2009 vi1_2010 vi1_2011 vi1_2012 vi1_2013 vi1_2014 vi1_2015, style(tex) cells(b(star fmt(%10.3f)) se(par)) stats(N r2) ///
	starlevels(* 0.10 ** 0.05 *** 0.01)
estout vi1_mfx_2008 vi1_mfx_2009 vi1_mfx_2010 vi1_mfx_2011 vi1_mfx_2012 vi1_mfx_2013 vi1_mfx_2014 vi1_mfx_2015, ///
	style(tex) cells(b(star fmt(%10.3f)) se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
******************************************************************
** Combine years
use "${DATA_FINAL}Predicted_VI_PFS_2008.dta", clear
forvalues t=2009/2015 {
	append using "${DATA_FINAL}Predicted_VI_PFS_`t'.dta"
}
sort physician_npi NPINUM Year	
save "${DATA_FINAL}PredictedVI_PFS.dta", replace


******************************************************************
** Raw physician differential payment
use "${DATA_FINAL}PFS_Revenue_2008.dta", clear
gen Year=2008
forvalues t=2009/2015 {
	append using "${DATA_FINAL}PFS_Revenue_`t'.dta"
	replace Year=`t' if Year==.
}
save "${DATA_FINAL}PFS_Revenue.dta", replace

log close


******************************************************************
** Assessment of instrument
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
replace PH_VI=0 if PH_VI==.
bys physician_npi Year: egen VI=max(PH_VI)
bys physician_npi Year: gen u_obs=_n
keep if u_obs==1

keep SKA_Practice_ID physician_npi indy_prac ehr avg_exper avg_female adult_pcp multi surg Year VI
save temp_phy_vi, replace

use "${DATA_FINAL}PFS_Revenue.dta", clear
merge 1:1 physician_npi Year using temp_phy_vi, keep(match) nogenerate

gen normchange=0
gen change=0
forvalues t=2008/2015 {
	gen change2007_`t'=rev_change_rel_2007*(Year==`t')
	gen change2010_`t'=rev_change_rel_2010*(Year==`t')
	gen normchange2007_`t'=totchange_rel_2007*(Year==`t')
	gen normchange2010_`t'=totchange_rel_2010*(Year==`t')
	gen facility_change2010_`t'=rev_change_facility_2010*(Year==`t')
	gen office_change2010_`t'=rev_change_office_2010*(Year==`t')	
	gen facility_change2007_`t'=rev_change_facility_2007*(Year==`t')
	gen office_change2007_`t'=rev_change_office_2007*(Year==`t')
	replace normchange=normchange2010_`t' if Year==`t' & Year>=2010
	replace change=change2010_`t' if Year==`t' & Year>=2010
}
gen Year2011=(Year==2011)
gen Year2012=(Year==2012)
gen Year2013=(Year==2013)
gen Year2014=(Year==2014)
gen Year2015=(Year==2015)
reg VI normchange2007_* normchange2010_* rev_change_rel_2007 rev_change_rel_2010 i.Year, cluster(physician_npi)
est store ev_coeff
coefplot ev_coeff, keep(normchange2010_2008 normchange2010_2009 normchange2010_2010 normchange2010_2011 normchange2010_2012 normchange2010_2013 normchange2010_2014 normchange2010_2015) vert ytitle("Percentage Point Increase in" "Probability of Integration") xtitle("Year") ///
	coeflabels(normchange2010_2008="2008" normchange2010_2009="2009" normchange2010_2010="2010" normchange2010_2011="2011" normchange2010_2012="2012" normchange2010_2013="2013" normchange2010_2014="2015" normchange2010_2015="2015") yline(0, lwidth(vthin) lcolor(gray)) rescale(3300) ylabel(-1(1)8)
graph save "${RESULTS_FINAL}IV_Estimates", replace
graph export "${RESULTS_FINAL}IV_Estimates.png", as(png) replace	


preserve
bys physician_npi: egen ever_vi=max(VI)
collapse (mean) revchange=totchange_rel_2010 [aweight=tot_carrier], by(Year ever_vi)
graph twoway (connected revchange Year if ever_vi==1, color(black)) (connected revchange Year if ever_vi==0, color(black) lpattern(dash)), ///
	ytitle("Mean Relative Revenue Increase") xtitle("Year") legend(off) xlabel(2008(1)2015) ylabel(0(10)60) ///
	text(40 2012.5 "Non-Integrated", place(e)) text(54 2013 "Integrated", place(e))
graph save "${RESULTS_FINAL}Raw_IV_Graph", replace
graph export "${RESULTS_FINAL}Raw_IV_Graph.png", as(png) replace		
restore


use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
replace PH_VI=0 if PH_VI==.
merge 1:1 physician_npi NPINUM Year using "${DATA_FINAL}PredictedVI_PFS.dta", keep(match) nogenerate
bys physician_npi NPINUM: egen ever_vi=max(PH_VI)
collapse (mean) pred_vi1, by(Year ever_vi)
sum pred_vi1 if ever_vi==1 & (Year==2008 | Year==2009)
local vi_2008=r(mean)
sum pred_vi1 if ever_vi==0 & (Year==2008 | Year==2009)
local novi_2008=r(mean)
replace pred_vi1=pred_vi1-`vi_2008' if ever_vi==1
replace pred_vi1=pred_vi1-`novi_2008' if ever_vi==0
graph twoway (connected pred_vi1 Year if ever_vi==1, color(black)) (connected pred_vi1 Year if ever_vi==0, color(black) lpattern(dash)), ///
	ytitle("Differential Predicted Probability of Integration") xtitle("Year") legend(off) xlabel(2008(1)2015) ///
	text(0.04 2011.5 "Non-Integrated", place(e)) text(.12 2012.5 "Integrated", place(e))
graph save "${RESULTS_FINAL}Logit_IV_Graph", replace
graph export "${RESULTS_FINAL}Logit_IV_Graph.png", as(png) replace		
