set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\AnalysisHome_`logdate'.log", replace

******************************************************************
**	Title:			Analysis
**	Description:	Run all summary stats and regression analysis for physician agency/hospital influence paper.
**	Author:			Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	8/6/2020
******************************************************************

cd "S:\IMC969\Temp and ado files\"

******************************************************************
** Preliminaries
set more off
set maxvar 10000
set scheme uncluttered

global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global RESULTS_FINAL "S:\IMC969\Results\Physician Agency Episodes\202008_Home\"


******************************************************************
** Build final dataset

** collect all instruments
use "${DATA_FINAL}PredictedVI_PFS.dta", clear
merge m:1 physician_npi Year using "${DATA_FINAL}PFS_Revenue.dta", nogenerate keep(master match)
save temp_ivs, replace

** reduce physician/hospital dataset to key variables and merge with instruments
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
drop MCRNUM* phyop_claims phyop_patients phy_carrier_claims phy_carrier_patients total_phyop_claims ///
	total_phyop_patients total_hosp_admits total_hosp_patients total_hosp_pymt total_hosp_charges total_hosp_drg
merge 1:1 physician_npi NPINUM Year using temp_ivs, generate(IV_Match) keep(master match)
save temp_phyhosp, replace

** merge physician/hospital characteristics to episode-level spending & quality data
use "${DATA_FINAL}PatientLevel_Spend.dta", clear
merge 1:1 bene_id clm_id Year using "${DATA_FINAL}PatientLevel_Quality.dta", nogenerate keep(match)
merge m:1 physician_npi NPINUM Year using temp_phyhosp, nogenerate keep(match)

** final clean up
gen month=month(admit)
replace Year=year(admit)
format admit %td
drop if admit<d(01jan2008)
keep if Discharge_Home==1
**drop if clm_pmt_amt<0 | pay_op<0 | pay_ipfull<0 | carrier_pay<0

******************************************************************
** Create additional variables
******************************************************************
** identify counts of each group (for summary stats by level)
bys physician_npi Year: gen phy_obs=_n
bys physician_npi Year: gen phy_episodes=_N
bys NPINUM Year: gen hosp_obs=_n
bys NPINUM Year: gen hosp_episodes=_N
bys fips Year: gen fips_obs=_n
bys fips Year: gen fips_episodes=_N

bys physician_npi: gen unique_phy=_n
bys NPINUM: gen unique_hosp=_n
bys physician_npi NPINUM: gen unique_pair=_n

** max VI by hospital and physician
bys NPINUM Year: egen Hospital_VI=max(PH_VI)
bys physician_npi Year: egen Physician_VI=max(PH_VI)

** different groups
egen state_group=group(phy_state)
egen fips_group=group(fips)
egen phy_hosp=group(physician_npi NPINUM)

** size of physician practice
gen phy_count_tax=(phy_obs==1)
bys Year phy_taxid: egen PracticeSize=total(phy_count_tax)
drop phy_count_tax

** clean population
replace TotalPop=TotalPop/1000

** Major Teaching Hospital
gen MajorTeaching=(Teaching_Hospital1==1)	

** Monopoly/duopoly/triopoly indicators
gen hosp_first=(hosp_obs==1)
bys fips Year: egen Fips_Hospitals=total(hosp_first)
gen Fips_Monopoly=(Fips_Hospitals==1)
gen Fips_Duopoly=(Fips_Hospitals==2)
gen Fips_Triopoly=(Fips_Hospitals==3)

** log outcomes
gen ln_ep_charge=log(episode_charge)
gen ln_ep_pay=log(episode_pay)
gen ln_clm_pmt=log(clm_pmt_amt)
gen ln_op=ln(pay_op+1)
gen ln_ip=ln(pay_ipfull+1)
gen ln_carrier=ln(carrier_pay+1)
gen ln_op_charge=ln(charge_op)
gen ln_ip_charge=ln(clm_tot_chrg_amt + charge_ipfull)
gen ln_carrier_charge=ln(carrier_charge)
gen ln_pre_pay=ln(pre_carrier_pay+1)
gen ln_admit_pay=ln(admit_carrier_pay+1)
gen ln_post_pay=ln(post_carrier_pay+1)


count
count if unique_phy==1
count if unique_hosp==1
count if unique_pair==1

******************************************************************
** Global varlists
******************************************************************
global COUNTY_VARS TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black ///
	Income_50to75 Income_75to100 Income_100to150 Income_150plus Educ_HSGrad ///
	Educ_Bach Emp_FullTime Fips_Monopoly Fips_Duopoly Fips_Triopoly
global PHY_CONTROLS PracticeSize avg_exper avg_female adult_pcp multi surg indy_prac
global HOSP_CONTROLS Labor_Phys Labor_Residents Labor_Nurse Labor_Other Beds Profit System MajorTeaching
global OUTCOMES_SPEND episode_charge episode_pay ln_ep_charge ln_ep_pay episode_claims 
global OUTCOMES_QUAL mortality_90 readmit_90 sepsis ssi any_comp
global OUTCOMES_FALSE clm_pmt_amt ln_clm_pmt drgweight
global OUTCOMES_COMP ln_ep_pay ln_ip ln_op ln_carrier ln_ip_charge ln_op_charge ln_carrier_charge carrier_claims
global OUTCOMES_COMP_LEVEL episode_pay pay_ipfull pay_op carrier_pay charge_ipfull charge_op carrier_charge carrier_claims
global OUTCOMES_REFERRAL op_same_phy op_vi_phy op_same_hosp carrier_same_phy carrier_vi_phy carrier_same_hosp
	
******************************************************************
** Summary Statistics
******************************************************************
tab Year
tab Year if phy_obs==1
tab Year if hosp_obs==1
tab Year if fips_obs==1

** physician/hospital vars
qui estpost tabstat ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} PH_VI, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}phy_hosp_all.tex", main(mean) aux(sd) unstack replace

qui estpost tabstat ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} if PH_VI==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}phy_hosp_vi.tex", main(mean) aux(sd) unstack replace

qui estpost tabstat ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} if PH_VI==0, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}phy_hosp_novi.tex", main(mean) aux(sd) unstack replace


** physician vars
qui estpost tabstat $PHY_CONTROLS PH_VI phy_episodes if phy_obs==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}phy_all.tex", main(mean) aux(sd) unstack replace

qui estpost tabstat $PHY_CONTROLS phy_episodes if PH_VI==1 & phy_obs==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}phy_vi.tex", main(mean) aux(sd) unstack replace

qui estpost tabstat $PHY_CONTROLS phy_episodes if PH_VI==0 & phy_obs==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}phy_novi.tex", main(mean) aux(sd) unstack replace

** hospital vars
qui estpost tabstat $HOSP_CONTROLS Hospital_VI hosp_episodes if hosp_obs==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}hosp_all.tex", main(mean) aux(sd) unstack replace

qui estpost tabstat $HOSP_CONTROLS hosp_episodes if hosp_obs==1 & Hospital_VI==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}hosp_vi.tex", main(mean) aux(sd) unstack replace

qui estpost tabstat $HOSP_CONTROLS hosp_episodes if hosp_obs==1 & Hospital_VI==0, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}hosp_novi.tex", main(mean) aux(sd) unstack replace

** county vars
qui estpost tabstat ${COUNTY_VARS} fips_episodes if fips_obs==1, ///
	by(Year) statistics(mean sd min max count) columns(statistics)
esttab using "${RESULTS_FINAL}fips_all.tex", main(mean) aux(sd) unstack replace

** histogram of DRGs for episodes
preserve
drop if clm_drg_cd==10000 | clm_drg_cd==0
bys clm_drg_cd: gen drg_count=_N
keep if drg_count>18500
tab clm_drg_cd

gen t_count=0.001
graph bar (sum) t_count, over(clm_drg_cd) ytitle("Frequency of Top DRG Codes (1000s)") ///
	legend(off) plotregion(margin(medium)) intensity(60) blabel(bar, format(%3.0f))
graph save "${RESULTS_FINAL}TopDRGs", replace
graph export "${RESULTS_FINAL}TopDRGs.png", as(png) replace	
restore


******************************************************************
** Replace missing variables
******************************************************************	
local step=0
foreach x of varlist $PHY_CONTROLS {
	local step=`step'+1
	bys physician_npi: egen mean_`step'=mean(`x')
	gen miss_`x'=(`x'==.)
	replace `x'=mean_`step' if `x'==.
	drop mean_`step'
}

local step=0
foreach x of varlist $HOSP_CONTROLS {
	local step=`step'+1
	bys NPINUM: egen mean_`step'=mean(`x')
	gen miss_`x'=(`x'==.)
	replace `x'=mean_`step' if `x'==.
	drop mean_`step'
}

global PHY_MISS miss_PracticeSize miss_avg_exper miss_avg_female miss_adult_pcp miss_multi miss_surg
global HOSP_MISS miss_Labor_Phys miss_Labor_Residents miss_Labor_Nurse miss_Labor_Other ///
  miss_Beds miss_Profit miss_System miss_MajorTeaching
	

******************************************************************
** Effect on Physician Behaviors
******************************************************************	
global PATIENT_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.cat_group1 i.cat_group2 i.cat_group3 i.clm_drg_cd
global ABSORB_VARS phy_hosp

********************************************
** FE estimates
		
est clear	
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	qui reghdfe `x' PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend1_`step'
	
	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend2_`step'
			
	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend3_`step'
	
	
}

** Display Results
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	estout fe_spend1_`step' fe_spend2_`step' fe_spend3_`step', style(tex) cells(b(star fmt(%10.3f)) ///
		se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
}

estout fe_spend2_3 fe_spend2_4 fe_spend2_5, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

	
local step=0
foreach x of varlist $OUTCOMES_QUAL {
	local step=`step'+1
	qui reghdfe `x' PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_qual1_`step'

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_qual2_`step'
	
	
}

** Display Results
local step=0
foreach x of varlist $OUTCOMES_QUAL {
	local step=`step'+1
	estout fe_qual1_`step' fe_qual2_`step', style(tex) cells(b(star fmt(%10.3f)) ///
		se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
}
	
		
********************************************
** Event Study for PH VI
gen low=.
replace low=Year if PH_VI==1
bys physician_npi NPINUM: egen first=min(low)
bys physician_npi NPINUM: egen ever_vi=max(PH_VI)
bys physician_npi NPINUM: egen count_vi=total(PH_VI)
bys physician_npi NPINUM: gen count_obs=_N
gen always_vi=(count_obs==count_vi)
drop low
gen time=(Year-first)+1
replace time=0 if ever_vi==0
tab time, gen(ev)
tab time, gen(ev_full)

** Full event study
**replace ev_full3=1 if ev_full2==1 | ev_full1==1
**replace ev_full12=1 if ev_full13==1 | ev_full14==1 | ev_full15==1

reghdfe ln_ep_pay ev_full1 ev_full2 ev_full3 ev_full4 ev_full5 ev_full6 ev_full8 ev_full9 ev_full10 ev_full11 ev_full12 ev_full13 ev_full14 ///
	Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff1
coefplot ev_coeff1, keep(ev_full3 ev_full4 ev_full5 ev_full6 ev_full8 ev_full9 ev_full10 ev_full11 ev_full12) vert ytitle("Charge") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full3="-4" ev_full4="-3" ev_full5="-2" ev_full6="-1" ev_full8="0" ev_full9="+1" ev_full10="+2" ev_full11="+3" ev_full12="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventPay_Episode_All", replace
graph export "${RESULTS_FINAL}EventPay_Episode_All.png", as(png) replace	

	
** Event Study for 2011 (using 2011 as post and 2010 as baseline)
reghdfe ln_ep_charge ev5 ev6 ev8 ev9 ev10 ev11 ev12 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month if first==2011 | ever_vi==0, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coef2
coefplot ev_coef2, keep(ev5 ev6 ev8 ev9 ev10 ev11 ev12) vert ytitle("Charge") xtitle("Period") xline(2.5) coeflabels(ev5="-2" ev6="-1" ev8="0" ev9="+1" ev10="+2" ev11="+3" ev12="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventCharge_Episode_2011", replace
graph export "${RESULTS_FINAL}EventCharge_Episode_2011.png", as(png) replace	

reghdfe ln_ep_pay ev5 ev6 ev8 ev9 ev10 ev11 ev12 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month if first==2011 | (time==0 & ever_vi==0), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coef3
coefplot ev_coef3, keep(ev5 ev6 ev8 ev9 ev10 ev11 ev12) vert ytitle("Medicare Payments") xtitle("Period") xline(2.5) coeflabels(ev5="-2" ev6="-1" ev8="0" ev9="+1" ev10="+2" ev11="+3" ev12="+4")  yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventPay_Episode_2011", replace
graph export "${RESULTS_FINAL}EventPay_Episode_2011.png", as(png) replace		

reghdfe episode_claims ev5 ev6 ev8 ev9 ev10 ev11 ev12 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month if first==2011 | (time==0 & ever_vi==0), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coef4
coefplot ev_coef4, keep(ev5 ev6 ev8 ev9 ev10 ev11 ev12) vert ytitle("Number of Claims") xtitle("Period") xline(2.5) coeflabels(ev5="-2" ev6="-1" ev8="0" ev9="+1" ev10="+2" ev11="+3" ev12="+4")  yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventClaims_Episode_2011", replace
graph export "${RESULTS_FINAL}EventClaims_Episode_2011.png", as(png) replace		

	
** Event Study for 2013 (using 2013 as first year and 2012 as baseline)
reghdfe ln_ep_charge ev3 ev4 ev5 ev6 ev8 ev9 ev10 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month if (first==2013 | (time==0 & ever_vi==0)), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coef5
coefplot ev_coef5, keep(ev3 ev4 ev5 ev6 ev8 ev9 ev10) vert ytitle("Charge") xtitle("Period") xline(4.5) coeflabels(ev3="-4" ev4="-3" ev5="-2" ev6="-1" ev8="0" ev9="+1" ev10="+2")  yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventCharge_Episode_2013", replace
graph export "${RESULTS_FINAL}EventCharge_Episode_2013.png", as(png) replace	

reghdfe ln_ep_pay ev3 ev4 ev5 ev6 ev8 ev9 ev10 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month if (first==2013 | (time==0 & ever_vi==0)), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coef6
coefplot ev_coef6, keep(ev3 ev4 ev5 ev6 ev8 ev9 ev10) vert ytitle("Medicare Payments") xtitle("Period") xline(4.5) coeflabels(ev3="-4" ev4="-3" ev5="-2" ev6="-1" ev8="0" ev9="+1" ev10="+2")  yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventPay_Episode_2013", replace
graph export "${RESULTS_FINAL}EventPay_Episode_2013.png", as(png) replace		

reghdfe episode_claims ev3 ev4 ev5 ev6 ev8 ev9 ev10 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS  i.month if (first==2013 | (time==0 & ever_vi==0)), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coef7
coefplot ev_coef7, keep(ev3 ev4 ev5 ev6 ev8 ev9 ev10) vert ytitle("Number of Claims") xtitle("Period") xline(4.5) coeflabels(ev3="-4" ev4="-3" ev5="-2" ev6="-1" ev8="0" ev9="+1" ev10="+2")  yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}EventClaims_Episode_2013", replace
graph export "${RESULTS_FINAL}EventClaims_Episode_2013.png", as(png) replace		


********************************************
** Triple diff among physicians that operate in VI and non-VI hospitals in the same year (at some point)
gen vi_diff=(PH_VI!=Physician_VI)
bys physician_npi: egen diff_max=max(vi_diff)
bys physician_npi: egen ever_vi_phy=max(PH_VI)

local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	qui reghdfe `x' PH_VI Physician_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month if (diff_max>0 | ever_vi_phy==0), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe3d_`step'
}

** Display Results
estout fe3d_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Physician_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
	
		
********************************************
** FE-IV 

** first-stage
reghdfe PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month pred_vi1, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
test pred_vi1

** reduced form
reghdfe ln_ep_pay pred_vi1 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.month i.Year, ///
		absorb($ABSORB_VARS) cluster(physician_npi)

		
		
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	qui reghdfe `x' $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend1`step'
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend2`step'

	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend3`step'
}

** Display Results
estout feiv_spend1*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI $PHY_CONTROLS $HOSP_CONTROLS)
	
estout feiv_spend2*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_spend3*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)	
	
local step=0
foreach x of varlist $OUTCOMES_QUAL {
	local step=`step'+1
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_qual1`step'
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=totchange_rel_2010), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_qual2`step'	
}

** Display Results
estout feiv_qual1*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)	
	
estout feiv_qual2*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)		
	
		
****************************************************************************************
** Components of episode
****************************************************************************************	
local step=0
foreach x of varlist $OUTCOMES_COMP {
	local step=`step'+1

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_complog`step'	
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_complog`step'
}

** Display Results
estout fe_complog*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_complog*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

	
local step=0
foreach x of varlist $OUTCOMES_COMP_LEVEL {
	local step=`step'+1

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_complev`step'	
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_complev`step'
}

** Display Results
estout fe_complev*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_complev*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
	

coefplot (fe_complog1, label(Episode)) (fe_complog2, label(Inpatient)) (fe_complog3, label(Outpatient)) (fe_complog4, label(Professional)), bylabel(Logs) ///
	|| (fe_complev1, label(Episode)) (fe_complev2, label(Inpatient)) (fe_complev3, label(Outpatient)) (fe_complev4, label(Professional)), bylabel(Levels) ///
    ||, keep(PH_VI) xline(0) byopts(cols(2) xrescale legend(rows(1))) coeflabels(PH_VI="Vertical Integration", angle(vertical) notick) yscale(noline)
graph save "${RESULTS_FINAL}Components_OLS", replace
graph export "${RESULTS_FINAL}Components_OLS.png", as(png) replace		
	
	
coefplot (feiv_complog1, label(Episode)) (feiv_complog2, label(Inpatient)) (feiv_complog3, label(Outpatient)) (feiv_complog4, label(Professional)), bylabel(Logs) ///
	|| (feiv_complev1, label(Episode)) (feiv_complev2, label(Inpatient)) (feiv_complev3, label(Outpatient)) (feiv_complev4, label(Professional)), bylabel(Levels) ///
    ||, keep(PH_VI) xline(0) byopts(cols(2) xrescale legend(rows(1))) coeflabels(PH_VI="Vertical Integration", angle(vertical) notick) yscale(noline)
graph save "${RESULTS_FINAL}Components_IV", replace
graph export "${RESULTS_FINAL}Components_IV.png", as(png) replace		



****************************************************************************************
** Components of professional services (before, during, after inpatient stay)
****************************************************************************************	
local step=0
foreach x of varlist pre_carrier_claims admit_carrier_claims post_carrier_claims ln_pre_pay ln_admit_pay ln_post_pay {
	local step=`step'+1

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_timing`step'	
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_timing`step'
}

** Display Results
estout fe_timing*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_timing*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
		

		
****************************************************************************************
** Unconditional quantile regressions
****************************************************************************************	
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
	xtrifreg ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS yearfx* drgfx* cat1fx* cat2fx* cat3fx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 monthfx*, ///
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
	legend(off) ytitle("Effects on Log Medicare Payments", margin(vsmall)) xtitle("Quantile of Log Payments", margin(vsmall)) ///
	xlabel(1 "0.2" 2 "0.3" 3 "0.4" 4 "0.5" 5 "0.6" 6 "0.7" 7 "0.8") ///
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}QReg_Payment_Episode", replace)
graph export "${RESULTS_FINAL}QReg_Payment_Episode.png", as(png) replace	
restore


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
	xtrifreg episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS yearfx* drgfx* cat1fx* cat2fx* cat3fx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 monthfx*, ///
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
	legend(off) ytitle("Effects on Episode Claims", margin(vsmall)) xtitle("Quantile of Claims", margin(vsmall)) ///
	xlabel(1 "0.2" 2 "0.3" 3 "0.4" 4 "0.5" 5 "0.6" 6 "0.7" 7 "0.8") ///
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}QReg_Claims_Episode", replace)
graph export "${RESULTS_FINAL}QReg_Claims_Episode.png", as(png) replace	

restore

	
	
****************************************************************************************
** Falsification test
****************************************************************************************	
local step=0
foreach x of varlist $OUTCOMES_FALSE {
	local step=`step'+1
	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month $PHY_MISS $HOSP_MISS, ///
		absorb(phy_hosp) cluster(physician_npi)
	est store fe_false`step'
}

** Display Results
estout fe_false*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI $PHY_CONTROLS $HOSP_CONTROLS)


****************************************************************************************
** Plausibly exogenous estimation
****************************************************************************************	
preserve
qui tab Year, gen(yearfx)
qui tab month, gen(monthfx)
qui tab clm_drg_cd, gen(drgfx)
qui tab cat_group1, gen(cat1fx)
qui tab cat_group2, gen(cat2fx)
qui tab cat_group3, gen(cat3fx)


local resid_step=0
foreach x of varlist $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS Hospital_VI yearfx* monthfx* drgfx* cat1fx* cat2fx* cat3fx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1  {
	local resid_step=`resid_step'+1
	qui areg `x', absorb(phy_hosp)
	predict residx_`resid_step', r
}
qui areg PH_VI, absorb(phy_hosp)
predict vi_resid, r

qui areg pred_vi1, absorb(phy_hosp)
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
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}Plausexog_Pay", replace)
graph export "${RESULTS_FINAL}Plausexog_Pay.png", as(png) replace	


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
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}Plausexog_Charge", replace)
graph export "${RESULTS_FINAL}Plausexog_Charge.png", as(png) replace	


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
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}Plausexog_Claims", replace)
graph export "${RESULTS_FINAL}Plausexog_Claims.png", as(png) replace	
restore

**test sign of exclusion restrictions
reghdfe ln_ep_pay PH_VI pred_vi1 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) vce(robust)
est store excl_1
reghdfe ln_ep_charge PH_VI pred_vi1 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) vce(robust)		
est store excl_2		
reghdfe episode_claims PH_VI pred_vi1 Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) vce(robust)		
est store excl_3
estout excl_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI pred_vi1)

	
	
****************************************************************************************
** Merge Bundled Payment Data
****************************************************************************************	
merge m:1 NPINUM Year using "${DATA_FINAL}PFP_Data.dta", nogenerate keep(master match)
forvalues i=1/4 {
	bys NPINUM Year: egen any_bp_`i'=max(bp_`i')
	replace bp_`i'=(any_bp_`i'>0 & any_bp_`i'!=.)
	gen vi_bp`i'=PH_VI*bp_`i'
	gen bp_iv`i'=pred_vi1*bp_`i'
}
gen any_bp=((bp_1>0 | bp_2>0 | bp_3>0 | bp_4>0) & (bp_1!=. & bp_2!=. & bp_3!=. & bp_4!=.))
gen vi_any_bp=PH_VI*any_bp
gen any_bp_iv = pred_vi1*any_bp
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1

	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month any_bp (PH_VI vi_any_bp=pred_vi1 any_bp_iv) , ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store bpcoef_`step'
		
}

** Display Results
estout bpcoef_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI any_bp vi_any_bp Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)


****************************************************************************************
** Examine referral patterns
****************************************************************************************	
merge 1:1 bene_id clm_id physician_npi NPINUM using "${DATA_FINAL}ReferralData.dta"
keep if _merge==3
drop _merge

gen same_phy_claims=carrier_same_phy
gen vi_phy_claims=carrier_vi_phy
gen other_phy_claims=carrier_claims-carrier_same_phy
gen other_nonvi_claims=carrier_claims-carrier_vi_phy
foreach x of varlist op_same_phy op_vi_phy op_same_hosp {
	replace `x'=`x'/op_claims
}

foreach x of varlist carrier_same_phy carrier_vi_phy carrier_same_hosp {
	replace `x'=`x'/carrier_claims
}

local step=0
foreach x of varlist $OUTCOMES_REFERRAL same_phy_claims vi_phy_claims other_nonvi_claims other_phy_claims {
	local step=`step'+1

	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1) , ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store refer_`step'
		
}


** Display Results
estout refer_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)


	
****************************************************************************************
** Referrals to where? (em, lab, imaging, and other)
****************************************************************************************	
local step=0
foreach x of varlist pre_em_claims pre_lab_claims pre_imaging_claims pre_other_claims {
	local step=`step'+1

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_pre_mode`step'	
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_pre_mode`step'
}

** Display Results
estout fe_pre_mode*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_pre_mode*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
		


local step=0
foreach x of varlist post_em_claims post_lab_claims post_imaging_claims post_other_claims {
	local step=`step'+1

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_post_mode`step'	
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_post_mode`step'
}

** Display Results
estout fe_post_mode*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_post_mode*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
		
		
		
local step=0
foreach x of varlist em_claims lab_claims imaging_claims other_claims {
	local step=`step'+1

	qui reghdfe `x' PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_all_mode`step'	
	
	qui reghdfe `x' Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_all_mode`step'
}

** Display Results
estout fe_all_mode*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)

estout feiv_all_mode*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS)
	
	
	
log close


****************************************************************************************
** Specification charts
****************************************************************************************
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
qui reghdfe ln_ep_pay PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_pay PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

keep if clm_drg_cd==460 | clm_drg_cd==461 | clm_drg_cd==462 | clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_pay PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe ln_ep_pay PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Payments, OLS, charts
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base hospital_vi quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.065
foreach var in base hospital_vi quality {
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



** plot
tw (scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital_vi rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.05(0.01).03, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.06 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.065 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.07 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.075 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.085 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.090 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.095 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.100 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.105 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.110 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.115 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.120 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.035 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Payments_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_Payments_Spec.png", as(png) replace	





*************************************************************
** Episode Payments with IV
use temp_spec_data, clear
qui reghdfe ln_ep_pay $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_pay Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe ln_ep_pay Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_pay $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe ln_ep_pay Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe ln_ep_pay Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

keep if clm_drg_cd==460 | clm_drg_cd==461 | clm_drg_cd==462 | clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_pay $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_pay Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe ln_ep_pay Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Payments, IV, charts
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base hospital_vi quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.17
foreach var in base hospital_vi quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.01
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.02
cap gen i_sample_full=`ind'
local ind=`ind'-0.01
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.01
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.01
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital_vi rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	yline(0, lpattern(dash)) ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.14(0.05).14, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.16 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.17 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.18 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.19 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.21 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.22 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.23 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.24 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.25 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.26 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.27 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.28 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.18 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Payments_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Payments_Spec.png", as(png) replace	




*************************************************************
** Episode Claims with OLS
use temp_spec_data, clear
qui reghdfe episode_claims PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe episode_claims PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

keep if clm_drg_cd==460 | clm_drg_cd==461 | clm_drg_cd==462 | clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe episode_claims PH_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe episode_claims PH_VI Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)



** Episode Claims, OLS, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base hospital_vi quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-6.9
foreach var in base hospital_vi quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.2
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.25
cap gen i_sample_full=`ind'
local ind=`ind'-0.2
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-0.2
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-0.2
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital_vi rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-6(1)1, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -6.7 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -6.9 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -7.1 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -7.3 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -7.55 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -7.75 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -7.95 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -8.15 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -8.35 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -8.55 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -8.75 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -8.95 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 1.5 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Claims_Spec", replace
graph export "${RESULTS_FINAL}OLS_Episode_Claims_Spec.png", as(png) replace	



*************************************************************
** Episode Claims with IV
use temp_spec_data, clear
qui reghdfe episode_claims $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe episode_claims Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe episode_claims Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe episode_claims $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe episode_claims Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe episode_claims Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

keep if clm_drg_cd==460 | clm_drg_cd==461 | clm_drg_cd==462 | clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe episode_claims $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe episode_claims Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe episode_claims Hospital_VI $PHY_CONTROLS $HOSP_CONTROLS $COUNTY_VARS $PHY_MISS $HOSP_MISS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=pred_vi1), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_drg)


** Episode Claims, IV, chart
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base hospital_vi quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-42
foreach var in base hospital_vi quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-2
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-3
cap gen i_sample_full=`ind'
local ind=`ind'-2
local scoff="`scoff' (scatter i_sample_full rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_full rank if sample_full==1, msize(vsmall) mcolor(black))"

forval i=10(10)50 {
	cap gen i_sample`i'=`ind'
	local ind=`ind'-2
	local scoff="`scoff' (scatter i_sample`i' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_sample`i' rank if sample`i'==1, msize(vsmall) mcolor(black))"
}

cap gen i_sample_drg=`ind'
local ind=`ind'-2
local scoff="`scoff' (scatter i_sample_drg rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_drg rank if sample_drg==1, msize(vsmall) mcolor(black))"



** plot
tw (scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) /// main specification
	(rline u95 l95 rank, lcolor(gs12)) /// 95% CI
	(scatter beta rank, mcolor(black) msymbol(D) msize(small)) /// point estimates
	`scoff' `scon' /// indicators for specification
	(scatter beta rank if hospital_vi==1 & sample_full==1, mcolor(blue) msymbol(D) msize(small)) ///
	(scatter i_sample_full rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)) ///	
	(scatter i_hospital_vi rank if hospital_vi==1 & sample_full==1, msize(vsmall) mcolor(blue)), ///
	legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-35(5)5, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -40 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -42 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -44 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -46 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -49 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -51 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -53 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -55 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -57 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -59 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -61 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -63 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 8 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Claims_Spec", replace
graph export "${RESULTS_FINAL}IV_Episode_Claims_Spec.png", as(png) replace	

