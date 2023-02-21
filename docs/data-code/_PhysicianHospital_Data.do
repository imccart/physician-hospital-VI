set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\PhysicianHospitalDataBuild_`logdate'.log", replace

******************************************************************
**	Title:			PhysicianHospital_Data
**	Description:	Build Final Hospital/Physician-level Dataset for Agency/Hospital Influence Paper. This file
**					creates a unique set of all physician-hospital pairs and merges information about the
**					physician practice and acquiring hospital.
**	Author:			Ian McCarthy
**	Date Created:	11/29/17
**	Date Updated:	5/18/22
******************************************************************

******************************************************************
** Preliminaries
set more off
cd "S:\IMC969\Temp and ado files\"
global DATA_SAS "S:\IMC969\SAS Data v2\"
global DATA_HCRIS "S:\IMC969\Stata Uploaded Data\Hospital Cost Reports\"
global DATA_AHA "S:\IMC969\Stata Uploaded Data\AHA Data\"
global DATA_IPPS "S:\IMC969\Stata Uploaded Data\Inpatient PPS\"
global DATA_ACS "S:\IMC969\Stata Uploaded Data\ACS Data\"
global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global CODE_FILES "S:\IMC969\Stata Code Files\Physician Agency Episodes\"

/*
******************************************************************
** Run Individual do Files
do "${CODE_FILES}PH1_PhysicianHospitalIntegration.do"
do "${CODE_FILES}PH2_HCRIS_Data.do"
do "${CODE_FILES}PH3_Inpatient_PPS_Data.do"
do "${CODE_FILES}PH4_AHA_Data.do"
do "${CODE_FILES}PH5_ACS_Data.do"
do "${CODE_FILES}PH6_SAS_Hospitals.do"
do "${CODE_FILES}PH7_PFP_Data.do"
*/

******************************************************************
** Primary Data
use "${DATA_FINAL}PhysicianHospital_Integration.dta", clear
rename zip ska_zip
rename fips ska_fips
replace VI=0 if VI_1==0 & VI_2==1


******************************************************************
** Apply initial sample criteria

** drop outer areas and hawaii/alaska
replace phy_state=hosp_state if phy_state=="" & hosp_state!=""
drop if phy_state=="PR" | phy_state=="GU" | phy_state=="VI" | phy_state=="AK" ///
   | phy_state=="HI" | phy_state=="MP" | phy_state=="PUERTO RICO" | phy_state=="FM" | phy_state=="PW"
replace phy_state="TX" if phy_state=="TEXAS"   

** drop physicians that operate in hospitals more than 120 miles away from office
bys physician_npi: egen max_distance=max(distance)
drop if max_distance>=120
drop max_distance

** drop physicians that are in more than one practice (with sufficient patients in both)
replace tin1_unq_benes=0 if tin1_unq_benes==.
replace tin2_unq_benes=0 if tin2_unq_benes==.
gen tot_unique_benes=tin1_unq_benes + tin2_unq_benes
gen tin1_rel=tin1_unq_benes/tot_unique_benes
drop if tin2!=.

** drop if all years of VI data are missing (physician's practice is never in SK&A data)
gen byte missing=mi(VI_any)
bys tin1: egen min_missing=min(missing)
drop if min_missing==1
drop min_missing missing


******************************************************************
** Clean VI measure

** assign VI based on "any VI" and exclusive affiliation in claims
bys physician_npi Year: gen all_hospitals=_N
bys physician_npi Year: egen max_vi=max(VI_any)
replace VI=1 if all_hospitals==1 & max_vi==1 & VI_any==1
drop max_vi


** create final pairwise VI indicator
gen PH_VI=VI

** fill in PH_VI for same physician npi based on gaps
preserve
keep physician_npi hospital_npi Year PH_VI VI_any
bys physician_npi hospital_npi Year: gen obs=_n
bys physician_npi hospital_npi Year: egen max_ph_vi=max(PH_VI)
bys physician_npi hospital_npi Year: egen min_ph_vi=min(PH_VI)
keep if obs==1
drop obs min_ph_vi
egen phy_hospital=group(physician_npi hospital_npi)
xtset phy_hospital Year
sort phy_hospital Year
by phy_hospital: replace PH_VI=1 if L.PH_VI==1 & F.PH_VI==1 & (PH_VI==0 | PH_VI==.)
by phy_hospital: replace PH_VI=1 if L.PH_VI==1 & (PH_VI==. | PH_VI==0)
by phy_hospital: replace PH_VI=1 if L.PH_VI==1 & Year==2015 & VI_any==1

keep physician_npi hospital_npi Year PH_VI
rename PH_VI PH_VI_phy_fill
save phy_vi_fill, replace
restore

merge m:1 physician_npi hospital_npi Year using phy_vi_fill, keep(master match) nogenerate
replace PH_VI=1 if PH_VI_phy_fill==1 & (PH_VI==0 | PH_VI==.)


** drop remaining physicians with VI from SKA but no hospital match
bys physician_npi Year: egen max_phvi=max(PH_VI)
gen no_vi_match=(max_phvi==0 & VI_any==1)
bys physician_npi: egen any_vi_miss=max(no_vi_match)
drop if any_vi_miss==1
drop max_phvi any_vi_miss no_vi_match


** always/never purchased dummies
bys physician_npi: egen VI_min=min(PH_VI)
gen VI_always=(VI_min==1)
bys physician_npi: egen VI_max=max(PH_VI)
gen VI_never=(VI_max==0)
drop VI_min VI_max


******************************************************************
** Merge Additional Data
rename hospital_npi NPINUM
merge m:1 NPINUM Year using "${DATA_FINAL}AllHospitals.dta", generate(MCRNUM_Merge) keep(master match) keepusing(MCRNUM)
merge m:1 MCRNUM Year using "${DATA_FINAL}HCRIS_Hospital_Level.dta", generate(HCRIS_Merge) keep(master match)
merge m:1 MCRNUM Year using "${DATA_FINAL}Hospital_PPS.dta", generate(PPS_Merge) keep(master match)
merge m:1 MCRNUM Year using "${DATA_FINAL}AHA_Data.dta", generate(AHA_Merge) keep(master match)

gen byte nonmiss=!mi(fips)
sort MCRNUM fips nonmiss
bys MCRNUM (nonmiss): replace fips=fips[_N] if nonmiss==0
drop nonmiss
merge m:1 fips Year using "${DATA_FINAL}ACS_Data.dta", generate(ACS_Merge) keep(master match)

drop rpt_rec_num street city state county zip fileid filetype stusab chariter sequence logrecno ///
	TotalPop_uw TotalHouse_uw sumlevel name
	
** Clean bed size variable
gen HBeds=BDTOT
replace HBeds=Beds/100 if HBeds==.
replace HBeds=beds/100 if HBeds==.
drop Beds beds BDTOT
rename HBeds Beds


** Generate new hospital ID (system or npi based)
gen System_Group=SYSID
replace System_Group=NPINUM if System_Group==.
egen ID_System=group(System_Group)
drop System_Group


******************************************************************
** Save final dataset
save "${DATA_FINAL}PhysicianHospital_Data.dta", replace
log close


