******************************************************************
**	Title:			PH1_PhysicianHospitalIntegration
**	Description:	Measure integration for each physician-hospital pair
**	Author:			Ian McCarthy
**	Date Created:	10/30/17
**	Date Updated:	5/15/2020
******************************************************************

** Drop physicians affiliated with multiple practices
** -- likely little if any effect since SK&A data include all physicians 
**    (not just surgeons)
use "S:\IMC969\Stata Uploaded Data\SKA_PhysicianLevel_v2.dta", clear
bys physician_npi Year: gen obs=_N
drop if obs>1
drop obs
save temp_ska_physician, replace

******************************************************************
/* Read and Clean NPI Integration Panel */
******************************************************************

** 2008 Data (have to use lagged 2009 data)
use temp_ska_physician, clear
keep if Year==2009
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2008
save temp_npi_vi_2008, replace


** 2009 Data
use temp_ska_physician, clear
keep if Year==2009
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2009
save temp_npi_vi_2009, replace


** 2010 Data - use 2009 or 2011
use temp_ska_physician, clear
keep if Year==2009
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2010
save temp_npi_vi_2010a, replace

use temp_ska_physician, clear
keep if Year==2011
drop Year
rename vert_integrated VI2
rename horz_integrated HI2
gen Year=2010
save temp_npi_vi_2010b, replace

use temp_npi_vi_2010a, clear
merge 1:1 physician_npi using temp_npi_vi_2010b
replace VI1=VI2 if _merge==2
replace HI1=HI2 if _merge==2
replace VI2=VI1 if _merge==1
replace HI2=HI1 if _merge==1
drop _merge
save temp_npi_vi_2010, replace


** 2011 Data
use temp_ska_physician, clear
keep if Year==2011
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2011
save temp_npi_vi_2011, replace


** 2012 Data - use 2011 or 2013
use temp_ska_physician, clear
keep if Year==2011
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2012
save temp_npi_vi_2012a, replace

use temp_ska_physician, clear
keep if Year==2013
drop Year
rename vert_integrated VI2
rename horz_integrated HI2
gen Year=2012
save temp_npi_vi_2012b, replace

use temp_npi_vi_2012a, clear
merge 1:1 physician_npi using temp_npi_vi_2012b
replace VI1=VI2 if _merge==2
replace HI1=HI2 if _merge==2
replace VI2=VI1 if _merge==1
replace HI2=HI1 if _merge==1
drop _merge
save temp_npi_vi_2012, replace


** 2013 Data
use temp_ska_physician, clear
keep if Year==2013
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2013
save temp_npi_vi_2013, replace


** 2014 Data - use 2013 or 2015
use temp_ska_physician, clear
keep if Year==2013
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2014
save temp_npi_vi_2014a, replace

use temp_ska_physician, clear
keep if Year==2015
drop Year
rename vert_integrated VI2
rename horz_integrated HI2
gen Year=2014
save temp_npi_vi_2014b, replace

use temp_npi_vi_2014a, clear
merge 1:1 physician_npi using temp_npi_vi_2014b
replace VI1=VI2 if _merge==2
replace HI1=HI2 if _merge==2
replace VI2=VI1 if _merge==1
replace HI2=HI1 if _merge==1
drop _merge
save temp_npi_vi_2014, replace

** 2015 Data
use temp_ska_physician, clear
keep if Year==2015
drop Year
rename vert_integrated VI1
rename horz_integrated HI1
gen Year=2015
save temp_npi_vi_2015, replace

** Append years
use temp_npi_vi_2008, clear
forvalues t=2009/2015 {
	append using temp_npi_vi_`t'
}
replace VI2=VI1 if VI2==. & VI1!=.
replace HI2=HI1 if HI2==. & HI1!=.
replace VI1=VI2 if VI1==. & VI2!=.
replace HI1=HI2 if HI1==. & HI2!=.

drop zip fips 
sort physician_npi Year
save "${DATA_FINAL}PhysicianIntegration.dta", replace



******************************************************************
/* Read and Clean Physician Data from SAS Analysis */
******************************************************************

** 2008 Data
insheet using "${DATA_SAS}Physician_Choice_2008.tab", tab clear
keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2008
save temp_phyaff_2008, replace


** 2009 Data
insheet using "${DATA_SAS}Physician_Choice_2009.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2009
save temp_phyaff_2009, replace


** 2010 Data
insheet using "${DATA_SAS}Physician_Choice_2010.tab", tab clear
keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2010
save temp_phyaff_2010, replace


** 2011 Data
insheet using "${DATA_SAS}Physician_Choice_2011.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2011
save temp_phyaff_2011, replace


** 2012 Data
insheet using "${DATA_SAS}Physician_Choice_2012.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2012
save temp_phyaff_2012, replace


** 2013 Data
insheet using "${DATA_SAS}Physician_Choice_2013.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

gen byte notnumeric=(real(phy_specialty)==.)
replace phy_specialty="" if notnumeric==1
destring phy_specialty, replace
drop notnumeric

keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2013
save temp_phyaff_2013, replace


** 2014 Data
insheet using "${DATA_SAS}Physician_Choice_2014.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

gen byte notnumeric=(real(phy_specialty)==.)
replace phy_specialty="" if notnumeric==1
destring phy_specialty, replace
drop notnumeric

keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2014
save temp_phyaff_2014, replace


** 2015 Data
insheet using "${DATA_SAS}Physician_Choice_2015.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

gen byte notnumeric=(real(phy_specialty)==.)
replace phy_specialty="" if notnumeric==1
destring phy_specialty, replace
drop notnumeric

keep if total_phyop_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyop_claims/total_phyop_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2015
save temp_phyaff_2015, replace

** Append years
use temp_phyaff_2008, clear
forvalues t=2009/2015{
	append using temp_phyaff_`t'
}

gen byte nonmiss=!mi(hosp_zip)
sort hospital_npi nonmiss
bys hospital_npi (nonmiss): replace hosp_zip=hosp_zip[_N] if nonmiss==0
drop nonmiss
save "${DATA_FINAL}Physician_Choice.dta", replace


******************************************************************
/* Merge affiliation and integration data */
******************************************************************
use "${DATA_FINAL}Physician_Choice.dta", clear
merge m:1 physician_npi Year using "${DATA_FINAL}PhysicianIntegration.dta", generate(SKA_Physician_Merge) keep(master match)
save "${DATA_FINAL}PhysicianHospital_Integration.dta", replace


