set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )

******************************************************************
**	Title:		Build Quality Outcomes
**	Author:		Ian McCarthy
**	Date Created:	11/3/17
**	Date Updated:	3/17/24
******************************************************************

******************************************************************
** Preliminaries
set more off
global ROOT_PATH "/home/imc969/files/dua_027710/"
global PROJ_PATH "/home/imc969/files/dua_027710/ph-vi/"

cd "${ROOT_PATH}stata-ado"
global DATA_UPLOAD "${ROOT_PATH}data-external/"
global DATA_SAS "${ROOT_PATH}data-sas/"
global DATA_FINAL "${PROJ_PATH}data/"
global CODE_FILES "${PROJ_PATH}data-code/"
global RESULTS_FINAL "${PROJ_PATH}results/"

global LOG_PATH "${PROJ_PATH}logs/"
log using "${LOG_PATH}Quality_`logdate'.log", replace


******************************************************************
** Extract quality outcomes for each inpatient stay
forvalues y=2009/2015 {
	
	** outcome data from claims (for readmissions and complications)
	insheet using "${DATA_SAS}OUTCOMES_`y'.tab", tab clear
	gen any_ssi=0
	replace any_ssi=1 if ssi==1 | primaryssi==1
	gen any_sepsis=0
	replace any_sepsis=1 if sepsis==1 | primarysepsis==1
	gen any_comp=(any_ssi+any_sepsis>0)
	gen readmit=0
	replace readmit=1 if readmit_claims>0 & readmit_claims!=.
	gen admit=date(initial_admit, "DMY")
	gen discharge=date(initial_discharge, "DMY")
	keep bene_id admit discharge initial_id any_ssi any_sepsis any_comp readmit
	save temp_outcomes, replace
	
	** beneficiary data (for mortality measures)
	insheet using "${DATA_SAS}IP_PATIENT_DATA_`y'.tab", tab clear
	gen date_of_death=date(bene_death_dt, "DMY")
	save temp_mortality, replace
		
	** Merge datasets
	use "${DATA_FINAL}PatientLevel_Spend_`y'.dta", clear
	merge 1:1 bene_id admit discharge initial_id using temp_outcomes, generate(Outcomes_Match) keep(master match)
	merge m:1 bene_id using temp_mortality, generate(Patient_Match) keep(master match)
	
	format discharge %td
	format date_of_death %td
	gen mortality=( (date_of_death-discharge)<90 & date_of_death!=. & discharge!=.)

	** Keep primary variables for analysis
	keep physician_npi NPINUM bene_id initial_id admit discharge ///
		race_1 gender_1 age claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4 ///
		${PATIENT_VARS} cat_group1 cat_group2 cat_group3 cat_group4 cat_group5 clm_drg_cd Discharge_* ///
		any_ssi any_sepsis any_comp readmit mortality
	save "${DATA_FINAL}PatientLevel_Quality_`y'.dta", replace

}

use "${DATA_FINAL}PatientLevel_Quality_2009.dta", clear
gen Year=2009
forvalues y=2010/2015 {
	append using "${DATA_FINAL}PatientLevel_Quality_`y'.dta"
	replace Year=`y' if Year==.
}
save "${DATA_FINAL}PatientLevel_Quality.dta", replace

log close
