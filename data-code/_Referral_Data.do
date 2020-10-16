set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Referral_`logdate'.log", replace

******************************************************************
**	Title:			Build Referral Outcomes
**	Author:			Ian McCarthy
**	Date Created:	4/27/2020
**	Date Updated:	5/18/2020
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
global RESULTS_FINAL "S:\IMC969\Results\Physician Agency Episodes\"


** identify carrier patients
forvalues y=2008/2015 {
	insheet using "${DATA_SAS}CARRIER_`y'.tab", tab clear
	keep bene_id
	save carrier_patient_`y', replace
}
use carrier_patient_2008, clear
forvalues y=2009/2015 {
	append using carrier_patient_`y'
}
bys bene_id: gen obs=_n
keep if obs==1
drop obs
save carrier_patients, replace


forvalues y=2008/2015 {
	
	******************************************************************
	/* Get set of hospitals and physicians in final dataset */
	******************************************************************
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep if Year==`y'
	keep NPINUM physician_npi PH_VI
	bys NPINUM physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save temp_phyhosp_set, replace

	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep if Year==`y'
	keep NPINUM physician_npi PH_VI
	bys NPINUM physician_npi: gen obs=_n	
	keep if obs==1
	drop obs
	
	save temp1, replace
	keep if PH_VI==1
	bys physician_npi: gen obs=_n
	rename NPINUM int_hosp
	reshape wide int_hosp, i(physician_npi) j(obs)
	save temp_int, replace
	
	use temp1, clear
	keep if PH_VI==0
	bys physician_npi: gen obs=_n
	rename NPINUM noint_hosp
	reshape wide noint_hosp, i(physician_npi) j(obs)
	save temp_noint, replace
	
	use temp1, clear
	bys physician_npi: gen obs=_n
	keep if obs==1
	keep physician_npi
	
	merge 1:1 physician_npi using temp_int, nogenerate keep(master match)
	merge 1:1 physician_npi using temp_noint, nogenerate keep(master match)	
	save temp_phyint_only, replace
	
	
	******************************************************************
	/* Collect patient variables and individual outcome files */
	******************************************************************
	** Import patient data
	insheet using "${DATA_SAS}Patient_Data_`y'.tab", tab clear
	save temp_patient, replace

	** Import inpatient claims
	insheet using "${DATA_SAS}INPATIENTSTAYS_`y'.tab", tab clear
	drop prvdr_num
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	gen discharge=date(nch_bene_dschrg_dt, "DMY")
	replace discharge=date(clm_thru_dt, "DMY") if discharge==.
	gen admit=date(clm_from_dt,"DMY")
	gen admit_month=month(admit)
	
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(master match)
	save temp_ip_dat, replace
	
	keep bene_id admit clm_pmt_amt
	save ip_dat_small, replace

	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}INPATIENTSTAYS_`y_p1'.tab", tab clear
		drop prvdr_num
		rename org_npi_num NPINUM
		rename op_physn_npi physician_npi
		gen discharge=date(nch_bene_dschrg_dt, "DMY")
		replace discharge=date(clm_thru_dt, "DMY") if discharge==.
		gen admit=date(clm_from_dt,"DMY")
		gen admit_month=month(admit)
		drop if admit_month>3
		
		merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(master match)		
		save temp_ip_dat_next, replace
		
		keep bene_id admit clm_pmt_amt 
		save ip_dat_small_next, replace
	}
	
	
	** Import outpatient claims
	insheet using "${DATA_SAS}OPFINAL_`y'.tab", tab clear
	gen claim_date_op=date(clm_from_dt,"DMY")
	rename clm_pmt_amt pay_op
	rename clm_tot_chrg_amt charge_op
	rename clm_id claim_op
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(master match)	
	rename NPINUM op_hosp
	rename physician_npi op_phy	
	keep bene_id claim_date_op pay_op charge_op claim_op op_hosp op_phy PH_VI	
	save temp_op_dat, replace

	local y_l1=`y'-1
	insheet using "${DATA_SAS}OPFINAL_`y_l1'.tab", tab clear
	gen claim_date_op=date(clm_from_dt,"DMY")
	rename clm_pmt_amt pay_op
	rename clm_tot_chrg_amt charge_op
	rename clm_id claim_op
	gen claim_month=month(claim_date)
	drop if claim_month<12
	
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(master match)			
	
	rename NPINUM op_hosp
	rename physician_npi op_phy	
	keep bene_id claim_date_op pay_op charge_op claim_op op_hosp op_phy PH_VI
	save temp_op_dat_prior, replace
	
	use temp_op_dat, clear
	append using temp_op_dat_prior
	save temp_op_dat, replace
	
	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}OPFINAL_`y_p1'.tab", tab clear
		gen claim_date_op=date(clm_from_dt,"DMY")
		rename clm_pmt_amt pay_op
		rename clm_tot_chrg_amt charge_op
		rename clm_id claim_op
		gen claim_month=month(claim_date)
		drop if claim_month>3

		rename org_npi_num NPINUM
		rename op_physn_npi physician_npi
		merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(master match)
		
		rename NPINUM op_hosp
		rename physician_npi op_phy
		keep bene_id claim_date_op pay_op charge_op claim_op op_hosp op_phy PH_VI
		save temp_op_dat_next, replace
		
		use temp_op_dat, clear
		append using temp_op_dat_next
		save temp_op_dat, replace
	}
	
		

	** Import Carrier claims data
	insheet using "${DATA_SAS}CARRIER_`y'.tab", tab clear
	gen claim_date_carrier=date(claim_date, "DMY")
	keep bene_id claim_date_carrier carrier_claims carrier_charge carrier_pay physician_npi
	
	destring physician_npi, force replace
	merge m:1 physician_npi using temp_phyint_only, nogenerate keep(master match)
	
	rename physician_npi carrier_phy
	save temp_carrier_dat, replace
	
	local y_l1=`y'-1
	insheet using "${DATA_SAS}CARRIER_`y_l1'.tab", tab clear
	gen claim_date_carrier=date(claim_date, "DMY")
	gen claim_month=month(claim_date_carrier)
	drop if claim_month<12	
	keep bene_id claim_date_carrier carrier_claims carrier_charge carrier_pay physician_npi
	
	destring physician_npi, force replace
	merge m:1 physician_npi using temp_phyint_only, nogenerate keep(master match)
	
	rename physician_npi carrier_phy
	save temp_carrier_dat_prior, replace
		
	use temp_carrier_dat, clear
	append using temp_carrier_dat_prior
	save temp_carrier_dat, replace
		
		
	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}CARRIER_`y_p1'.tab", tab clear
		gen claim_date_carrier=date(claim_date, "DMY")
		gen claim_month=month(claim_date_carrier)
		drop if claim_month>3		
		keep bene_id claim_date_carrier carrier_claims carrier_charge carrier_pay physician_npi
		
		destring physician_npi, force replace
		merge m:1 physician_npi using temp_phyint_only, nogenerate keep(master match)
		rename physician_npi carrier_phy		
		save temp_carrier_dat_next, replace
		
		use temp_carrier_dat, clear
		append using temp_carrier_dat_next
		save temp_carrier_dat, replace
	}
	
	
	** Import Full Inpatient claims data
	insheet using "${DATA_SAS}OUTCOMES_`y'.tab", tab clear
	gen claim_date_ip=date(clm_from_dt, "DMY")
	rename clm_id claim_ipfull
	rename clm_tot_chrg_amt charge_ipfull
	rename clm_pmt_amt pay_ipfull
		
	keep bene_id claim_date_ip claim_ipfull charge_ipfull pay_ipfull
	save temp_ipfull_dat, replace
	
	local y_l1=`y'-1
	insheet using "${DATA_SAS}OUTCOMES_`y_l1'.tab", tab clear
	gen claim_date_ip=date(clm_from_dt, "DMY")
	rename clm_id claim_ipfull
	rename clm_tot_chrg_amt charge_ipfull
	rename clm_pmt_amt pay_ipfull
	gen claim_month=month(claim_date_ip)
	drop if claim_month<12	
	keep bene_id claim_date_ip claim_ipfull charge_ipfull pay_ipfull
	save temp_ipfull_dat_prior, replace
		
	use temp_ipfull_dat, clear
	append using temp_ipfull_dat_prior
	save temp_ipfull_dat, replace
	
	
	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}OUTCOMES_`y_p1'.tab", tab clear
		gen claim_date_ip=date(clm_from_dt, "DMY")
		rename clm_id claim_ipfull
		rename clm_tot_chrg_amt charge_ipfull
		rename clm_pmt_amt pay_ipfull
		gen claim_month=month(claim_date_ip)
		drop if claim_month>3		
		keep bene_id claim_date_ip claim_ipfull charge_ipfull pay_ipfull
		save temp_ipfull_dat_next, replace
		
		use temp_ipfull_dat, clear
		append using temp_ipfull_dat_next
		save temp_ipfull_dat, replace
	}
	
	
	******************************************************************
	/* Merge claims files */
	******************************************************************
	** Identify episodes
	use ip_dat_small, clear
	append using ip_dat_small_next
	
	bys bene_id admit: egen max_pay=max(clm_pmt_amt)
	bys bene_id admit: gen obs_count=_N
	drop if clm_pmt_amt!=max_pay & obs_count>1
	bys bene_id admit: gen obs_count2=_n
	keep if obs_count2==1
	drop obs_count obs_count2 max_pay
	
	tsset bene_id admit
	panelthin, min(90) gen(OK)
	keep if OK
	drop OK
	save temp_episode_dat, replace
	
	use temp_ip_dat, clear	
	bys bene_id admit: egen max_pay=max(clm_pmt_amt)
	bys bene_id admit: gen obs_count=_N
	drop if clm_pmt_amt!=max_pay & obs_count>1
	bys bene_id admit: gen obs_count2=_n
	keep if obs_count2==1
	drop obs_count obs_count2 max_pay
	merge 1:1 bene_id admit using temp_episode_dat, nogenerate keep(match)
	save temp_base_dat, replace
	
	
	** Outpatient claims
	use temp_base_dat, clear
	keep bene_id admit discharge NPINUM physician_npi clm_id admit_month
	
	merge m:m bene_id using temp_op_dat, nogenerate keep(match)
	keep if claim_date_op<=(discharge+90) & claim_date_op>(admit-30)
	
	gen op_same_phy=(op_phy==physician_npi)
	gen op_vi_phy=(PH_VI==1)
	gen op_same_hosp=(op_hosp==NPINUM)
	collapse (count) op_claims=claim_op (sum) op_same_phy op_vi_phy op_same_hosp charge_op pay_op, by(bene_id NPINUM clm_id)
	save temp_op_total, replace
	
	** Carrier claims	
	use temp_base_dat, clear
	keep bene_id admit discharge NPINUM physician_npi clm_id admit_month
	
	merge m:m bene_id using temp_carrier_dat, nogenerate keep(match)
	keep if claim_date_carrier<=(discharge+90) & claim_date_carrier>=(admit-30)
	
	gen carrier_same_phy=(carrier_phy==physician_npi)
	gen carrier_vi_phy=(PH_VI==1)
	gen carrier_same_hosp=0
	forvalues i=1/20 {
		capture confirm variable int_hosp`i'
		if !_rc {
			replace carrier_same_hosp=1 if int_hosp`i'==NPINUM
		}
	}
	collapse (sum) carrier_claims carrier_charge carrier_pay carrier_same_phy carrier_vi_phy carrier_same_hosp, by(bene_id NPINUM clm_id)
	save temp_carrier_total, replace
	
	** Merge datasets
	use temp_base_dat, clear
	
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(match)
	merge m:1 bene_id using temp_patient, nogenerate keep(master match)
	merge m:1 bene_id using "${DATA_FINAL}BENE_Spending_`y'.dta", nogenerate keep(master match)
	merge 1:1 bene_id NPINUM clm_id using temp_op_total, generate(OP_Match) keep(master match)	
	merge 1:1 bene_id NPINUM clm_id using temp_carrier_total, generate(Carrier_Match) keep(master match)	
	merge m:1 bene_id using carrier_patients, generate(Carrier_Any) keep(master match)
	
	** Clean data for analysis
	gen birthday=date(bene_birth_dt, "DMY")
	format birthday %td
	format discharge %td
	gen age=int( (discharge-birthday)/365.25)

	drop if age<65 
	drop if admit>=date("01OCT2015","DMY")

	keep physician_npi NPINUM bene_id clm_id admit ///
		op_same_phy op_vi_phy op_same_hosp carrier_same_phy carrier_vi_phy carrier_same_hosp 
	save "${DATA_FINAL}PatientLevel_Referral_`y'.dta", replace
	
}
	
******************************************************************
** Combine Spending Data

use "${DATA_FINAL}PatientLevel_Referral_2008.dta", clear
gen Year=2008
forvalues t=2009/2015 {
	append using "${DATA_FINAL}PatientLevel_Referral_`t'.dta"
	replace Year=`t' if Year==.
}
merge m:1 bene_id using carrier_patients
keep if _merge==3
drop _merge
save "${DATA_FINAL}ReferralData.dta", replace


log close