set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )

******************************************************************
**	Title:		Effort Data
**	Description:	Form extensive margin for physician-level analysis
**	Author:		Ian McCarthy
**	Date Created:	4/6/21
**	Date Updated:	5/6/24
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
log using "${LOG_PATH}Effort_`logdate'.log", replace

forvalues y=2009/2015 {
	insheet using "${DATA_SAS}HCPCS_ALL_`y'.tab", tab clear
	collapse (sum) carrier_claims, by(hcpcs_cd)
	gsort -carrier_claims
	gen rank=_n
	keep if rank<=50
	drop rank
	save top_codes_`y', replace
}
use top_codes_2009, clear
forvalues y=2010/2015 {
	append using top_codes_`y'
}
collapse (sum) carrier_claims, by(hcpcs_cd)
gsort -carrier_claims
gen rank=_n
keep if rank<=20
drop rank
rename carrier_claims total_code_claims
save top_codes_all, replace

******************************************************************
** Construct panel
forvalues y=2009/2015 {
	
	** office place of service
	insheet using "${DATA_SAS}HCPCS_OFFICE_`y'.tab", tab clear
	rename physician_id physician_npi
	gen year=`y'
	
	collapse (sum) office_patients=carrier_patients office_spend=carrier_spend office_rvus=carrier_rvus office_claims=carrier_claims, by(physician_npi)
	save temp_effort_office_`y', replace
	
	
	** OP place of service
	insheet using "${DATA_SAS}HCPCS_OP_`y'.tab", tab clear
	rename physician_id physician_npi
	gen year=`y'
	
	collapse (sum) op_patients=carrier_patients op_spend=carrier_spend op_rvus=carrier_rvus op_claims=carrier_claims, by(physician_npi)
	save temp_effort_op_`y', replace
	
	
	** by place of service and code
	insheet using "${DATA_SAS}HCPCS_ALL_`y'.tab", tab clear
	merge m:1 hcpcs_cd using top_codes_all, keep(match) nogenerate
	collapse (sum) carrier_claims carrier_patients carrier_spend carrier_rvus, by(physician_id hcpcs_cd)
	gsort physician_id -carrier_claims
	by physician_id: gen obs=_n
	rename physician_id physician_npi
	gen year=`y'
	save temp_effort_cd_`y', replace
	
	
	** merge physician-level datasets
	insheet using "${DATA_SAS}PHYSICIAN_DATA_`y'.tab", tab clear
	gen year=`y'	
	rename ip_patients totip_patients
	rename op_patients totop_patients
	
	merge 1:1 physician_npi using temp_effort_office_`y', nogenerate keep(master match)
	merge 1:1 physician_npi using temp_effort_op_`y', nogenerate keep(master match)
	
	replace totop_spend=totop_spend+op_spend
	gen totop_rvus=op_rvus
	keep physician_npi year carrier_rvus carrier_spend carrier_patients carrier_claims ///
		totip_spend totip_patients totip_claims totop_spend totop_patients totop_rvus totop_claims ///
		office_patients office_spend office_rvus office_claims
	
	save temp_effort_dat_`y', replace	
	
}


use temp_effort_dat_2009, clear
forvalues t=2010/2015 {
	append using temp_effort_dat_`t'
}
save "${DATA_FINAL}PhysicianEffort.dta", replace


use temp_effort_cd_2009, clear
forvalues t=2010/2015 {
	append using temp_effort_cd_`t'
}
save "${DATA_FINAL}PhysicianEffort_byCode.dta", replace


** extract IP data only (to append data with RVUs for IP setting)
forvalues y=2009/2015 {
	insheet using "${DATA_SAS}HCPCS_ALL_`y'.tab", tab clear
	keep if place==21
	collapse (sum) totip_rvus=carrier_rvus, by(physician_id)
	rename physician_id physician_npi
	gen year=`y'
	save temp_effort_ip_`y', replace
}

use temp_effort_ip_2009, clear
forvalues t=2010/2015 {
	append using temp_effort_ip_`t'
}
save "${DATA_FINAL}PhysicianEffort_IP.dta", replace


log close	



