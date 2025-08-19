******************************************************************
**	Title:		Supplemental
**	Description:	Additional analysis, robustness, sensitivity, etc.
**	Author:		Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	5/6/24
******************************************************************

****************************************************************************************
** Plausibly exogenous estimation
****************************************************************************************	
use "${DATA_FINAL}FinalEpisodesData.dta", clear

preserve
qui tab Year, gen(yearfx)
qui tab month, gen(monthfx)
qui tab clm_drg_cd, gen(drgfx)
qui tab cat_group1, gen(cat1fx)
qui tab cat_group2, gen(cat2fx)
qui tab cat_group3, gen(cat3fx)


local resid_step=0
foreach x of varlist $HOSP_CONTROLS $COUNTY_VARS Hospital_VI yearfx* monthfx* drgfx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1  {
	local resid_step=`resid_step'+1
	qui areg `x', absorb(phy_hosp)
	predict residx_`resid_step', r
}
qui areg PH_VI, absorb(phy_hosp)
predict vi_resid, r

qui areg total_revchange, absorb(phy_hosp)
predict ins_resid, r

qui areg ln_ep_pay, absorb(phy_hosp)
predict pay_resid, r

qui areg ln_ep_charge, absorb(phy_hosp)
predict charge_resid, r
		
qui areg episode_claims, absorb(phy_hosp)
predict claims_resid, r

mat def results_pay=J(11,3,.)
local step=0
forvalues i=-.5(0.1).5 {
	local step=`step'+1
	local j=round(`i'*10+5,1)
	plausexog uci pay_resid residx_* (vi_resid=ins_resid), gmin(`i') gmax(`i') grid(2) vce(robust)
	display `step'
	mat def A`j'=e(b)
	mat def Var`j'=e(V)
	mat results_pay[`step',1]=A`j'[1,1]
	mat results_pay[`step',2]=sqrt(Var`j'[1,1])
	mat results_pay[`step',3]=`i'
}

mat def results_charge=J(11,3,.)
local step=0
forvalues i=-.5(0.1).5 {
	local step=`step'+1
	local j=round(`i'*10+5,1)
	plausexog uci charge_resid residx_* (vi_resid=ins_resid), gmin(`i') gmax(`i') grid(2) vce(robust)
	display `step'
	mat def A`j'=e(b)
	mat def Var`j'=e(V)
	mat results_charge[`step',1]=A`j'[1,1]
	mat results_charge[`step',2]=sqrt(Var`j'[1,1])
	mat results_charge[`step',3]=`i'
}

mat def results_claims=J(11,3,.)
local step=0
forvalues i=-5(1)5 {
	local step=`step'+1
	local j=round(`i'+5,1)
	plausexog uci claims_resid residx_* (vi_resid=ins_resid), gmin(`i') gmax(`i') grid(2) vce(robust)
	display `step'
	mat def A`j'=e(b)
	mat def Var`j'=e(V)
	mat results_claims[`step',1]=A`j'[1,1]
	mat results_claims[`step',2]=sqrt(Var`j'[1,1])
	mat results_claims[`step',3]=`i'
}


clear
svmat results_pay
rename results_pay1 PH_VI
rename results_pay2 PH_VI_SE
rename results_pay3 excl_v
gen int_ub=PH_VI + 1.96*PH_VI_SE
gen int_lb=PH_VI - 1.96*PH_VI_SE
gen cut=0

twoway (rarea int_ub int_lb excl_v, color(gs14)) (line PH_VI excl_v, color(black)) ///
	(line cut excl_v, color(black) lpattern(dot) lstyle(foreground)), ///
	legend(off) ytitle("Effects on Episode Payments", margin(vsmall)) xtitle("Violation of Exclusion Restriction", margin(vsmall)) ///
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}appfig_Plausexog_Pay", replace)
graph export "${RESULTS_FINAL}appfig_Plausexog_Pay.png", as(png) replace	


clear
svmat results_charge
rename results_charge1 PH_VI
rename results_charge2 PH_VI_SE
rename results_charge3 excl_v
gen int_ub=PH_VI + 1.96*PH_VI_SE
gen int_lb=PH_VI - 1.96*PH_VI_SE
gen cut=0

twoway (rarea int_ub int_lb excl_v, color(gs14)) (line PH_VI excl_v, color(black)) ///
	(line cut excl_v, color(black) lpattern(dot) lstyle(foreground)), ///
	legend(off) ytitle("Effects on Episode Charges", margin(vsmall)) xtitle("Violation of Exclusion Restriction", margin(vsmall)) ///
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}appfig_Plausexog_Charge", replace)
graph export "${RESULTS_FINAL}appfig_Plausexog_Charge.png", as(png) replace	


clear
svmat results_claims
rename results_claims1 PH_VI
rename results_claims2 PH_VI_SE
rename results_claims3 excl_v
gen int_ub=PH_VI + 1.96*PH_VI_SE
gen int_lb=PH_VI - 1.96*PH_VI_SE
gen cut=0

twoway (rarea int_ub int_lb excl_v, color(gs14)) (line PH_VI excl_v, color(black)) ///
	(line cut excl_v, color(black) lpattern(dot) lstyle(foreground)), ///
	legend(off) ytitle("Effects on Episode Claims", margin(vsmall)) xtitle("Violation of Exclusion Restriction", margin(vsmall)) ///
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}appfig_Plausexog_Claims", replace)
graph export "${RESULTS_FINAL}appfig_Plausexog_Claims.png", as(png) replace	
restore



****************************************************************************************
** Specification charts
****************************************************************************************
use "${DATA_FINAL}FinalEpisodesData.dta", clear
save temp_spec_data, replace

** Define program
cap program drop specchart
program specchart
syntax varlist, [replace] spec(string)
	** save current data
	tempfile temp
	save "`temp'", replace
	
	** dataset to store estimates
	if "`replace'"!="" {
		clear
		gen beta=.
		gen se=.
		gen spec_id=.
		gen u95=.
		gen u90=.
		gen l95=.
		gen l90=.
		save "${RESULTS_FINAL}estimates.dta", replace
	}
	else {
		** load dataset
		use "${RESULTS_FINAL}estimates.dta", clear
	}
	** add observations
	local obs=_N+1
	set obs `obs'
	replace spec_id=`obs' if _n==`obs'
	
	** store estimates
	replace beta=_b[`varlist'] if spec_id==`obs'
	replace se=_se[`varlist'] if spec_id==`obs'
	replace u95=beta+invt(e(df_r),0.975)*se if spec_id==`obs'
	replace u90=beta+invt(e(df_r),0.950)*se if spec_id==`obs'
	replace l95=beta-invt(e(df_r),0.975)*se if spec_id==`obs'
	replace l90=beta-invt(e(df_r),0.950)*se if spec_id==`obs'
	
	** store specification
	foreach s in `spec' {
		cap gen `s'=1 if spec_id==`obs'
		cap replace `s'=1 if spec_id==`obs'
	}
	save "${RESULTS_FINAL}estimates.dta", replace
	use `temp', clear
end


*************************************************************
** Episode Payments with OLS
use temp_spec_data, clear
qui reghdfe ln_ep_spend PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace

qui reghdfe ln_ep_spend PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_spend PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe ln_ep_spend PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')

	qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')	
	
	qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_spend PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_spend PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore

keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_spend PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_spend PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)

qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui reghdfe ln_ep_spend PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Payments, OLS, charts
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.030
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.005
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.010
cap gen i_sample_full=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.005
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Full spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.02(0.01).02, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.025 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.03 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.035 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.040 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.045 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.055 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.060 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.065 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.070 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.075 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.080 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.085 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.090 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.095 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.025 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Payments_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_Payments_Spec.png", as(png) replace	





*************************************************************
** Episode Payments with IV
use temp_spec_data, clear
qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)

qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)

			
qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')

	qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
	
	qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore

keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)
			
qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)

qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Payments, IV, charts
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.2
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.02
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.03
cap gen i_sample_full=`ind'
local ind=`ind'-0.02
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.02
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.02
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.02
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.1(0.1).2, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.175 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.20 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.22 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.24 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.26 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.29 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.31 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.33 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.37 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.39 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.41 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.43 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.45 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.24 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Payments_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Payments_Spec.png", as(png) replace	




*************************************************************
** Episode Payments with Alternative IV
use temp_spec_data, clear
bys NPINUM Year: egen all_revchange=sum(total_revchange)
bys NPINUM physician_npi Year: egen all_phy_revchange=sum(total_revchange)
replace all_revchange=all_revchange-all_phy_revchange
bys NPINUM Year: gen hosp_year_count=_N
gen rel_revchange=all_revchange/hosp_year_count

reghdfe PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month rel_revchange, absorb($ABSORB_VARS) cluster(physician_npi)
test rel_revchange


qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)

qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)

			
qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')

	qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
	
	qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore

keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_spend $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_spend $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)
			
qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)

qui ivreghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Payments, IV, charts
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.2
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.02
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.03
cap gen i_sample_full=`ind'
local ind=`ind'-0.02
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.02
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.02
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.02
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.1(0.1).2, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.175 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.20 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.22 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.24 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.26 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.29 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.31 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.33 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.37 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.39 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.41 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.43 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.45 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.24 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Payments2_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Payments2_Spec.png", as(png) replace	



*************************************************************
** Service counts with OLS
use temp_spec_data, clear
qui reghdfe ln_ep_service PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_service PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)

qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_service PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')

	qui reghdfe ln_ep_service PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_service PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_service PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)
	
qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_service PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_service PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)
	
qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui reghdfe ln_ep_service PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)



** Service Counts, OLS, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.06
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.004
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.008
cap gen i_sample_full=`ind'
local ind=`ind'-0.004
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.004
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.004
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.004
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-0.05(0.01)0.01, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -0.057 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.06 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.064 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.068 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.072 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -0.08 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.084 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.088 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.092 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.096 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.10 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.104 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.108 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.112 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.02 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Service_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_Service_Spec.png", as(png) replace	



*************************************************************
** Service counts with IV
use temp_spec_data, clear
qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Service Counts, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-.6
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.05
cap gen i_sample_full=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.50(.1)0.1, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -0.57 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.6 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.63 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.66 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.69 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -0.74 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.77 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.80 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.83 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.86 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.89 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.92 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.95 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.98 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.2 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Service_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Service_Spec.png", as(png) replace	


*************************************************************
** Service counts with Alternative IV
use temp_spec_data, clear
bys NPINUM Year: egen all_revchange=sum(total_revchange)
bys NPINUM physician_npi Year: egen all_phy_revchange=sum(total_revchange)
replace all_revchange=all_revchange-all_phy_revchange
bys NPINUM Year: gen hosp_year_count=_N
gen rel_revchange=all_revchange/hosp_year_count

qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_service $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_service $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_service Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Service Counts, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-.6
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.05
cap gen i_sample_full=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.50(.1)0.1, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -0.57 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.6 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.63 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.66 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.69 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -0.74 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.77 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.80 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.83 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.86 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.89 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.92 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.95 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.98 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.2 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Service2_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Service2_Spec.png", as(png) replace	




*************************************************************
** Episode RVUs with OLS
use temp_spec_data, clear
qui reghdfe ln_ep_rvu PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_rvu PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)

qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_rvu PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')

	qui reghdfe ln_ep_rvu PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_rvu PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_rvu PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)
	
qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_rvu PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_rvu PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)
	
qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui reghdfe ln_ep_rvu PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)



** Episode RVU, OLS, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-.025
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.005
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.01
cap gen i_sample_full=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.005
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///	
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-0.01(.01).05, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.02 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.025 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.03 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.035 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.04 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.05 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.055 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.06 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.065 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.07 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.075 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.08 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.085 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.09 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.06 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_RVU_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_RVU_Spec.png", as(png) replace	



*************************************************************
** Episode RVU with IV
use temp_spec_data, clear
qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode RVU, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.25
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.1
cap gen i_sample_full=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///		
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.15(.1).25, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.2 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.25 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.3 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.4 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -.5 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.55 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.6 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.65 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.7 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.75 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.8 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.85 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.9 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks .3 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_RVU_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_RVU_Spec.png", as(png) replace	




*************************************************************
** Episode RVU with Alternative IV
use temp_spec_data, clear
bys NPINUM Year: egen all_revchange=sum(total_revchange)
bys NPINUM physician_npi Year: egen all_phy_revchange=sum(total_revchange)
replace all_revchange=all_revchange-all_phy_revchange
bys NPINUM Year: gen hosp_year_count=_N
gen rel_revchange=all_revchange/hosp_year_count

qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_rvu $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_rvu $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_rvu Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode RVU, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.25
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.1
cap gen i_sample_full=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///		
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.15(.1).25, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.2 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.25 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.3 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.4 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -.5 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.55 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.6 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.65 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.7 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.75 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.8 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.85 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.9 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks .3 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_RVU2_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_RVU2_Spec.png", as(png) replace	





*************************************************************
** Episode Events with OLS
use temp_spec_data, clear
qui reghdfe ln_ep_events PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_events PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)

qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_events PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')

	qui reghdfe ln_ep_events PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_events PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_events PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)
	
qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_events PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_events PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)
	
qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui reghdfe ln_ep_events PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)



** Episode Event, OLS, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-.025
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.005
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.01
cap gen i_sample_full=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.005
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///	
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-0.01(.01).05, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.02 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.025 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.03 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.035 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.04 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.05 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.055 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.06 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.065 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.07 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.075 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.08 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.085 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.09 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.06 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Event_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_Event_Spec.png", as(png) replace	



*************************************************************
** Episode Event with IV
use temp_spec_data, clear
qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Event, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.25
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.1
cap gen i_sample_full=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///		
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.15(.1).25, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.2 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.25 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.3 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.4 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -.5 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.55 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.6 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.65 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.7 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.75 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.8 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.85 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.9 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks .3 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Event_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Event_Spec.png", as(png) replace	




*************************************************************
** Episode Event with Alternative IV
use temp_spec_data, clear
bys NPINUM Year: egen all_revchange=sum(total_revchange)
bys NPINUM physician_npi Year: egen all_phy_revchange=sum(total_revchange)
replace all_revchange=all_revchange-all_phy_revchange
bys NPINUM Year: gen hosp_year_count=_N
gen rel_revchange=all_revchange/hosp_year_count

qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_events $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_events $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_events Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Event, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.25
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.1
cap gen i_sample_full=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.05
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.05
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///		
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.15(.1).25, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.2 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.25 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.3 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.4 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -.5 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.55 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.6 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.65 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.7 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.75 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.8 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.85 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.9 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks .3 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Event2_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Event2_Spec.png", as(png) replace	




*************************************************************
** Claim counts with OLS
use temp_spec_data, clear
qui reghdfe ln_ep_claims PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_claims PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)

qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_claims PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')

	qui reghdfe ln_ep_claims PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_claims PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_claims PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)
	
qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_claims PH_VI $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_claims PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)
	
qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui reghdfe ln_ep_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)



** Claims Counts, OLS, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.06
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.004
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.008
cap gen i_sample_full=`ind'
local ind=`ind'-0.004
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.004
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.004
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-0.004
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-0.05(0.01)0.01, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -0.057 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.06 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.064 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.068 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.072 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -0.08 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.084 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.088 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.092 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.096 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.10 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.104 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.108 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.112 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.02 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Claims_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_Claims_Spec.png", as(png) replace	



*************************************************************
** Claims counts with IV
use temp_spec_data, clear
qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Claims Counts, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-.6
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.05
cap gen i_sample_full=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.50(.1)0.1, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -0.57 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.6 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.63 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.66 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.69 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -0.74 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.77 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.80 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.83 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.86 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.89 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.92 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.95 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.98 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.2 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Claims_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Claims_Spec.png", as(png) replace	


*************************************************************
** Claims counts with Alternative IV
use temp_spec_data, clear
bys NPINUM Year: egen all_revchange=sum(total_revchange)
bys NPINUM physician_npi Year: egen all_phy_revchange=sum(total_revchange)
replace all_revchange=all_revchange-all_phy_revchange
bys NPINUM Year: gen hosp_year_count=_N
gen rel_revchange=all_revchange/hosp_year_count

qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_full)
	
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_full)
			
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(county sample`i')
	
	qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital sample`i')
			
	qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_snf)

qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_snf)
			
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui ivreghdfe ln_ep_claims $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui ivreghdfe ln_ep_claims $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(county sample_drg)	
	
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital sample_drg)
			
qui ivreghdfe ln_ep_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=rel_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Claims Counts, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base county hospital quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-.6
foreach var in base county hospital quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-.05
cap gen i_sample_full=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-.03
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"

cap gen i_sample_snf=`ind'
local ind=`ind'-.03
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital rank if hospital==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.50(.1)0.1, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -0.57 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.6 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.63 `"+ County"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.66 `"+ Hospital"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.69 `"+ Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))


gr_edit .yaxis1.add_ticks -0.74 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.77 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.80 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.83 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.86 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.89 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.92 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.95 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -0.98 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.2 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Claims2_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Claims2_Spec.png", as(png) replace	


****************************************************************************************
** SUTVA assessment (R1)
****************************************************************************************	
use "${DATA_FINAL}FinalEpisodesData.dta", clear
gen non_int_op=(Physician_VI==1 & PH_VI!=1)
bys physician_npi: egen any_novi=max(non_int_op)
drop if any_novi==1

foreach x of varlist ln_ep_spend ln_ep_rvu ln_ep_service ln_ep_events ln_ep_claims {
	ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), absorb($ABSORB_VARS) cluster(physician_npi)
	ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), absorb($ABSORB_VARS) cluster(physician_npi)
**	ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), absorb($ABSORB_VARS) cluster(physician_npi)
	ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), absorb($ABSORB_VARS) cluster(physician_npi)
}

****************************************************************************************
** Source of Variation in Instrument (R1)
****************************************************************************************	
use "${DATA_FINAL}FinalEpisodesData.dta", clear
reghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month total_revchange if PH_VI==0, absorb($ABSORB_VARS) cluster(physician_npi)

keep physician_npi initial_id PH_VI total_revchange episode_spend episode_service_count episode_rvu $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 Year
collapse (mean) total_revchange $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 (max) PH_VI (sum) episode_spend episode_service_count episode_rvu ///
	(count) episodes=initial_id, by(physician_npi Year)
gen year=Year
save temp_physician_level, replace

** aggregate outcomes
use temp_physician_level, clear
est clear
merge 1:1 physician_npi year using "${DATA_FINAL}PhysicianEffort.dta", nogenerate keep(master match)
drop year
bys physician_npi: gen year_count=_N


****************************************************************************************
** Details of sample construction
****************************************************************************************

use "${DATA_FINAL}PatientLevel_Spend.dta", clear
merge m:1 bene_id using bene_20percent, nogenerate keep(match)
format admit %td
drop if admit<d(01jan2010) | admit>=d(01oct2015)
gen month=month(admit)
replace Year=year(admit)

bys physician_npi NPINUM Year: gen obs=_n
keep if obs==1
keep physician_npi NPINUM Year
save temp_pair_year, replace


** Integration and matches
use "${DATA_FINAL}PhysicianHospital_Integration.dta", clear
rename hospital_npi NPINUM
merge m:1 physician_npi NPINUM Year using temp_pair_year, keep(match)
rename zip ska_zip
rename fips ska_fips
replace VI=0 if VI_1==0 & VI_2==1

** drop outer areas and hawaii/alaska
replace phy_state=hosp_state if phy_state=="" & hosp_state!=""
drop if phy_state=="PR" | phy_state=="GU" | phy_state=="VI" | phy_state=="AK" ///
   | phy_state=="HI" | phy_state=="MP" | phy_state=="PUERTO RICO" | phy_state=="FM" | phy_state=="PW"
replace phy_state="TX" if phy_state=="TEXAS"   

** drop physicians that operate in hospitals more than 120 miles away from office
bys physician_npi: egen max_distance=max(distance)
drop if max_distance>=120
drop max_distance

** drop physicians that are in more than one practice (with sufficient patients in both)
replace tin1_unq_benes=0 if tin1_unq_benes==.
replace tin2_unq_benes=0 if tin2_unq_benes==.
gen tot_unique_benes=tin1_unq_benes + tin2_unq_benes
gen tin1_rel=tin1_unq_benes/tot_unique_benes
drop if tin2!=.

** drop if all years of VI data are missing (physician's practice is never in SK&A data)
tab VI_any 

gen byte missing=mi(VI_any)
bys tin1: egen min_missing=min(missing)
drop if min_missing==1
drop min_missing missing

** count of physician-hospital-year observations with any data from SK&A
count

** which of these physicians are integrated and do/don't have an assigned hospital?
tab VI VI_any

** which of the remaining unassigned physicians are only operating in one hospital?
bys physician_npi Year: gen all_hospitals=_N
bys physician_npi Year: egen max_vi=max(VI_any)
count if VI_missing==1 & all_hospitals==1 & max_vi==1 & VI_any==1
replace VI=1 if all_hospitals==1 & max_vi==1 & VI_any==1

** fill in gaps
gen PH_VI=VI
rename NPINUM hospital_npi

preserve
keep physician_npi hospital_npi Year PH_VI VI_any
bys physician_npi hospital_npi Year: gen obs=_n
bys physician_npi hospital_npi Year: egen max_ph_vi=max(PH_VI)
bys physician_npi hospital_npi Year: egen min_ph_vi=min(PH_VI)
keep if obs==1
drop obs min_ph_vi
egen phy_hospital=group(physician_npi hospital_npi)
xtset phy_hospital Year
sort phy_hospital Year
by phy_hospital: replace PH_VI=1 if L.PH_VI==1 & F.PH_VI==1 & (PH_VI==0 | PH_VI==.)
by phy_hospital: replace PH_VI=1 if L.PH_VI==1 & (PH_VI==. | PH_VI==0)
by phy_hospital: replace PH_VI=1 if L.PH_VI==1 & Year==2015 & VI_any==1

keep physician_npi hospital_npi Year PH_VI
rename PH_VI PH_VI_phy_fill
save phy_vi_fill, replace
restore

**merge m:1 tin1 hospital_npi Year using practice_vi_fill, keep(master match) nogenerate
merge m:1 physician_npi hospital_npi Year using phy_vi_fill, keep(master match) nogenerate
**replace PH_VI=1 if PH_VI_practice_fill==1 & (PH_VI==0 | PH_VI==.)
replace PH_VI=1 if PH_VI_phy_fill==1 & (PH_VI==0 | PH_VI==.)


** drop remaining physicians with VI from SKA but no hospital match
bys physician_npi Year: egen max_phvi=max(PH_VI)
gen no_vi_match=(max_phvi==0 & VI_any==1)
bys physician_npi: egen any_vi_miss=max(no_vi_match)
drop if any_vi_miss==1
drop max_phvi any_vi_miss no_vi_match


