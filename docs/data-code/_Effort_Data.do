set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Effort_`logdate'.log", replace

******************************************************************
**	Title:			Spending_Data
**	Description:	Form extensive margin for physician-level analysis
**	Author:			Ian McCarthy
**	Date Created:	4/6/21
**	Date Updated:	4/28/22
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

forvalues y=2009/2015 {
	
	******************************************************************
	/* Get set of hospitals and physicians from final dataset */
	******************************************************************
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep if Year==`y'
	keep NPINUM physician_npi CCR
	bys NPINUM physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save temp_phyhosp_set, replace

	** Import inpatient claims
	insheet using "${DATA_SAS}INPATIENTSTAYS_`y'.tab", tab clear
	drop prvdr_num
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	gen discharge=date(nch_bene_dschrg_dt, "DMY")
	replace discharge=date(clm_thru_dt, "DMY") if discharge==.
	gen admit=date(clm_from_dt,"DMY")
	gen admit_month=month(admit)
	keep bene_id clm_id NPINUM physician_npi admit discharge clm_pmt_amt clm_drg_cd
	destring physician_npi, replace force
	collapse (count) claims=clm_id (sum) clm_pmt_amt, by(bene_id NPINUM physician_npi admit discharge clm_drg_cd)	
	gen claim_type="inpatient"
	gen year=`y'
	save temp_ip_dat, replace
		
	** Import outpatient claims
	insheet using "${DATA_SAS}FULLOUTPATIENT_`y'.tab", tab clear
	rename physician_id physician_npi
	rename op_pay clm_pmt_amt
	rename patients claims
	keep physician_npi clm_pmt_amt claims
	destring physician_npi, replace force
	gen claim_type="outpatient"
	gen year=`y'
	save temp_op_dat, replace

	** Import carrier claims data
	insheet using "${DATA_SAS}FULLCARRIER_`y'.tab", tab clear
	rename carrier_pay clm_pmt_amt
	rename carrier_claims claims
	rename physician_id physician_npi
	keep physician_npi claims clm_pmt_amt
	destring physician_npi, replace force
	gen claim_type="carrier"
	gen year=`y'
	save temp_carrier_dat, replace
				
	******************************************************************
	/* Merge claims files */
	******************************************************************
	use temp_ip_dat, clear
	keep physician_npi year claims clm_pmt_amt claim_type
	collapse (sum) claims clm_pmt_amt, by(physician_npi year claim_type)
	append using temp_carrier_dat	
	append using temp_op_dat
	save temp_effort_dat_`y', replace	
}


use temp_effort_dat_2009, clear
forvalues t=2010/2015 {
	append using temp_effort_dat_`t'
}
bys physician_npi year claim_type: gen obs=_N
drop if obs>1
drop obs

rename clm_pmt_amt pay_
rename claims claims_
reshape wide claims_ pay_, i(physician_npi year) j(claim_type, string)
save "${DATA_FINAL}PhysicianEffort.dta", replace


log close	

