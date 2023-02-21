set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Quality_`logdate'.log", replace

******************************************************************
**	Title:			Build Quality Outcomes
**	Author:			Ian McCarthy
**	Date Created:	11/3/17
**	Date Updated:	8/6/2020
******************************************************************

******************************************************************
** Preliminaries
set more off
cd "S:\IMC969\Temp and ado files\"
global DATA_SAS "S:\IMC969\SAS Data v2\"
global DATA_DARTMOUTH "S:\IMC969\Stata Uploaded Data\"
global DATA_AHA "S:\IMC969\Stata Uploaded Data\AHA Data\"
global DATA_ACS "S:\IMC969\Stata Uploaded Data\ACS Data\"
global DATA_COMPARE "S:\IMC969\Stata Uploaded Data\Hospital Compare\"
global DATA_HCRIS "S:\IMC969\Stata Uploaded Data\Hospital Cost Reports\"
global DATA_IPPS "S:\IMC969\Stata Uploaded Data\Inpatient PPS\"
global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global CODE_FILES "S:\IMC969\Stata Code Files\Physician Agency Episodes\"


******************************************************************
** Extract quality outcomes for each inpatient stay
forvalues t=2008/2015 {

	******************************************************************
	/* Condense Physician/Hospital Data */
	******************************************************************
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep if Year==`t'
	keep NPINUM physician_npi
	bys NPINUM physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save temp_phyhosp_set, replace
	

	******************************************************************
	/* Merge patient and hospital characteristics */
	******************************************************************
	** First import patient data
	if `t' < 2015 {
		insheet using "${DATA_SAS}Patient_Data_`t'.tab", tab clear
		save temp_patient1, replace

		local next=`t'+1
		insheet using "${DATA_SAS}Patient_Data_`next'.tab", tab clear
		keep bene_id bene_death_dt
		rename bene_death_dt bene_death_dt2
		bys bene_id: gen obs=_n
		keep if obs==1
		drop obs
		save temp_patient2, replace

		use temp_patient1, clear
		merge m:1 bene_id using temp_patient2, nogenerate keep(master match)
		gen death_date=bene_death_dt
		replace death_date=bene_death_dt2 if death_date==""
		save temp_patient, replace
	}
	else if `t' >= 2015 {
		insheet using "${DATA_SAS}Patient_Data_`t'.tab", tab clear
		gen death_date=bene_death_dt
		save temp_patient, replace
	}


	** Now collect other outcome data and reshape to wide form
	if `t' < 2015 {
		insheet using "${DATA_SAS}Outcomes_`t'.tab", tab clear
		save temp_outcomes1, replace
		
		local next=`t'+1
		insheet using "${DATA_SAS}Outcomes_`next'.tab", tab clear
		gen ad_date=date(clm_from_dt, "DMY")
		keep if ad_date<date("01APR`next'","DMY")
		drop ad_date
		save temp_outcomes2, replace
		
		use temp_outcomes1, clear
		append using temp_outcomes2
		save temp_outcomes, replace
	}
	else if `t' >= 2015{
		insheet using "${DATA_SAS}Outcomes_`t'.tab", tab clear
		save temp_outcomes, replace
	}
	use temp_outcomes, clear
	sort bene_id clm_from_dt
	by bene_id: gen obs=_n
	by bene_id: gen max_obs=_N
	rename clm_id claim
	rename clm_from_dt admit

	egen p25=pctile(max_obs), p(25)
	egen p50=pctile(max_obs), p(50)
	egen p75=pctile(max_obs), p(75)

	drop clm_pmt_amt clm_tot_chrg_amt
	preserve
	keep if max_obs<=p25
	reshape wide claim admit sepsis ssi primarysepsis primaryssi, i(bene_id) j(obs)
	save temp_out_reshape25, replace
	restore

	preserve
	keep if max_obs>p25 & max_obs<=p50
	reshape wide claim admit sepsis ssi primarysepsis primaryssi, i(bene_id) j(obs)
	save temp_out_reshape50, replace
	restore

	preserve
	keep if max_obs>p50 & max_obs<=p75
	reshape wide claim admit sepsis ssi primarysepsis primaryssi, i(bene_id) j(obs)
	save temp_out_reshape75, replace
	restore

	keep if max_obs>p75
	reshape wide claim admit sepsis ssi primarysepsis primaryssi, i(bene_id) j(obs)
	save temp_out_reshape100, replace

	** Collect final outcome data merged to inpatient data
	forvalues i=25(25)100 {
		insheet using "${DATA_SAS}INPATIENTSTAYS_`t'.tab", tab clear
		gen discharge=date(nch_bene_dschrg_dt, "DMY")
		replace discharge=date(clm_thru_dt, "DMY") if discharge==.
		qui merge m:1 bene_id using temp_out_reshape`i', keep(match)
		qui sum max_obs
		local max_ad=r(max)
		gen readmit_30=0
		gen readmit_60=0
		gen readmit_90=0
		gen sepsis=0
		gen ssi=0
		forvalues s=1/`max_ad' {
			gen admit=date(admit`s',"DMY")
			format admit %td
			forvalues r=30(30)90 {
				replace readmit_`r'=1 if admit>discharge & admit<=(discharge+`r')
			}
			replace sepsis=1 if admit>discharge & admit<=(discharge+90) & (sepsis`s'==1 | primarysepsis`s'==1)
			replace sepsis=1 if claim`s'==clm_id & primarysepsis`s'==1
			replace ssi=1 if admit>discharge & admit<=(discharge+90) & (ssi`s'==1 | primaryssi`s'==1)
			replace ssi=1 if claim`s'==clm_id & primaryssi`s'==1		
			drop admit
		}
		keep bene_id clm_id readmit_30 readmit_60 readmit_90 sepsis ssi
		save temp_outcomes_`i', replace
	}
	use temp_outcomes_25, clear
	append using temp_outcomes_50
	append using temp_outcomes_75
	append using temp_outcomes_100
	save temp_outcomes_all, replace
		
	** Merge datasets
	insheet using "${DATA_SAS}INPATIENTSTAYS_`t'.tab", tab clear
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(match)
	merge m:1 bene_id using temp_patient, nogenerate keep(master match)
	qui merge m:1 bene_id clm_id using temp_outcomes_all, nogenerate keep(master match)

	** Create variables
	gen birthday=date(bene_birth_dt, "DMY")
	gen discharge=date(nch_bene_dschrg_dt, "DMY")
	replace discharge=date(clm_thru_dt, "DMY") if discharge==.
	gen death=date(death_date, "DMY")
	format birthday %td
	format discharge %td
	format death %td
	gen age=int( (discharge-birthday)/365.25)
	gen mortality_90=( (death-discharge)<90 & death!=. & discharge!=.)
	gen mortality_60=( (death-discharge)<60 & death!=. & discharge!=.)
	gen mortality_30=( (death-discharge)<30 & death!=. & discharge!=.)

	** Clean data for analysis
	drop if age<65 
	drop if discharge>=date("01OCT2015","DMY")
	gen any_comp=(sepsis==1 | ssi==1)
	global CAT_OUTCOMES mortality_90 mortality_60 mortality_30 readmit_90 readmit_60 readmit_30 ///
		sepsis ssi any_comp

	keep physician_npi NPINUM bene_id clm_id ${CAT_OUTCOMES}
	save "${DATA_FINAL}PatientLevel_Quality_`t'.dta", replace

}

use "${DATA_FINAL}PatientLevel_Quality_2008.dta", clear
gen Year=2008
forvalues t=2009/2015 {
	append using "${DATA_FINAL}PatientLevel_Quality_`t'.dta"
	replace Year=`t' if Year==.
}
keep bene_id clm_id Year mortality_90 mortality_60 mortality_30 readmit_90 readmit_60 readmit_30 sepsis ssi any_comp
save "${DATA_FINAL}PatientLevel_Quality.dta", replace

log close
