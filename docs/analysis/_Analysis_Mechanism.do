set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Analysis_Mechanisms_`logdate'.log", replace

******************************************************************
**	Title:			Analysis-Mechanisms
**	Description:	Investigate specific heterogeneities that may explain main results
**	Author:			Ian McCarthy
**	Date Created:	8/31/2020
**	Date Updated:	9/1/2020
******************************************************************

cd "S:\IMC969\Temp and ado files\"

******************************************************************
** Preliminaries
set more off
set maxvar 10000
set scheme uncluttered

global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global RESULTS_FINAL "S:\IMC969\Results\Physician Agency Episodes\202008\"

global COUNTY_VARS TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black ///
	Income_50to75 Income_75to100 Income_100to150 Income_150plus Educ_HSGrad ///
	Educ_Bach Emp_FullTime Fips_Monopoly Fips_Duopoly Fips_Triopoly
global PHY_CONTROLS PracticeSize avg_exper avg_female adult_pcp multi surg indy_prac
global HOSP_CONTROLS Labor_Phys Labor_Residents Labor_Nurse Labor_Other Beds Profit System MajorTeaching
global PATIENT_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.cat_group1 i.cat_group2 i.cat_group3 i.clm_drg_cd
global ABSORB_VARS phy_hosp
global PHY_MISS miss_PracticeSize miss_avg_exper miss_avg_female miss_adult_pcp miss_multi miss_surg
global HOSP_MISS miss_Labor_Phys miss_Labor_Residents miss_Labor_Nurse miss_Labor_Other ///
  miss_Beds miss_Profit miss_System miss_MajorTeaching


******************************************************************
** #1: Are physicians "overusing" care before acquisition to manage
**		their relationship with PCPs
******************************************************************	
use "S:\IMC969\Stata Uploaded Data\SKA_PhysicianLevel_v2.dta", clear
keep physician_npi SKA_Practice_ID size ihs_prac ihs_new indy_prac ehr avg_exper avg_female adult_pcp multi surg Year vert_integrated horz_integrated
rename physician_npi pcp_npi
rename Year SKA_Year
bys pcp_npi SKA_Year: gen obs=_n
drop if obs>1
save temp_vi_data, replace


use "${DATA_FINAL}FinalEpisodesData.dta", clear
merge 1:1 bene_id clm_id physician_npi NPINUM Year using "${DATA_FINAL}ReferralPCPData.dta"
keep if _merge==3
drop _merge

gen SKA_Year=0
forvalues i=2009(2)2015 {
	replace SKA_Year=`i' if inlist(Year, `i', `i'+1)
}
replace SKA_Year=2009 if Year==2008
merge m:1 pcp_npi SKA_Year using temp_vi_data, nogenerate keep(master match)

gen pcp_vi=(vert_integrated==1)
replace carrier_pcp_vi=carrier_pcp*(pcp_vi==1)
gen carrier_pcp_novi=carrier_pcp*(pcp_vi==0)
gen any_pcp=(carrier_pcp>0)
gen any_pcp_novi=any_pcp*(pcp_vi==0)
keep if carrier_pcp<25

est clear	
local step=0
foreach x of varlist carrier_pcp carrier_pcp_novi any_pcp any_pcp_novi {
	local step=`step'+1
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_pcp1_`step'
			
	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_pcp2_`step'

}

** Display Results
estout fe_pcp1_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)
estout fe_pcp2_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)


keep if adult_pcp==0
est clear	
local step=0
foreach x of varlist carrier_pcp carrier_pcp_novi any_pcp any_pcp_novi {
	local step=`step'+1
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_pcp1_`step'
			
	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_pcp2_`step'

}

** Display Results
estout fe_pcp1_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)
estout fe_pcp2_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)
	

******************************************************************
** #2: Are physicians less incentivized to refer patients since marginal revenue from within-practice referrals is now lower
**		- test this by looking at practice size as of 2009
******************************************************************	
use "${DATA_FINAL}FinalEpisodesData.dta", clear
keep if Year==2009
keep physician_npi PracticeSize
rename PracticeSize Base_PracSize
bys physician_npi: gen obs=_n
keep if obs==1
save temp_prac_size, replace

use "${DATA_FINAL}FinalEpisodesData.dta", clear
merge m:1 physician_npi using temp_prac_size, nogenerate keep(master match)
sum Base_PracSize

est clear
local step=0
foreach x of varlist episode_pay carrier_pay carrier_claims {
	local step=`step'+1
	
	forvalues i=30(10)99 {
		_pctile Base_PracSize, p(`i')
		local cut=r(r1)
		qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1) if Base_PracSize<=`cut', ///
			absorb($ABSORB_VARS) cluster(physician_npi)
		est store refer_`step'_`i'
	}
		
}

** Display Results
estout refer_1_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)

estout refer_2_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)

estout refer_3_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $HOSP_CONTROLS)
	


******************************************************************
** #3: Are physicians acting like other acquired physicians
******************************************************************	

** lagged PH_VI
use "${DATA_FINAL}FinalEpisodesData.dta", clear
keep physician_npi NPINUM Year PH_VI
collapse (max) PH_VI, by(physician_npi NPINUM Year)
replace Year=Year+1
rename PH_VI vi_lag
save temp_lagvi, replace


** average prediction
use "${DATA_FINAL}FinalEpisodesData.dta", clear
forvalues i=2008/2015 {
	preserve
	keep if Year==`i'
	keep NPINUM PH_VI episode_pay carrier_pay carrier_claims Year
	collapse (mean) episode_pay carrier_pay carrier_claims, by(NPINUM PH_VI Year)
	replace Year=Year+1
	reshape wide episode_pay carrier_pay carrier_claims, i(NPINUM) j(PH_VI)
	save temp_avg_claims_`i', replace
	restore
}
use temp_avg_claims_2008
forvalues i=2009/2015 {
	append using temp_avg_claims_`i'
}
save temp_avg_claims, replace


******************************************************************	
** analysis of deviation from predicted claims using the average
use "${DATA_FINAL}FinalEpisodesData.dta", clear
merge m:1 NPINUM Year using temp_avg_claims, nogenerate keep(master match)

foreach x of varlist episode_pay carrier_pay carrier_claims {
	gen dist_`x'=(`x'-`x'1)^2
}

** find newly integrated physicians and focus on them
merge m:1 physician_npi NPINUM Year using temp_lagvi, nogenerate keep(match)
keep if vi_lag==0

est clear
local step=0
foreach x of varlist dist_episode_pay dist_carrier_pay dist_carrier_claims {
	local step=`step'+1
	
	qui reghdfe `x' $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS)
	est store refer_`step'		
}

** Display Results
estout refer_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI $PHY_CONTROLS $HOSP_CONTROLS)

	
preserve
qui tab Year, gen(yearfx)
qui tab clm_drg_cd, gen(drgfx)
qui tab cat_group1, gen(cat1fx)
qui tab cat_group2, gen(cat2fx)
qui tab cat_group3, gen(cat3fx)
qui tab month, gen(monthfx)
mat def results=J(7,2,.)
local step=0
forvalues i=0.2(0.1)0.8 {
	local step=`step'+1
	local j=round(`i'*10,1)
	xtrifreg dist_carrier_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS yearfx* drgfx* cat1fx* cat2fx* cat3fx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 monthfx*, ///
		fe i(phy_hosp) quantile(`i')
	display `step'
	mat def A`j'=e(b)
	mat def Var`j'=e(V)
	mat results[`step',1]=A`j'[1,1]
	mat results[`step',2]=sqrt(Var`j'[1,1])
}
clear
svmat results
rename results1 PH_VI
rename results2 PH_VI_SE
gen int_ub=PH_VI + 1.96*PH_VI_SE
gen int_lb=PH_VI - 1.96*PH_VI_SE
gen Quantile=_n
gen cut=0

twoway (rarea int_ub int_lb Quantile, color(gs14)) (line PH_VI Quantile, color(black)) ///
	(line cut Quantile, color(black) lpattern(dot) lstyle(foreground)), ///
	legend(off) ytitle("Distance from Mean VI Physician", margin(vsmall)) xtitle("Quantile of Squared Deviation", margin(vsmall)) ///
	xlabel(1 "0.2" 2 "0.3" 3 "0.4" 4 "0.5" 5 "0.6" 6 "0.7" 7 "0.8") ///
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}Mech_AvgClaims", replace)
graph export "${RESULTS_FINAL}Mech_AvgClaims.png", as(png) replace	
restore

	
log close