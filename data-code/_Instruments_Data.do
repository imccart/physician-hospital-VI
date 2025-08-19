set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )

******************************************************************
**	Title:		Instruments_Data
**	Description:	Run individual code files for instrument
**	Author:		Ian McCarthy
**	Date Created:	4/26/18
**	Date Updated:	3/22/24
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
log using "${LOG_PATH}Instruments_`logdate'.log", replace


******************************************************************
** Run Individual do Files
do "${CODE_FILES}IV_Replicate.do"

******************************************************************
** Total differential payment at practice level
use "${DATA_FINAL}PhysicianHospital_Data.dta", clear

preserve
keep if Year==2009
keep physician_npi tin1 
keep if tin1!=.
bys physician_npi: gen obs=_n
keep if obs==1
drop obs
rename tin1 tin_base
save temp_phy_tin, replace
restore

merge m:1 physician_npi Year using "${DATA_FINAL}PFS_Revenue_Replicate.dta", nogenerate keep(master match)
merge m:1 physician_npi using temp_phy_tin, nogenerate keep(master match)
keep physician_npi NPINUM Year tin_base totchange_rel_2010
bys physician_npi Year: gen phy_obs=_n
gen revchange=totchange_rel_2010 if phy_obs==1
replace revchange=0 if phy_obs>1
bys tin_base Year: egen total_revchange=total(revchange) if tin_base!=.
replace total_revchange=totchange_rel_2010 if tin_base==.
keep if phy_obs==1
keep physician_npi Year total_revchange tin_base
save "${DATA_FINAL}Total_PFS_Revenue.dta", replace

log close
