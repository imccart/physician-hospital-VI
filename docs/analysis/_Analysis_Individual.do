set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Analysis_`logdate'.log", replace

******************************************************************
**	Title:			Analysis
**	Description:	Run all summary stats and regression analysis for physician agency/hospital influence paper.
**	Author:			Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	5/18/22
******************************************************************

cd "/home/imc969/files/dua_027710/stata-ado"

******************************************************************
** Preliminaries
set more off
set maxvar 10000
set scheme uncluttered

global DATA_FINAL "/home/imc969/files/dua_027710/ph-vi/data/"
global DATA_SAS "/home/imc969/files/dua_27710/data-sas/"
global RESULTS_FINAL "/home/imc969/files/dua_027710/ph-vi/results/"


******************************************************************
** Build final dataset

** reduce physician/hospital dataset to key variables and merge with instruments
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
drop MCRNUM* phyop_claims phyop_patients phy_carrier_claims phy_carrier_patients total_phyop_claims ///
	total_phyop_patients total_hosp_admits total_hosp_patients total_hosp_pymt total_hosp_charges total_hosp_drg
merge m:1 physician_npi Year using "${DATA_FINAL}PFS_Revenue.dta", generate(IV_Match1) keep(master match)
merge m:1 physician_npi Year using "${DATA_FINAL}Total_PFS_Revenue.dta", generate(IV_Match2) keep(master match)
merge m:1 physician_npi Year using "${DATA_FINAL}Predicted_EverVI.dta", generate(IV_Match3) keep(master match)
save temp_phyhosp, replace

** merge physician/hospital characteristics to episode-level spending & quality data
use "${DATA_FINAL}PatientLevel_Spend.dta", clear
merge 1:1 bene_id clm_id Year using "${DATA_FINAL}PatientLevel_Quality.dta", nogenerate keep(match)
merge m:1 physician_npi NPINUM Year using temp_phyhosp, nogenerate keep(match)

** final clean up
gen month=month(admit)
replace Year=year(admit)
format admit %td
drop if admit<d(01jan2010)
save temp_episode_spend, replace

/*
** quick check of episode spending as a share of total patient spending per year
forvalues y=2010/2015 {
	insheet using "${DATA_SAS}TOTALBENE_`y'.tab", tab clear
	
	gen yearly_parta_pay=tot_payment
	gen yearly_parta_claims=tot_claims
	gen Year=`y'
	keep bene_id Year yearly_parta_pay yearly_parta_claims
	save temp_pay1, replace
	
	insheet using "${DATA_SAS}CARRIER_`y'.tab", tab clear
	collapse (sum) yearly_carrier_pay=carrier_pay yearly_carrier_claims=carrier_claims, by(bene_id)
	gen Year=`y'
	save temp_pay2, replace
	
	use temp_episode_spend, clear
	keep bene_id admit Year pre_op_claims admit_op_claims post_op_claims pre_carrier_claims admit_carrier_claims post_carrier_claims episode_claims episode_pay
	keep if Year==`y'
	merge m:1 bene_id Year using temp_pay1, nogenerate keep(match)
	merge m:1 bene_id Year using temp_pay2, nogenerate keep(match)
	save temp_episode_spend_`y', replace	
}

use temp_episode_spend_2010, clear
forvalues y=2011/2015 {
	append using temp_episode_spend_`y'
}
gen admit_month=month(admit)
keep if admit_month>1 & admit_month<10
gen episode_share=episode_pay/(yearly_parta_pay + yearly_carrier_pay)
sum episode_share if episode_pay>0 & episode_pay!=.


** quick check of changes in tax IDs for acquired physicians
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
keep physician_npi tin1 PH_VI Year
bys physician_npi tin1 PH_VI Year: gen obs=_n
keep if obs==1
drop obs
bys physician_npi: egen min_vi=min(PH_VI)
bys physician_npi: egen max_vi=max(PH_VI)
keep if min_vi!=max_vi

*/

******************************************************************
** Create additional variables
******************************************************************
use temp_episode_spend, clear


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
gen ln_snf_pay=ln(pay_snf + 1)
gen ln_hha_pay=ln(pay_hha + 1)

count
count if unique_phy==1
count if unique_hosp==1
count if unique_pair==1

save "${DATA_FINAL}FinalEpisodesData.dta", replace

******************************************************************
** Global varlists
******************************************************************
use "${DATA_FINAL}FinalEpisodesData.dta", clear
global COUNTY_VARS TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black ///
	Income_50to75 Income_75to100 Income_100to150 Income_150plus Educ_HSGrad ///
	Educ_Bach Emp_FullTime Fips_Monopoly Fips_Duopoly Fips_Triopoly
global HOSP_CONTROLS Labor_Nurse Labor_Other Beds Profit System MajorTeaching
global OUTCOMES_SPEND episode_charge episode_pay ln_ep_charge ln_ep_pay episode_claims 
global OUTCOMES_QUAL mortality_90 readmit_90 sepsis ssi any_comp
global OUTCOMES_FALSE clm_pmt_amt ln_clm_pmt drgweight
global OUTCOMES_COMP ln_ep_pay ln_ip ln_op ln_carrier ln_snf_pay ln_hha_pay ln_ip_charge ln_op_charge ln_carrier_charge 
global OUTCOMES_REFERRAL op_same_phy op_vi_phy op_same_hosp carrier_same_phy carrier_vi_phy carrier_same_hosp
global PATIENT_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.clm_drg_cd
global ABSORB_VARS phy_hosp

******************************************************************
** Summary Statistics
******************************************************************
tab Year
tab Year if phy_obs==1
tab Year if hosp_obs==1
tab Year if fips_obs==1

** physician/hospital vars (Table 1 Summary Stats)
label variable episode_charge "Charges"
label variable episode_pay "Medicare Payments"
label variable ln_ep_charge "Log Charges"
label variable ln_ep_pay "Log Payments"
label variable episode_claims "Claims"
label variable mortality_90 "Mortality"
label variable readmit_90 "Readmission"
label variable sepsis "Sepsis"
label variable ssi "SSI"
label variable any_comp "Any Complication"
label variable PH_VI "Integrated"

forvalues t=2010/2015 {
	estpost sum ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} PH_VI if Year==`t'
	est store sum_phy_hosp_`t'
}
estpost sum ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} PH_VI
est store sum_phy_hosp_all

esttab sum_phy_hosp_2010 sum_phy_hosp_2011 sum_phy_hosp_2012 sum_phy_hosp_2013 sum_phy_hosp_2014 sum_phy_hosp_2015 sum_phy_hosp_all using "${RESULTS_FINAL}t1_episode_sum.tex", replace ///
	stats(N, fmt(%9.0fc) labels("\midrule Observations")) ///
	mtitle("2010" "2011" "2012" "2013" "2014" "2015" "Total") ///
	cells(mean(fmt(%9.3fc)) sd(par)) label booktabs nonum collabels(none) gaps f noobs


** physician vars (Table 2 Summary Stats)
label variable phy_episodes "Episodes"
label variable prac_size "Practice Size"
label variable avg_exper "Experience"
label variable avg_female "Female"
label variable adult_pcp "Includes PCP"
label variable multi "Multi-specialty"
label variable surg "Surgery Center"
label variable indy_prac "Independent"
label variable Physician_VI "Integrated"

forvalues t=2010/2015 {
	estpost sum phy_episodes ${PHY_CONTROLS} Physician_VI if phy_obs==1 & Year==`t'
	est store sum_phy_`t'
}
estpost sum phy_episodes ${PHY_CONTROLS} Physician_VI if phy_obs==1
est store sum_phy_all

esttab sum_phy_2010 sum_phy_2011 sum_phy_2012 sum_phy_2013 sum_phy_2014 sum_phy_2015 sum_phy_all using "${RESULTS_FINAL}t2_phy_sum.tex", replace ///
	stats(N, fmt(%9.0fc) labels("\midrule Observations")) ///
	mtitle("2010" "2011" "2012" "2013" "2014" "2015" "Total") ///
	cells(mean(fmt(%9.3fc)) sd(par)) label booktabs nonum collabels(none) gaps f noobs



** hospital vars (Table 3 Summary Stats)
label variable hosp_episodes "Episodes"
label variable Labor_Phys "Physician FTEs"
label variable Labor_Residents "Resident FTEs"
label variable Labor_Nurse "Nurse FTEs"
label variable Labor_Other "Other FTEs"
label variable Beds "Bed Size (100s)"
label variable Profit "For-profit"
label variable System "System Affiliation"
label variable MajorTeaching "Major Teaching"
label variable Hospital_VI "Integrated"

forvalues t=2010/2015 {
	estpost sum hosp_episodes ${HOSP_CONTROLS} Hospital_VI if hosp_obs==1 & Year==`t'
	est store sum_hosp_`t'
}
estpost sum hosp_episodes ${HOSP_CONTROLS} Hospital_VI if hosp_obs==1
est store sum_hosp_all

esttab sum_hosp_2010 sum_hosp_2011 sum_hosp_2012 sum_hosp_2013 sum_hosp_2014 sum_hosp_2015 sum_hosp_all using "${RESULTS_FINAL}t3_hosp_sum.tex", replace ///
	stats(N, fmt(%9.0fc) labels("\midrule Observations")) ///
	mtitle("2010" "2011" "2012" "2013" "2014" "2015" "Total") ///
	cells(mean(fmt(%9.3fc)) sd(par)) label booktabs nonum collabels(none) gaps f noobs


** histogram of DRGs for episodes (Figure 1)
preserve
drop if clm_drg_cd==10000 | clm_drg_cd==0
bys clm_drg_cd: gen drg_count=_N
keep if drg_count>10000
tab clm_drg_cd

gen t_count=0.001
graph bar (sum) t_count, over(clm_drg_cd) ytitle("Frequency of Top DRG Codes (1000s)") ///
	legend(off) plotregion(margin(medium)) intensity(60) blabel(bar, format(%3.0f))
graph save "${RESULTS_FINAL}f1_TopDRGs", replace
graph export "${RESULTS_FINAL}f1_TopDRGs.png", as(png) replace	
restore



******************************************************************
** Effect on Physician Behaviors
******************************************************************	

********************************************
** FE estimates for spending
use "${DATA_FINAL}FinalEpisodesData.dta", clear
est clear	
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	qui reghdfe `x' PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend1_`step'
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend2_`step'
			
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend3_`step'
}

** Display Results
label variable PH_VI "Integrated"
label variable hosp_episodes "Episodes"
label variable Labor_Nurse "Nurse FTEs"
label variable Labor_Other "Other FTEs"
label variable Beds "Bed Size (100s)"
label variable Profit "For-profit"
label variable System "System Affiliation"
label variable MajorTeaching "Major Teaching"
label variable Hospital_VI "Any Integration"

esttab fe_spend2_3 fe_spend2_4 fe_spend2_5 using "${RESULTS_FINAL}app_spend_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Log Charges" "Log Payments" "Number of Claims") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI Hospital_VI $HOSP_CONTROLS) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs
	

		
********************************************
** Event Study for PH VI
use "${DATA_FINAL}FinalEpisodesData.dta", clear
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
tab time, gen(ev_full)
gen never_vi=(ever_vi==0)
save temp_event_data, replace


** Traditional twfe event study
reghdfe ln_ep_pay ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff1
coefplot ev_coeff1, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Log Episode Payments") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventPay_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventPay_TWFE.png", as(png) replace	


reghdfe ln_ep_charge ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff2
coefplot ev_coeff2, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Log Episode Charges") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventCharge_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventCharge_TWFE.png", as(png) replace	


reghdfe episode_claims ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff3
coefplot ev_coeff3, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Episode Claims") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventClaims_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventClaims_TWFE.png", as(png) replace	

	
** Sun and Abraham
use temp_event_data, clear
replace ev_full10=1 if ev_full11==1

eventstudyinteract ln_ep_pay ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) covariates($PATIENT_VARS $HOSP_CONTROLS $COUNTY_VARS Hospital_VI) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa1

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Payments") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventPay_SA", replace
graph export "${RESULTS_FINAL}f2_EventPay_SA.png", as(png) replace	


eventstudyinteract ln_ep_charge ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) covariates($PATIENT_VARS $HOSP_CONTROLS $COUNTY_VARS Hospital_VI) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa2

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Charges") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventCharge_SA", replace
graph export "${RESULTS_FINAL}f2_EventCharge_SA.png", as(png) replace	


eventstudyinteract episode_claims ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) covariates($PATIENT_VARS $HOSP_CONTROLS $COUNTY_VARS Hospital_VI) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa3

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Episode Claims") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventClaims_SA", replace
graph export "${RESULTS_FINAL}f2_EventClaims_SA.png", as(png) replace	
	
	
** Callaway and Sant'Anna
use temp_event_data, clear
gen cs_time=first
replace cs_time=0 if ever_vi==0
csdid ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 , time(Year) gvar(cs_time) notyet cluster(physician_npi)
csdid_estat event
csdid_plot, ytitle(Estimated ATT)
gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
graph save "${RESULTS_FINAL}f2_EventPay_CSDID_Covars", replace
graph export "${RESULTS_FINAL}f2_EventPay_CSDID_Covars.png", as(png) replace

csdid ln_ep_charge Hospital_VI $HOSP_CONTROLS $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 , time(Year) gvar(cs_time) notyet cluster(physician_npi)
csdid_estat event
csdid_plot, ytitle(Estimated ATT)
gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
graph save "${RESULTS_FINAL}f2_EventCharge_CSDID_Covars", replace
graph export "${RESULTS_FINAL}f2_EventCharge_CSDID_Covars.png", as(png) replace

csdid episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1, time(Year) gvar(cs_time) notyet
csdid_estat event
csdid_plot, ytitle(Estimated ATT)
gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
graph save "${RESULTS_FINAL}f2_EventClaims_CSDID_Covars", replace
graph export "${RESULTS_FINAL}f2_EventClaims_CSDID_Covars.png", as(png) replace


csdid ln_ep_pay, time(Year) gvar(cs_time) notyet cluster(physician_npi)
csdid_estat event
csdid_plot, ytitle(Estimated ATT)
gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
graph save "${RESULTS_FINAL}f2_EventPay_CSDID_NoCovars", replace
graph export "${RESULTS_FINAL}f2_EventPay_CSDID_NoCovars.png", as(png) replace

csdid ln_ep_charge, time(Year) gvar(cs_time) notyet cluster(physician_npi)
csdid_estat event
csdid_plot, ytitle(Estimated ATT)
gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
graph save "${RESULTS_FINAL}f2_EventCharge_CSDID_NoCovars", replace
graph export "${RESULTS_FINAL}f2_EventCharge_CSDID_NoCovars.png", as(png) replace

csdid episode_claims, time(Year) gvar(cs_time) notyet cluster(physician_npi)
csdid_estat event
csdid_plot, ytitle(Estimated ATT)
gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
graph save "${RESULTS_FINAL}f2_EventClaims_CSDID_NoCovars", replace
graph export "${RESULTS_FINAL}f2_EventClaims_CSDID_NoCovars.png", as(png) replace


		
********************************************
** FE-IV 
use "${DATA_FINAL}FinalEpisodesData.dta", clear

** first-stage
reghdfe PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month total_revchange, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

** reduced form
reghdfe episode_claims total_revchange Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.month i.Year, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

		
** iv estimates		
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	
	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend`step'

}

** Display Results
esttab feiv_spend3 feiv_spend4 feiv_spend5 using "${RESULTS_FINAL}t4_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Log Charges" "Log Payments" "Number of Claims") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI Hospital_VI $HOSP_CONTROLS) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs
	

********************************************
** Investigate changes in quality
local step=0
foreach x of varlist $OUTCOMES_QUAL {
	local step=`step'+1
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_qual_`step'
		
	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_qual_`step'
}


** Display Results
esttab fe_qual_1 fe_qual_2 fe_qual_5 feiv_qual_1 feiv_qual_2 feiv_qual_5 using "${RESULTS_FINAL}app_quality.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Mortality" "Readmissions" "Complications" "Mortality" "Readmissions" "Complications") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI Hospital_VI $HOSP_CONTROLS) ///	
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs
	
	
		
****************************************************************************************
** Components of episode
****************************************************************************************	

** payments
qui reghdfe episode_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
est store feiv_comppay1

local step=1
foreach x of varlist pay_ip pay_op carrier_pay pay_snf pay_hha {
	replace `x'=0 if `x'<0	
	sum `x', detail
	local `x'_tail=r(p99)
	local step=`step'+1
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month if `x'<``x'_tail', ///
		absorb($ABSORB_VARS) cluster(physician_npi) old
	est store fe_comppay`step'	
	
	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange) if `x'<``x'_tail', ///
		absorb($ABSORB_VARS) cluster(physician_npi) old
	est store feiv_comppay`step'
}

** Display Results		
esttab feiv_comppay1 feiv_comppay2 feiv_comppay3 feiv_comppay4 feiv_comppay5 feiv_comppay6 using "${RESULTS_FINAL}t5_comp_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Episode" "Inpatient" "Outpatient" "Professional" "SNF" "Home Health") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs
	
	
** claims
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store feiv_claims1

local step=1
foreach x of varlist ip_claims op_claims carrier_claims snf_claims hha_claims {
	replace `x'=0 if `x'<0	
	sum `x', detail
	local `x'_tail=r(p99)
	local step=`step'+1
	
	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange)  if `x'<``x'_tail', ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_claims`step'
}

esttab feiv_claims1 feiv_claims2 feiv_claims3 feiv_claims4 feiv_claims5 feiv_claims6 using "${RESULTS_FINAL}t5_comp_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Episode" "Inpatient" "Outpatient" "Professional" "SNF" "Home Health") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs	

	
** event studies for components of episode
use temp_event_data, clear
gen cs_time=first
replace cs_time=0 if ever_vi==0

foreach x of pay_ip pay_op carrier_pay pay_snf pay_hha ip_claims op_claims carrier_claims snf_claims hha_claims {
	replace `x'=0 if `x'<0
	sum `x', detail
	local upper_tail=r(p99)
	csdid `x' if `x'<`upper_tail', time(Year) gvar(cs_time) notyet cluster(physician_npi)
	csdid_estat event
	csdid_plot, ytitle(Estimated ATT)
	gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
	graph save "${RESULTS_FINAL}csdid_comp_`x'", replace
	graph export "${RESULTS_FINAL}csdid_comp_`x'.png", as(png) replace
}
	

****************************************************************************************
** Unconditional quantile regressions
****************************************************************************************	
ivqreg2 ln_ep_pay PH_VI Hospital_VI, inst(total_revchange Hospital_VI) q(0.5)

preserve
qui tab Year, gen(yearfx)
qui tab NPINUM, gen(hospfx)
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
	xtrifreg ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS yearfx* drgfx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 monthfx*, ///
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
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}f7_QReg_Payment_Episode", replace)
graph export "${RESULTS_FINAL}f7_QReg_Payment_Episode.png", as(png) replace	
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
	xtrifreg episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS yearfx* drgfx* claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 monthfx*, ///
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
	ylabel( ,angle(0)) saving("${RESULTS_FINAL}f7_QReg_Claims_Episode", replace)
graph export "${RESULTS_FINAL}f7_QReg_Claims_Episode.png", as(png) replace	

restore

	
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

**test sign of exclusion restrictions
reghdfe ln_ep_pay PH_VI total_revchange Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) vce(robust)
est store excl_1
reghdfe ln_ep_charge PH_VI total_revchange Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) vce(robust)		
est store excl_2		
reghdfe episode_claims PH_VI total_revchange Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) vce(robust)		
est store excl_3
estout excl_*, style(tex) cells(b(star fmt(%10.3f)) ///
	se(par)) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01) keep(PH_VI total_revchange)

	
	
****************************************************************************************
** Examine referral patterns
****************************************************************************************
use "${DATA_FINAL}FinalEpisodesData.dta", clear
merge 1:1 bene_id clm_id physician_npi NPINUM using "${DATA_FINAL}ReferralData.dta"
keep if _merge==3
drop _merge

gen same_phy_claims=carrier_same_phy
gen vi_phy_claims=carrier_vi_phy
gen other_phy_claims=carrier_claims-carrier_same_phy
gen other_nonvi_claims=carrier_claims-carrier_vi_phy
sum same_phy_claims em_claims /*ratio suggests measure of how much of episode is affected by own-physician effort*/

foreach x of varlist op_same_phy op_vi_phy op_same_hosp {
	replace `x'=`x'/op_claims
}
foreach x of varlist carrier_same_phy carrier_vi_phy carrier_same_hosp {
	replace `x'=`x'/carrier_claims
}
gen pay_novi_phy=carrier_pay - pay_vi_phy


local step=0
foreach x of varlist same_phy_claims vi_phy_claims other_nonvi_claims pay_same_phy pay_vi_phy pay_novi_phy {
	replace `x'=0 if `x'<0
	sum `x', detail
	local `x'_tail=r(p99)
	local step=`step'+1

	qui reghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange)  if `x'<``x'_tail' , ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store refer_`step'
		
}


** Display Results
esttab refer_4 refer_5 refer_6 using "${RESULTS_FINAL}t7_refer_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Same Physician" "Other VI Physicians" "Other Non-VI Physicians") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs	

esttab refer_1 refer_2 refer_3 using "${RESULTS_FINAL}t7_refer_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Same Physician" "Other VI Physicians" "Other Non-VI Physicians") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs	

	
** event studies for referral patterns
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
tab time, gen(ev_full)
gen never_vi=(ever_vi==0)
gen cs_time=first
replace cs_time=0 if ever_vi==0

foreach x of varlist vi_phy_claims other_nonvi_claims pay_vi_phy pay_novi_phy {
	replace `x'=0 if `x'<0
	sum `x', detail
	local claims_tail=r(p99)
	csdid `x' if `x'<`claims_tail', time(Year) gvar(cs_time) notyet cluster(physician_npi)
	csdid_estat event
	csdid_plot, ytitle(Estimated ATT)
	gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
	graph save "${RESULTS_FINAL}csdid_`x'", replace
	graph export "${RESULTS_FINAL}csdid_`x'.png", as(png) replace
}	

	
****************************************************************************************
** Physician effort
****************************************************************************************	
use "${DATA_FINAL}FinalEpisodesData.dta", clear
keep physician_npi PH_VI total_revchange episode_pay episode_claims $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 Year
collapse (mean) total_revchange $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 (max) PH_VI (sum) episode_pay episode_claims, by(physician_npi Year)
gen year=Year
merge 1:1 physician_npi year using "${DATA_FINAL}PhysicianEffort.dta", nogenerate keep(master match)
drop year
bys physician_npi: gen year_count=_N

** Physician payments
replace pay_inpatient=0 if pay_inpatient<0
replace pay_outpatient=0 if pay_outpatient<0
replace pay_carrier=0 if pay_carrier<0
gen pay_all=pay_carrier + pay_inpatient + pay_outpatient


local step=0
foreach x of varlist pay_carrier pay_inpatient pay_outpatient pay_all {
    local step=`step'+1
	
	sum `x', detail
	local `x'_tail=r(p95)
	local `x'_low=r(p5)
	
	qui reghdfe `x' PH_VI $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1  i.Year if `x'<``x'_tail' & `x'>``x'_low', ///
		absorb(physician_npi) cluster(physician_npi)
	est store fe_effort_pay`step'	
	
	qui reghdfe `x' $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.Year (PH_VI=total_revchange) if `x'<``x'_tail'  & `x'>``x'_low', ///
		absorb(physician_npi) cluster(physician_npi)
	sum `x' if e(sample)==1
	est store feiv_effort_pay`step'
	
	reghdfe `x' $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.Year (PH_VI=total_revchange) if `x'<``x'_tail'  & `x'>``x'_low' & year_count==6, ///
		absorb(physician_npi) cluster(physician_npi)		
}
	
** Physician claims
gen claims_all=claims_carrier + claims_inpatient + claims_outpatient
local step=0
foreach x of varlist claims_carrier claims_inpatient claims_outpatient claims_all {
	local step=`step'+1
	
	sum `x', detail
	local `x'_tail=r(p95)
	local `x'_low=r(p5)
	
	qui reghdfe `x' PH_VI $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.Year if `x'<``x'_tail'  & `x'>``x'_low', ///
		absorb(physician_npi) cluster(physician_npi)
	est store fe_effort_claims`step'	
	
	qui reghdfe `x' $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.Year (PH_VI=total_revchange) if `x'<``x'_tail'  & `x'>``x'_low', ///
		absorb(physician_npi) cluster(physician_npi)
	sum `x' if e(sample)==1
	est store feiv_effort_claims`step'
	
	reghdfe `x' $COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.Year (PH_VI=total_revchange) if `x'<``x'_tail'  & `x'>``x'_low' & year_count==6, ///
		absorb(physician_npi) cluster(physician_npi)	
}

** Display Results
esttab feiv_effort_pay4 feiv_effort_pay1 feiv_effort_pay2 feiv_effort_pay3 using "${RESULTS_FINAL}t8_effort_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Total" "Professional Services" "Inpatient" "Outpatient") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%11.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs		
	

esttab feiv_effort_claims4 feiv_effort_claims1 feiv_effort_claims2 feiv_effort_claims3 using "${RESULTS_FINAL}t8_effort_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("Total" "Professional Services" "Inpatient" "Outpatient") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N, fmt(%9.0fc) labels(`"Observations"')) nonum collabels(none) gaps noobs		
	

	
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
	

foreach x of varlist claims_carrier claims_inpatient claims_outpatient claims_all pay_carrier pay_inpatient pay_outpatient pay_all {
	replace `x'=0 if `x'<0
	sum `x', detail
	local claims_tail=r(p95)
	local claims_low=r(p5)
	csdid `x' if `x'<`claims_tail' & `x'>`claims_low', time(Year) gvar(cs_time) notyet cluster(physician_npi)
	csdid_estat event
	csdid_plot, ytitle(Estimated ATT)
	gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
	graph save "${RESULTS_FINAL}csdid_`x'", replace
	graph export "${RESULTS_FINAL}csdid_`x'.png", as(png) replace
}	

replace ev_full10=1 if ev_full11==1
eventstudyinteract claims_carrier ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) covariates($COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1) control_cohort(never_vi) absorb(physician_npi) vce(cluster physician_npi)
est store ev_sa1

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Payments") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}carrier_claims_SA", replace
graph export "${RESULTS_FINAL}carrier_claims_SA.png", as(png) replace	


eventstudyinteract claims_inpatient ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) covariates($COUNTY_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1) control_cohort(never_vi) absorb(physician_npi) vce(cluster physician_npi)
est store ev_sa1

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Payments") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}ip_claims_SA", replace
graph export "${RESULTS_FINAL}ip_claims_SA.png", as(png) replace

	

keep if year_count==6
foreach x of varlist claims_carrier claims_inpatient claims_outpatient claims_all pay_carrier pay_inpatient pay_outpatient pay_all {
	replace `x'=0 if `x'<0
	sum `x', detail
	local claims_tail=r(p95)
	local claims_low=r(p5)
	csdid `x' if `x'<`claims_tail' & `x'>`claims_low', time(Year) gvar(cs_time) notyet ivar(physician_npi)
	csdid_estat event
	csdid_plot, ytitle(Estimated ATT)
	gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
	graph save "${RESULTS_FINAL}csdid_`x'_fe", replace
	graph export "${RESULTS_FINAL}csdid_`x'_fe.png", as(png) replace
}	

	
log close


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
qui reghdfe ln_ep_pay PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_pay PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_pay PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_snf)
			
qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore

keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_pay PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe ln_ep_pay PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
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
local ind=-0.025
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

cap gen i_sample_snf=`ind'
local ind=`ind'-0.005
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



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
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.01(0.01).02, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.02 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.025 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.03 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.035 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.045 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.050 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.055 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.060 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.065 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.070 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.075 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.080 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.085 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.025 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Payments_Spec2", replace
graph export "${RESULTS_FINAL}OLS_Episode_Payments_Spec2.png", as(png) replace	





*************************************************************
** Episode Payments with IV
use temp_spec_data, clear
qui reghdfe ln_ep_pay $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe ln_ep_pay $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi) old
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi) old
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi) old
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui reghdfe ln_ep_pay $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(hospital_vi sample_snf)
			
qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(quality sample_snf)
restore

keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe ln_ep_pay $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe ln_ep_pay Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi) old
specchart PH_VI, spec(quality sample_drg)


** Episode Payments, IV, charts
use "${RESULTS_FINAL}estimates.dta", clear
duplicates drop base hospital_vi quality sample*, force
**gsort -quality -hospital_vi -base -hosp_cluster -robust -sample_full -sample_drg -sample10 -sample20 -sample30 -sample40 -sample50, mfirst
sort beta
gen rank=_n

local scoff=" "
local scon=" "
local ind=-0.2
foreach var in base hospital_vi quality {
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
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-.1(0.1).2, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -.175 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.20 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.22 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.24 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -.27 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.29 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.31 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.33 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.35 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.37 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.39 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.41 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -.43 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.24 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Payments_Spec2", replace
graph export "${RESULTS_FINAL}IV_Episode_Payments_Spec2.png", as(png) replace	




*************************************************************
** Episode Claims with OLS
use temp_spec_data, clear
qui reghdfe episode_claims PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe episode_claims PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}

preserve
keep if Discharge_Home==1
qui reghdfe episode_claims PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_snf)
			
qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe episode_claims PH_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe episode_claims PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp, ///
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
local ind=-4.2
foreach var in base hospital_vi quality {
	cap gen i_`var'=`ind'
	local ind=`ind'-0.2
	local scoff="`scoff' (scatter i_`var' rank, msize(vsmall) mcolor(gs10))"
	local scon="`scon' (scatter i_`var' rank if `var'==1, msize(vsmall) mcolor(black))"
}


local ind=`ind'-0.4
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

cap gen i_sample_snf=`ind'
local ind=`ind'-0.2
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



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
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-4(0.5)0, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -4 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -4.2 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -4.4 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -4.6 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -5.0 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -5.2 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -5.4 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -5.6 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -5.8 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -6 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -6.2 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -6.4 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -6.6 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks 0.25 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}OLS_Episode_Claims_Spec2", replace
graph export "${RESULTS_FINAL}OLS_Episode_Claims_Spec2.png", as(png) replace	



*************************************************************
** Episode Claims with IV
use temp_spec_data, clear
qui reghdfe episode_claims $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_full) replace
	
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_full)
			
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_full)

bys phy_hosp: gen phy_hosp_obs=_N
forval i=10(10)50 {
	preserve
	keep if phy_hosp_obs>=`i'
	qui reghdfe episode_claims $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(base sample`i')
	
	qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(hospital_vi sample`i')
			
	qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	specchart PH_VI, spec(quality sample`i')
	restore
}
preserve
keep if Discharge_Home==1
qui reghdfe episode_claims $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_snf)
	
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_snf)
			
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(quality sample_snf)
restore


keep if clm_drg_cd==469 | clm_drg_cd==470
qui reghdfe episode_claims $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(base sample_drg)
	
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
	absorb($ABSORB_VARS) cluster(physician_npi)
specchart PH_VI, spec(hospital_vi sample_drg)
			
qui reghdfe episode_claims Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality_90 any_comp (PH_VI=total_revchange), ///
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
local ind=-49
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

cap gen i_sample_snf=`ind'
local ind=`ind'-2
local scoff="`scoff' (scatter i_sample_snf rank, msize(vsmall) mcolor(gs10))"
local scon="`scon' (scatter i_sample_snf rank if sample_snf==1, msize(vsmall) mcolor(black))"



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
	xtitle(" ") ytitle(" ") yscale(noline) xscale(noline) ylab(-45(5)-5, noticks nogrid angle(horizontal)) xlab("", noticks) ///
	graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))

gr_edit .yaxis1.add_ticks -47 `"Specification		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -49 `"Base"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -51 `"Hospital VI"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -53 `"Quality"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -56 `"Sample		"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -58 `"Full"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -60 `">=10"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -62 `">=20"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -64 `">=30"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -66 `">=40"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -68 `">=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -70 `"DRGs"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))
gr_edit .yaxis1.add_ticks -72 `"Home"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))))

gr_edit .yaxis1.add_ticks -2 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))))

graph save "${RESULTS_FINAL}IV_Episode_Claims_Spec2", replace
graph export "${RESULTS_FINAL}IV_Episode_Claims_Spec2.png", as(png) replace	

