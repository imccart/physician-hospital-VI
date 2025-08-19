set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )

******************************************************************
**	Title:		main
**	Description:	Organize final analysis and call relevant analysis scripts
**	Author:		Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	6/20/24
******************************************************************

******************************************************************
** Preliminaries
set more off
global ROOT_PATH "/home/imc969/files/dua_027710/"
global PROJ_PATH "/home/imc969/files/dua_027710/ph-vi/"

cd "${ROOT_PATH}stata-ado"
global plusdir "${ROOT_PATH}stata-ado"
sysdir set PLUS $plusdir

set scheme uncluttered
global DATA_UPLOAD "${ROOT_PATH}data-external/"
global DATA_SAS "${ROOT_PATH}data-sas/"
global DATA_FINAL "${PROJ_PATH}data/"
global ANALYSIS "${PROJ_PATH}analysis/"
global CODE_FILES "${PROJ_PATH}data-code/"
global RESULTS_FINAL "${PROJ_PATH}results/"

global LOG_PATH "${PROJ_PATH}logs/"
log using "${LOG_PATH}Analysis_`logdate'.log", replace


** global varlists
global COUNTY_VARS TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black ///
	Income_50to75 Income_75to100 Income_100to150 Income_150plus Educ_HSGrad ///
	Educ_Bach Emp_FullTime Fips_Monopoly Fips_Duopoly Fips_Triopoly
global HOSP_CONTROLS Labor_Nurse Labor_Other Beds Profit System MajorTeaching
global PATIENT_VARS claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 race_1 gender_1 i.clm_drg_cd
global PHYSICIAN_VARS prac_size avg_exper avg_female adult_pcp multi surg indy_prac
global ABSORB_VARS phy_hosp
global OUTCOMES_SPEND episode_charge episode_spend episode_events episode_rvu episode_service_count episode_claims ln_ep_charge ln_ep_spend ln_ep_events ln_ep_service ln_ep_rvu ln_ep_claims
global OUTCOMES_QUAL mortality readmit any_sepsis any_ssi any_comp

******************************************************************
** Build analytic dataset

** identify 20 percent random sample of patients
forvalues y=2009/2015 {
	insheet using "${DATA_SAS}BENE_20PERCENT_`y'.tab", tab clear
	save bene_`y', replace
}
use bene_2009, clear
forvalues y=2010/2015 {
	append using bene_`y'
}
bys bene_id: gen obs=_n
keep if obs==1
keep bene_id
save bene_20percent, replace

** reduce physician/hospital dataset to key variables and merge with instruments
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
merge m:1 physician_npi Year using "${DATA_FINAL}PFS_Revenue.dta", generate(IV_Match1) keep(master match)
merge m:1 physician_npi Year using "${DATA_FINAL}Total_PFS_Revenue.dta", generate(IV_Match2) keep(master match)
save temp_phyhosp, replace

** merge physician/hospital characteristics to episode-level spending & quality data
use "${DATA_FINAL}PatientLevel_Spend.dta", clear
merge 1:1 bene_id initial_id Year using "${DATA_FINAL}PatientLevel_Quality.dta", nogenerate keep(match)
merge m:1 physician_npi NPINUM Year using temp_phyhosp, nogenerate keep(match)
merge m:1 bene_id using bene_20percent, nogenerate keep(match)
format admit %td
drop if admit<d(01jan2010) | admit>=d(01oct2015)
gen month=month(admit)
replace Year=year(admit)

** remove outliers (should always be positive)
foreach x of varlist admit_charge admit_claims admit_spend admit_service_count admit_rvu ///
	episode_charge episode_claims episode_spend episode_rvu episode_npis episode_events episode_service_count {
	replace `x'=. if `x'<0
	_pctile `x', percentiles(1 99)
	replace `x'=r(r1) if `x'<=r(r1) 
	replace `x'=r(r2) if `x'>=r(r2)
}

** remove outliers (should always be nonnegative but could be very low)
foreach x of varlist carrier_* imaging_* em_* lab_* ip_* op_* carrier_* snf_* hha_* tot_lab_* office_* other_* {
	replace `x'=0 if `x'==.
	replace `x'=. if `x'<0
	_pctile `x', percentiles(99)
	replace `x'=r(r1) if `x'>=r(r1)
}	
drop if episode_spend==. | episode_charge==. | admit_charge==. | admit_spend==. | total_revchange==. 

******************************************************************
** Create additional variables

** log of episode outcomes
gen ln_ep_charge=ln(episode_charge+1)
gen ln_ep_spend=ln(episode_spend+1)
gen ln_ep_service=ln(episode_service_count+1)
gen ln_ep_events=ln(episode_events+1)
gen ln_ep_rvu=ln(episode_rvu+1)
gen ln_ep_npis=ln(episode_npis+1)
gen ln_ep_claims=ln(episode_claims+1)

** log of initial admission outcomes
gen ln_admit_charge=ln(admit_charge+1)
gen ln_admit_spend=ln(admit_spend+1)
gen ln_admit_service=ln(admit_service_count+1)
gen ln_admit_rvu=ln(admit_rvu+1)
gen ln_admit_claims=ln(admit_claims+1)

** log of total inpatient outcomes
gen ln_ip_charge=ln(ip_charge+1)
gen ln_ip_spend=ln(ip_spend+1)
gen ln_ip_events=ln(ip_events+1)
gen ln_ip_npis=ln(ip_physicians+1)
gen ln_ip_service=ln(ip_service_count+1)
gen ln_ip_rvu=ln(ip_rvu+1)
gen ln_ip_claims=ln(ip_claims+1)

** log of outpatient outcomes
gen ln_op_charge=ln(op_charge+1)
gen ln_op_spend=ln(op_spend+1)
gen ln_op_events=ln(op_events+1)
gen ln_op_npis=ln(op_physicians+1)
gen ln_op_service=ln(op_service_count+1)
gen ln_op_rvu=ln(op_rvu+1)
gen ln_op_claims=ln(op_claims+1)


** log of carrier outcomes
gen ln_carrier_charge=ln(carrier_charge+1)
gen ln_carrier_spend=ln(carrier_spend+1)
gen ln_carrier_events=ln(carrier_events+1)
gen ln_carrier_npis=ln(carrier_physicians+1)
gen ln_carrier_claims=ln(carrier_claims+1)

** log of snf outcomes
gen ln_snf_charge=ln(snf_charge+1)
gen ln_snf_spend=ln(snf_spend+1)
gen ln_snf_events=ln(snf_events+1)
gen ln_snf_npis=ln(snf_physicians+1)
gen ln_snf_service=ln(snf_service_count+1)
gen ln_snf_rvu=ln(snf_rvu+1)
gen ln_snf_claims=ln(snf_claims+1)

** log of hha outcomes
gen ln_hha_charge=ln(hha_charge+1)
gen ln_hha_spend=ln(hha_spend + 1)
gen ln_hha_events=ln(hha_events+1)
gen ln_hha_npis=ln(hha_physicians+1)
gen ln_hha_service=ln(hha_service_count+1)
gen ln_hha_rvu=ln(hha_rvu+1)
gen ln_hha_claims=ln(hha_claims+1)

** log of lab outcomes
gen ln_lab_charge=ln(tot_lab_charge+1)
gen ln_lab_events=ln(tot_lab_events+1)
gen ln_lab_spend=ln(tot_lab_spend + 1)
gen ln_lab_service=ln(tot_lab_srvc_count+1)
gen ln_lab_rvu=ln(tot_lab_rvu+1)
gen ln_lab_claims=ln(tot_lab_claims+1)


** log of office outcomes
gen ln_office_charge=ln(office_charge+1)
gen ln_office_events=ln(office_events+1)
gen ln_office_spend=ln(office_spend + 1)
gen ln_office_service=ln(office_service_count+1)
gen ln_office_rvu=ln(office_rvu+1)
gen ln_office_claims=ln(office_claims+1)


** log of "other" outcomes
gen ln_other_charge=ln(other_charge+1)
gen ln_other_events=ln(other_events+1)
gen ln_other_spend=ln(other_spend + 1)
gen ln_other_service=ln(other_service_count+1)
gen ln_other_rvu=ln(other_rvu+1)
gen ln_other_claims=ln(other_claims+1)

** max VI by hospital and physician
bys NPINUM Year: egen Hospital_VI=max(PH_VI)
bys physician_npi Year: egen Physician_VI=max(PH_VI)

** clean population
replace TotalPop=TotalPop/1000

** Major Teaching Hospital
gen MajorTeaching=(Teaching_Hospital1==1)

** monopoly/duopoly/triopoloy indicators
bys NPINUM Year: gen hosp_obs=_n
gen hosp_first=(hosp_obs==1)
bys fips Year: egen Fips_Hospitals=total(hosp_first)
gen Fips_Monopoly=(Fips_Hospitals==1)
gen Fips_Duopoly=(Fips_Hospitals==2)
gen Fips_Triopoly=(Fips_Hospitals==3)
drop hosp_obs hosp_first

save temp_episode_spend, replace

******************************************************************
** Address missing covariates

** hospital variables
use temp_episode_spend, clear
keep NPINUM ${HOSP_CONTROLS} Year
bys NPINUM Year: gen obs=_n
keep if obs==1

** forward fill missing values
foreach x of varlist $HOSP_CONTROLS {
	by NPINUM (Year), sort: gen temp=`x'
	by NPINUM (Year), sort: replace `x'=cond(missing(`x'), temp[_n-1], `x')
	drop temp
}

** back fill missing values
foreach x of varlist $HOSP_CONTROLS {
	by NPINUM (Year), sort: gen temp=`x'
	by NPINUM (Year), sort: replace `x'=cond(missing(`x'), temp[_n+1], `x')
	drop temp
}

** fill with mean if still missing
foreach x of varlist Labor_Nurse Labor_Other Beds {
	bys NPINUM: egen `x'_mean=mean(`x')
	replace `x'=`x'_mean if `x'==.
}

** fill with max if still missing
foreach x of varlist Profit System MajorTeaching {
	bys NPINUM: egen `x'_max=max(`x')
	replace `x'=`x'_max if `x'==.
}
gen missing_hospital=0
foreach x of varlist $HOSP_CONTROLS {
	replace missing_hospital=1 if `x'==.
}
keep NPINUM Year $HOSP_CONTROLS missing_hospital
save hosp_controls_temp, replace


** county variables
use temp_episode_spend, clear
keep fips ${COUNTY_VARS} Year
bys fips Year: gen obs=_n
keep if obs==1

** forward fill missing values
foreach x of varlist $COUNTY_VARS {
	by fips (Year), sort: gen temp=`x'
	by fips (Year), sort: replace `x'=cond(missing(`x'), temp[_n-1], `x')
	drop temp
}

** back fill missing values
foreach x of varlist $COUNTY_VARS {
	by fips (Year), sort: gen temp=`x'
	by fips (Year), sort: replace `x'=cond(missing(`x'), temp[_n+1], `x')
	drop temp
}

** fill with mean if still missing
foreach x of varlist TotalPop Age_18to34 Age_35to64 Age_65plus Race_White Race_Black ///
	Income_50to75 Income_75to100 Income_100to150 Income_150plus Educ_HSGrad ///
	Educ_Bach Emp_FullTime {
	bys fips: egen `x'_mean=mean(`x')
	replace `x'=`x'_mean if `x'==.
}

** fill with max if still missing
foreach x of varlist Fips_Monopoly Fips_Duopoly Fips_Triopoly {
	bys fips: egen `x'_max=max(`x')
	replace `x'=`x'_max if `x'==.
}

gen missing_county=0
foreach x of varlist $COUNTY_VARS {
	replace missing_county=1 if `x'==.
}
keep fips Year $COUNTY_VARS missing_county
save county_controls_temp, replace

** merge back to main data
use temp_episode_spend, clear
drop $HOSP_CONTROLS 
drop $COUNTY_VARS
merge m:1 NPINUM Year using hosp_controls_temp, nogenerate keep(master match)
merge m:1 fips Year using county_controls_temp, nogenerate keep(master match)
drop if missing_hospital==1 | missing_county==1


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

** different groups
egen state_group=group(phy_state)
egen fips_group=group(fips)
egen phy_hosp=group(physician_npi NPINUM)

save "${DATA_FINAL}FinalEpisodesData.dta", replace


******************************************************************
** Analysis
******************************************************************	

do "${ANALYSIS}1_summary_stats.do"
do "${ANALYSIS}2_episodes.do"
do "${ANALYSIS}3_physician_effort.do"
do "${ANALYSIS}4_supplemental.do"

log close
