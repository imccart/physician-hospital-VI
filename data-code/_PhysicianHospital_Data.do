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
**	Date Updated:	5/15/2020
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

******************************************************************
** Apply sample criteria

** drop outer areas and hawaii/alaska
replace phy_state=hosp_state if phy_state=="" & hosp_state!=""
drop if phy_state=="PR" | phy_state=="GU" | phy_state=="VI" | phy_state=="AK" ///
   | phy_state=="HI" | phy_state=="MP" | phy_state=="PUERTO RICO" | phy_state=="FM" | phy_state=="PW"
replace phy_state="TX" if phy_state=="TEXAS"   

** drop physicians that operate in hospitals more than 120 miles away from office
bys physician_npi: egen max_distance=max(distance)
drop if max_distance>=120
drop max_distance

******************************************************************
** Additional Variables

** "ever" VI dummy
bys physician_npi: egen ever_VI=max(VI1)
replace ever_VI=0 if ever_VI==.

** Always/never purchased dummies
bys physician_npi: egen min_VI=min(VI1)
gen always_VI=(min_VI==1)
bys physician_npi: egen max_VI=max(VI1)
gen never_VI=(max_VI==0)
drop min_VI max_VI

** Clean missing VI
replace VI1=0 if VI1==. & never_VI==1
replace VI1=1 if VI1==. & always_VI==1

sort physician_npi Year
forvalues y=2008/2015 {
	gen vi_`y'=VI1 if Year==`y'
	by physician_npi: egen mean_vi`y'=mean(vi_`y')
	drop vi_`y'
}

forvalues y=2009/2015 {
	replace VI1=mean_vi`y' if Year==2008 & VI1==.
}
forvalues y=2008/2015 {
	replace VI1=mean_vi`y' if Year==2009 & VI1==.
    replace VI1=mean_vi`y' if Year==2010 & VI1==.	
	replace VI1=mean_vi`y' if Year==2011 & VI1==.	
	replace VI1=mean_vi`y' if Year==2012 & VI1==.
	replace VI1=mean_vi`y' if Year==2013 & VI1==.
	replace VI1=mean_vi`y' if Year==2014 & VI1==.
}

forvalues y=2014(-1)2008 {
	replace VI1=mean_vi`y' if Year==2015 & VI1==.
}
		
** drop if all years of VI data are missing (physician isn't in SK&A data)
gen byte missing=mi(VI1)
bys physician_npi: egen min_missing=min(missing)
**tab min_missing SKA_Merge
drop if min_missing==1
drop min_missing missing

******************************************************************
** Merge Additional Data
rename hospital_npi NPINUM
rename SKA_System_Code SKA_System_Code_Phy
merge m:1 NPINUM Year using "${DATA_FINAL}AllHospitals.dta", generate(MCRNUM_Merge) keep(master match) keepusing(MCRNUM)
merge m:1 MCRNUM Year using "${DATA_FINAL}HCRIS_Hospital_Level.dta", generate(HCRIS_Merge) keep(master match)
merge m:1 MCRNUM Year using "${DATA_FINAL}Hospital_PPS.dta", generate(PPS_Merge) keep(master match)
merge m:1 MCRNUM Year using "${DATA_FINAL}AHA_Data.dta", generate(AHA_Merge) keep(master match)
merge m:1 NPINUM physician_npi Year using "${DATA_FINAL}PH_Distance.dta", generate(PH_Distance_Match) keep(master match)
merge m:1 MCRNUM Year using "S:\IMC969\Stata Uploaded Data\SKA_HospitalLevel_v2.dta", generate(SKA_Hospital_Merge) keep(master match)
rename SKA_System_Code SKA_System_Code_Hosp

gen byte nonmiss=!mi(fips)
sort MCRNUM fips nonmiss
bys MCRNUM (nonmiss): replace fips=fips[_N] if nonmiss==0
drop nonmiss
merge m:1 fips Year using "${DATA_FINAL}ACS_Data.dta", generate(ACS_Merge) keep(master match)

drop mean_vi* rpt_rec_num street city state county zip fileid filetype stusab chariter sequence logrecno ///
	TotalPop_uw TotalHouse_uw sumlevel name
	
** Clean bed size variable
gen HBeds=BDTOT
replace HBeds=Beds/100 if HBeds==.
replace HBeds=beds/100 if HBeds==.
drop Beds beds BDTOT
rename HBeds Beds

	
******************************************************************
** Identify Hospital/Physician VI Match
******************************************************************
** Match by observed MCRNUM from hospital name / system name match
gen PH_VI=0
forvalues i=1/127 {
	replace PH_VI=1 if MCRNUM==MCRNUM`i' & MCRNUM!=.
}

** Match at system level using AHA system ID
gen SYS_VI=0
bys physician_npi SYSID Year: egen max_vi=max(VI1)
replace max_vi=. if SYSID==.
replace SYS_VI=1 if max_vi==1
replace PH_VI=1 if SYS_VI==1
drop max_vi

** Set PH_VI to 1 if physician is not observed to have operated in another hospital
** in the same year
bys physician_npi Year: gen all_hospitals=_N
bys physician_npi Year: egen max_vi=max(VI1)
replace PH_VI=1 if all_hospitals==1 & max_vi==1
drop max_vi

** count physicians without a match
bys physician_npi Year: gen obs=_n
bys physician_npi Year: egen max_phvi=max(PH_VI)
count if VI1==1 & max_phvi==0 & obs==1
count if VI1==1 & obs==1
gen PH_Match1=((max_phvi==1 & VI1==1) | VI1==0)
drop max_phvi

** Match by primary location of operations
bys physician_npi Year: egen max_patients=max(phyop_patients)
bys physician_npi Year: egen max_phvi=max(PH_VI)
replace PH_VI=1 if VI1==1 & max_phvi==0 & max_patients==phyop_patients
drop max_phvi

** Drop physicians without a match
bys physician_npi Year: egen max_phvi=max(PH_VI)
gen no_vi_match=(max_phvi==0 & VI1==1)
bys physician_npi: egen any_vi_miss=max(no_vi_match)
drop if any_vi_miss==1
drop max_phvi any_vi_miss no_vi_match

** Generate new hospital ID (system or npi based)
gen System_Group=SYSID
replace System_Group=NPINUM if System_Group==.
egen ID_System=group(System_Group)
drop System_Group

save "${DATA_FINAL}PhysicianHospital_Data.dta", replace
log close

