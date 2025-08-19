set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )

******************************************************************
**	Title:		Build Referral Outcomes
**	Author:		Ian McCarthy
**	Date Created:	4/27/20
**	Date Updated:	6/20/24
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
log using "${LOG_PATH}Referral_`logdate'.log", replace

******************************************************************
** merge integration to physician-bene level visits

forvalues y=2009/2015 {
	** physicians for which we observe some VI status
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep physician_npi
	bys physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save ph_list1, replace
	
	use "${DATA_FINAL}PhysicianHospital_Other_Integration.dta", clear
	keep physician_npi
	bys physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save ph_list2, replace
	
	use ph_list1, clear
	append using ph_list2
	bys physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save ph_list, replace
	
	** integration status for operating physicians
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep physician_npi NPINUM PH_VI Year
	rename NPINUM hospital_npi_vi
	keep if Year==`y' & PH_VI==1
	drop PH_VI Year
	sort physician_npi hospital_npi_vi
	by physician_npi: gen obs=_n
	reshape wide hospital_npi_vi, i(physician_npi) j(obs)
	save temp_phvi_1, replace
	
	** integration status for all physicians
	use "${DATA_FINAL}PhysicianHospital_Other_Integration.dta", clear
	keep if Year==`y'
	drop Year
	save temp_phvi_2, replace
	
	** episodes
	use "${DATA_FINAL}PatientLevel_Spend_`y'.dta", clear
	keep bene_id physician_npi NPINUM admit discharge initial_id 
	rename NPINUM hospital_npi
	rename physician_npi initial_physician
	save temp_episode, replace
	
	** Physicians visited after initial inpatient stay
	insheet using "${DATA_SAS}IP_PHYSICIANS_`y'.tab", tab clear
	rename op_physn_npi physician_npi
	drop if physician_npi==.
	gen admit=date(initial_admit, "DMY")
	gen discharge=date(initial_discharge, "DMY")
	drop initial_admit initial_discharge
	keep bene_id physician_npi admit discharge initial_id ip_admits ip_claims ip_charge ip_spend
	save temp_ip_physicians, replace
	
	** Physicians visited in outpatient setting
	insheet using "${DATA_SAS}OP_PHYSICIANS_`y'.tab", tab clear
	rename op_physn_npi physician_npi
	drop if physician_npi==.
	gen admit=date(initial_admit, "DMY")
	gen discharge=date(initial_discharge, "DMY")
	drop initial_admit initial_discharge
	keep bene_id physician_npi admit discharge initial_id op_events op_claims op_charge op_spend
	save temp_op_physicians, replace	
	
	** Physicians from carrier files
	insheet using "${DATA_SAS}CARRIER_PHYSICIANS_`y'.tab", tab clear
	rename prf_physn_npi physician_npi
	destring physician_npi, replace force
	drop if physician_npi==.
	gen admit=date(initial_admit, "DMY")
	gen discharge=date(initial_discharge, "DMY")
	drop initial_admit initial_discharge
	keep bene_id physician_npi admit discharge initial_id carrier_events carrier_claims carrier_srvc_count carrier_charge carrier_spend carrier_rvu
	gen admit_month=month(admit)
	forvalues m=1/12 {
		preserve
		keep if admit_month==`m'
		drop admit_month
		save temp_carrier_physicians`m', replace
		restore
	}

	** merge episode data to physician data and collapse
	foreach z of newlist ip op {
		use temp_episode, clear
		merge m:m admit discharge initial_id using temp_`z'_physicians, nogenerate keep(match)
		merge m:1 physician_npi using ph_list, generate(Any_VI_Data) keep(master match)
		merge m:1 physician_npi using temp_phvi_1, generate(VI_Only) keep(master match)
		merge m:1 physician_npi using temp_phvi_2, generate(VI_Other) keep(master match)
		gen status="_na"
		replace status="_same_phy" if physician_npi==initial_physician
		unab npilist: hospital_npi_vi*
		foreach x of local npilist {
			replace status="_vi1" if `x'==hospital_npi & `x'!=. & hospital_npi!=. & status=="_na" & VI_any==1
		}
		unab npilist: hospital_npi*
		foreach x of local npilist {
			replace status="_vi2" if `x'==hospital_npi & `x'!=. & hospital_npi!=. & status=="_na" & VI_any==1
		}
		replace status="_no_vi" if status=="_na" & Any_VI_Data==3
		keep bene_id admit discharge initial_id status `z'_*
		collapse (sum) `z'_*, by(bene_id admit discharge initial_id status)
		reshape wide `z'_*, i(bene_id admit discharge initial_id) j(status) string
		save temp_`z'_episode, replace
	}
	
	forvalues m=1/12 {
		use temp_episode, clear
		gen admit_month=month(admit)
		keep if admit_month==`m'
		merge m:m admit discharge initial_id using temp_carrier_physicians`m', nogenerate keep(match)
		merge m:1 physician_npi using ph_list, generate(Any_VI_Data) keep(master match)
		merge m:1 physician_npi using temp_phvi_1, generate(VI_Only) keep(master match)
		merge m:1 physician_npi using temp_phvi_2, generate(VI_Other) keep(master match)
		gen status="_na"
		replace status="_same_phy" if physician_npi==initial_physician
		unab npilist: hospital_npi_vi*
		foreach x of local npilist {
			replace status="_vi1" if `x'==hospital_npi & `x'!=. & hospital_npi!=. & status=="_na" & VI_any==1
		}
		unab npilist: hospital_npi*
		foreach x of local npilist {
			replace status="_vi2" if `x'==hospital_npi & `x'!=. & hospital_npi!=. & status=="_na" & VI_any==1
		}
		replace status="_no_vi" if status=="_na" & Any_VI_Data==3
		keep bene_id admit discharge initial_id status carrier_*
		collapse (sum) carrier_*, by(bene_id admit discharge initial_id status)
		reshape wide carrier_*, i(bene_id admit discharge initial_id) j(status) string
		save temp_carrier_episode`m', replace
	}
	use temp_carrier_episode1, clear
	forvalues m=2/12 {
		append using temp_carrier_episode`m'
	}
	collapse (sum) carrier_*, by(bene_id admit discharge initial_id)
	save temp_carrier_episode, replace
	
	** merge spending by vi status back to episode data
	use "${DATA_FINAL}PatientLevel_Spend_`y'.dta", clear
	keep bene_id admit discharge initial_id physician_npi NPINUM ///
		ip_events ip_spend ip_charge ip_claims op_events op_claims op_spend op_charge ///
		carrier_events carrier_claims carrier_spend carrier_charge ///
		episode_service_count episode_rvu episode_charge episode_spend episode_claims episode_npis episode_events
	merge 1:1 bene_id admit discharge initial_id using temp_ip_episode, generate(IP_Physician_Match) keep(master match)
	merge 1:1 bene_id admit discharge initial_id using temp_op_episode, generate(OP_Physician_Match) keep(master match)
	merge 1:1 bene_id admit discharge initial_id using temp_carrier_episode, generate(Carrier_Physician_Match) keep(master match)
	gen Year=`y'
	foreach x of newlist spend claims charge {
		egen episode_`x'_vi=rowtotal(carrier_`x'_vi2 carrier_`x'_vi1 carrier_`x'_same_phy op_`x'_vi2 op_`x'_vi1 op_`x'_same_phy ip_`x'_vi2 ip_`x'_vi1 ip_`x'_same_phy), missing
		egen carrier_`x'_vi=rowtotal(carrier_`x'_vi2 carrier_`x'_vi1 carrier_`x'_same_phy), missing
	}
	foreach x of newlist spend_no_vi claims_no_vi charge_no_vi {
		egen episode_`x'=rowtotal(carrier_`x' op_`x' ip_`x'), missing
	}	
	egen episode_events_vi=rowtotal(ip_admits_vi1 ip_admits_vi2 ip_admits_same_phy op_events_same_phy op_events_vi1 op_events_vi2 carrier_events_same_phy carrier_events_vi1 carrier_events_vi2)
	egen episode_events_no_vi=rowtotal(ip_admits_no_vi op_events_no_vi carrier_events_no_vi), missing
	egen episode_rvu_vi=rowtotal(carrier_rvu_vi1 carrier_rvu_vi2 carrier_rvu_same_phy), missing
	egen episode_service_vi=rowtotal(carrier_srvc_count_vi1 carrier_srvc_count_same_phy carrier_srvc_count_vi2), missing
	rename carrier_srvc_count_no_vi episode_service_no_vi
	rename carrier_rvu_no_vi episode_rvu_no_vi
	
	keep physician_npi NPINUM bene_id initial_id admit episode_* carrier_spend_vi carrier_claims_vi carrier_charge_vi carrier_spend_no_vi carrier_claims_no_vi carrier_charge_no_vi	
	save "${DATA_FINAL}PatientLevel_Referral_`y'.dta", replace
	
}

******************************************************************
** Combine Spending Data

use "${DATA_FINAL}PatientLevel_Referral_2009.dta", clear
gen Year=2009
forvalues t=2010/2015 {
	append using "${DATA_FINAL}PatientLevel_Referral_`t'.dta"
	replace Year=`t' if Year==.
}
save "${DATA_FINAL}ReferralData.dta", replace


log close
