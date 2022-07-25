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
**	Date Updated:	6/7/22
******************************************************************

******************************************************************
** Preliminaries
set more off
cd "S:\IMC969\Temp and ado files\"
set scheme uncluttered
global DATA_SAS "S:\IMC969\SAS Data v2\"
global DATA_HCRIS "S:\IMC969\Stata Uploaded Data\Hospital Cost Reports\"
global DATA_AHA "S:\IMC969\Stata Uploaded Data\AHA Data\"
global DATA_ACS "S:\IMC969\Stata Uploaded Data\ACS Data\"
global DATA_PFS "S:\IMC969\Stata Uploaded Data\"
global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global CODE_FILES "S:\IMC969\Stata Code Files\Physician Agency Episodes\"
global RESULTS_FINAL "S:\IMC969\Results\Physician Agency Episodes\202203\"


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


** Collect pre-integration practice data
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
bys physician_npi PH_VI: egen min_VI_year=min(Year) if PH_VI==1
bys physician_npi: egen first_year=min(min_VI_year) if min_VI_year!=.
keep physician_npi indy_prac avg_exper avg_female multi surg prac_size adult_pcp first_year Year
bys physician_npi Year: gen obs=_n
drop if obs>1
drop obs
drop if Year>=first_year & first_year!=.
gen merge_year=Year

local step=0
foreach x of varlist indy_prac avg_exper avg_female multi surg prac_size adult_pcp {
	local step=`step'+1
	bys physician_npi: egen mean_`step'=mean(`x')
	replace `x'=mean_`step' if `x'==.
	drop mean_`step'
}
foreach x of varlist indy_prac avg_exper avg_female multi surg prac_size adult_pcp {
	rename `x' `x'_previ
}
drop first_year Year
save "${DATA_FINAL}Physician_PreVI.dta", replace


** Collect pre-integration shares to each hospital
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
gen phy_share=phyop_claims/total_phyop_claims
bys physician_npi NPINUM PH_VI: egen min_VI_year=min(Year) if PH_VI==1
bys physician_npi NPINUM: egen first_year=min(min_VI_year) if min_VI_year!=.
keep physician_npi NPINUM first_year Year phy_share
bys physician_npi NPINUM Year: gen obs=_n
drop if obs>1
drop obs
drop if Year>=first_year & first_year!=.
gen merge_year=Year

drop first_year Year
save temp_phy_shares, replace


******************************************************************
** Raw physician differential payment
use "${DATA_FINAL}PFS_Revenue_2008.dta", clear
gen Year=2008
forvalues t=2009/2015 {
	append using "${DATA_FINAL}PFS_Revenue_`t'.dta"
	replace Year=`t' if Year==.
}
save "${DATA_FINAL}PFS_Revenue.dta", replace


******************************************************************
** Total differential payment at practice level
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear

preserve
keep if Year==2009
keep physician_npi tin1 
keep if tin1!=.
bys physician_npi: gen obs=_n
keep if obs==1
drop obs
rename tin1 tin_base
save temp_phy_tin, replace
restore

merge m:1 physician_npi Year using "${DATA_FINAL}PFS_Revenue.dta", nogenerate keep(master match)
merge m:1 physician_npi using temp_phy_tin, nogenerate keep(master match)
keep physician_npi NPINUM Year tin_base totchange_rel_2010
bys physician_npi Year: gen phy_obs=_n
gen revchange=totchange_rel_2010 if phy_obs==1
replace revchange=0 if phy_obs>1
bys tin_base Year: egen total_revchange=total(revchange) if tin_base!=.
replace total_revchange=totchange_rel_2010 if tin_base==.
keep if phy_obs==1
keep physician_npi Year total_revchange tin_base
save "${DATA_FINAL}Total_PFS_Revenue.dta", replace

log close


******************************************************************
** Assessment of instrument
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
drop VI
replace PH_VI=0 if PH_VI==.
bys physician_npi Year: egen VI=max(PH_VI)
bys physician_npi Year: gen u_obs=_n
keep if u_obs==1

keep SKA_Practice_ID physician_npi indy_prac avg_exper avg_female multi surg Year VI tin1 phy_zip
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
predict pred_ever_vi
est store ev_coeff

coefplot ev_coeff, keep(normchange2010_2008 normchange2010_2009 normchange2010_2010 normchange2010_2011 normchange2010_2012 normchange2010_2013 normchange2010_2014 normchange2010_2015) vert ytitle("Percentage Point Increase in" "Probability of Integration") xtitle("Year") ///
	coeflabels(normchange2010_2008="2008" normchange2010_2009="2009" normchange2010_2010="2010" normchange2010_2011="2011" normchange2010_2012="2012" normchange2010_2013="2013" normchange2010_2014="2015" normchange2010_2015="2015") yline(0, lwidth(vthin) lcolor(gray)) rescale(3300) ylabel(-8(2)8)
graph save "${RESULTS_FINAL}f4_iv_estimates", replace
graph export "${RESULTS_FINAL}f4_iv_estimates.png", as(png) replace	

keep physician_npi pred_ever_vi Year
sort physician_npi
save "${DATA_FINAL}Predicted_EverVI.dta", replace



use "${DATA_FINAL}PFS_Revenue.dta", clear
merge 1:1 physician_npi Year using temp_phy_vi, keep(match) nogenerate
drop if tin1==. | phy_zip==.
bys tin1 : egen ever_vi=max(VI)
bys tin1 phy_zip Year: egen practice_revchange=total(totchange_rel_2010)
bys tin1 phy_zip Year: egen practice_carrier=total(tot_carrier)
bys tin1 phy_zip Year: gen obs=_n
keep if obs==1
collapse (mean) revchange=practice_revchange [aweight=tot_carrier], by(Year ever_vi)
graph twoway (connected revchange Year if ever_vi==1, color(black)) (connected revchange Year if ever_vi==0, color(black) lpattern(dash)), ///
	ytitle("Mean Relative Revenue Increase") xtitle("Year") legend(off) xlabel(2008(1)2015) ylabel(0(25)150) ///
	text(55 2012.5 "Non-Integrated", place(e)) text(127 2013 "Integrated", place(e))
graph save "${RESULTS_FINAL}f3_raw_iv_graph", replace
graph export "${RESULTS_FINAL}f3_raw_iv_graph.png", as(png) replace		



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
	ytitle("Differential Predicted Probability of Integration") xtitle("Year") legend(off) xlabel(2009(1)2015) ///
	text(0.037 2011.4 "Non-Integrated", place(e)) text(.155 2012.5 "Integrated", place(e))
graph save "${RESULTS_FINAL}f5_logit_iv_graph", replace
graph export "${RESULTS_FINAL}f5_logit_iv_graph.png", as(png) replace		

