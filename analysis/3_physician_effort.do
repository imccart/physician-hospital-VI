******************************************************************
**	Title:		Physician Effort
**	Description:	Analysis at aggregate physician/year level
**	Author:		Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	6/20/24
******************************************************************

use "${DATA_FINAL}FinalEpisodesData.dta", clear
keep physician_npi initial_id PH_VI total_revchange episode_spend episode_service_count episode_rvu $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 Year
collapse (mean) total_revchange $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 (max) PH_VI (sum) episode_spend episode_service_count episode_rvu ///
	(count) episodes=initial_id, by(physician_npi Year)
gen year=Year
save temp_physician_level, replace

** aggregate outcomes
use temp_physician_level, clear
est clear
merge 1:1 physician_npi year using "${DATA_FINAL}PhysicianEffort.dta", nogenerate keep(master match)
merge 1:1 physician_npi year using "${DATA_FINAL}PhysicianEffort_IP.dta", nogenerate keep(master match)
drop year
bys physician_npi: gen year_count=_N

foreach x of varlist carrier_spend carrier_rvus carrier_patients carrier_claims totip_spend totip_patients totip_claims totip_rvus totop_spend totop_patients totop_rvus totop_claims office_spend office_patients office_rvus office_claims {
	replace `x'=. if `x'<0
	_pctile `x', percentiles(1 99)
	replace `x'=r(r1) if `x'<=r(r1)
	replace `x'=r(r2) if  `x'>=r(r2)
	replace `x'=log(`x'+1)
	drop if `x'==.
}

local step=0
foreach x of varlist carrier_spend carrier_rvus carrier_patients totip_spend totip_patients totop_spend totop_patients totop_rvus office_spend office_patients office_rvus ///
	carrier_claims totip_claims totop_claims office_claims totip_rvus {	
    local step=`step'+1
	
	qui ivreghdfe `x' i.Year (PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store feiv_effort1_`step'
	estadd local physician "X"
	estadd local year "X"
	gen samp1_`step'=e(sample)
	
	qui ivreghdfe `x' i.Year $COUNTY_VARS (PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store feiv_effort2_`step'
	estadd local physician "X"
	estadd local year "X"
	estadd local county "X"
	gen samp2_`step'=e(sample)

	qui ivreghdfe `x' i.Year $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 ///
		(PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store feiv_effort3_`step'
	estadd local physician "X"
	estadd local year "X"
	estadd local county "X"
	estadd local physician2 "X"
	gen samp3_`step'=e(sample)
	
}

** first stage
reghdfe PH_VI total_revchange i.Year, absorb(physician_hpi) cluster(physician_hpi)
test total_revchange

reghdfe PH_VI total_revchange i.Year $COUNTY_VARS, absorb(physician_hpi) cluster(physician_hpi)
test total_revchange

reghdfe PH_VI total_revchange i.Year $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1, absorb(physician_hpi) cluster(physician_hpi)
test total_revchange

	
** Display Results
esttab feiv_effort1_1 feiv_effort2_1 feiv_effort3_1 using "${RESULTS_FINAL}t10_effort_spend.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_effort1_2 feiv_effort2_2 feiv_effort3_2 using "${RESULTS_FINAL}t10_effort_rvu.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	
	
esttab feiv_effort1_3 feiv_effort2_3 feiv_effort3_3 using "${RESULTS_FINAL}t10_effort_patients.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

	
esttab feiv_effort1_4 feiv_effort2_4 feiv_effort3_4 using "${RESULTS_FINAL}t10_effort_ip_spend.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

	
esttab feiv_effort1_5 feiv_effort2_5 feiv_effort3_5 using "${RESULTS_FINAL}t10_effort_ip_patients.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_effort1_6 feiv_effort2_6 feiv_effort3_6 using "${RESULTS_FINAL}t10_effort_op_spend.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	
	
esttab feiv_effort1_7 feiv_effort2_7 feiv_effort3_7 using "${RESULTS_FINAL}t10_effort_op_patients.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

	
esttab feiv_effort1_8 feiv_effort2_8 feiv_effort3_8 using "${RESULTS_FINAL}t10_effort_op_rvus.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_effort1_9 feiv_effort2_9 feiv_effort3_9 using "${RESULTS_FINAL}t10_effort_office_spend.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_effort1_10 feiv_effort2_10 feiv_effort3_10 using "${RESULTS_FINAL}t10_effort_office_patients.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_effort1_11 feiv_effort2_11 feiv_effort3_11 using "${RESULTS_FINAL}t10_effort_office_rvu.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_effort1_12 feiv_effort2_12 feiv_effort3_12 using "${RESULTS_FINAL}t10_effort_claims.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_effort1_13 feiv_effort2_13 feiv_effort3_13 using "${RESULTS_FINAL}t10_effort_ip_claims.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_effort1_14 feiv_effort2_14 feiv_effort3_14 using "${RESULTS_FINAL}t10_effort_op_claims.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_effort1_15 feiv_effort2_15 feiv_effort3_15 using "${RESULTS_FINAL}t10_effort_office_claims.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_effort1_16 feiv_effort2_16 feiv_effort3_16 using "${RESULTS_FINAL}t10_effort_ip_rvu.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N physician year county physician2, fmt(%9.0fc) ///
	   label("Observations" "Physician FE" "Year FE" "County Vars" "Physician Vars")) ///
	nonum collabels(none) gaps noobs
	
	
** outcomes by HCPCS code
use temp_physician_level, clear
est clear
merge 1:m physician_npi year using "${DATA_FINAL}PhysicianEffort_byCode.dta", nogenerate keep(master match)
drop year

keep if inlist(hcpcs_cd, "99203", "99204", "99212", "99213", "99214", "99222", "99223", "99231", "99232") | hcpcs=="99233"
levelsof hcpcs_cd, local(codes)
foreach v in `codes' {
	preserve
	keep if hcpcs_cd=="`v'"
	foreach x of varlist carrier_spend carrier_rvus carrier_patients carrier_claims {
		replace `x'=. if `x'<0
		_pctile `x', percentiles(1 99)
		replace `x'=r(r1) if `x'<=r(r1)
		replace `x'=r(r2) if  `x'>=r(r2)
		replace `x'=log(`x'+1)
		drop if `x'==.
	}
	
	qui ivreghdfe carrier_spend i.Year $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 ///
		(PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store effort_spend_code_`v'
	estadd local code "`v'"
	
	qui ivreghdfe carrier_rvus i.Year $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 ///
		(PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store effort_rvus_code_`v'
	estadd local code "`v'"
	
	qui ivreghdfe carrier_patients i.Year $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 ///
		(PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store effort_patients_code_`v'
	estadd local code "`v'"

	qui ivreghdfe carrier_claims i.Year $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 ///
		(PH_VI=total_revchange), absorb(physician_npi) cluster(physician_npi)
	est store effort_claims_code_`v'
	estadd local code "`v'"	
	restore
}

esttab effort_spend_code_* using "${RESULTS_FINAL}t11_effort_spend_code.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N code, fmt(%9.0fc) ///
	   label("Observations" "HCPCS Code")) ///
	nonum collabels(none) gaps noobs
	
esttab effort_rvus_code_* using "${RESULTS_FINAL}t11_effort_rvu_code.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N code, fmt(%9.0fc) ///
	   label("Observations" "HCPCS Code")) ///
	nonum collabels(none) gaps noobs	

esttab effort_patients_code_* using "${RESULTS_FINAL}t11_effort_patients_code.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N code, fmt(%9.0fc) ///
	   label("Observations" "HCPCS Code")) ///
	nonum collabels(none) gaps noobs	
	
esttab effort_claims_code_* using "${RESULTS_FINAL}t11_effort_claims_code.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N code, fmt(%9.0fc) ///
	   label("Observations" "HCPCS Code")) ///
	nonum collabels(none) gaps noobs	
	
	
/*
** event studies for physician-level effort
gen low=.
replace low=Year if PH_VI==1
bys physician_npi: egen first=min(low)
bys physician_npi: egen ever_vi=max(PH_VI)
bys physician_npi: egen count_vi=total(PH_VI)
bys physician_npi: gen count_obs=_N
gen always_vi=(count_obs==count_vi)
drop low
gen time=(Year-first)+1
replace time=0 if ever_vi==0
tab time, gen(ev_full)
gen never_vi=(ever_vi==0)
gen cs_time=first
replace cs_time=0 if ever_vi==0
	

foreach x of varlist rvu_all patient_days pay_all pay_inpatient pay_outpatient pay_carrier claims_all claims_inpatient claims_outpatient claims_carrier phy_ep_claims phy_ep_pay phy_ep_rvu {
	csdid `x' , time(Year) gvar(cs_time) notyet cluster(physician_npi)
	csdid_estat event
	csdid_plot, ytitle(Estimated ATT)
	gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
	graph save "${RESULTS_FINAL}csdid_effort_`x'", replace
	graph export "${RESULTS_FINAL}csdid_effort_`x'.png", as(png) replace
}	
*/
