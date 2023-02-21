******************************************************************
**	Title:			PH6_SAS_HospitalsHospital
**	Description:	Collected hospital information from the CMS Medicare Claims Files. This
**					creates a "master" set of hospitals by NPINUM.
**	Author:			Ian McCarthy
**	Date Created:	10/9/17
**	Date Updated:	5/15/2020
******************************************************************

******************************************************************
/* Read and Clean Hospital Data from SAS Analysis */
******************************************************************
insheet using "${DATA_SAS}Hospital_Data_2007.tab", tab clear
gen Year=2007
save temp_hosp_2007, replace

insheet using "${DATA_SAS}Hospital_Data_2008.tab", tab clear
gen Year=2008
save temp_hosp_2008, replace

insheet using "${DATA_SAS}Hospital_Data_2009.tab", tab clear
gen byte notnumeric=(real(prvdr_num)==. & prvdr_num!="")
replace prvdr_num="" if notnumeric==1
destring prvdr_num, replace
drop notnumeric
gen Year=2009
save temp_hosp_2009, replace

insheet using "${DATA_SAS}Hospital_Data_2010.tab", tab clear
gen byte notnumeric=(real(prvdr_num)==. & prvdr_num!="")
replace prvdr_num="" if notnumeric==1
destring prvdr_num, replace
drop notnumeric
gen Year=2010
save temp_hosp_2010, replace

insheet using "${DATA_SAS}Hospital_Data_2011.tab", tab clear
gen Year=2011
save temp_hosp_2011, replace

insheet using "${DATA_SAS}Hospital_Data_2012.tab", tab clear
gen Year=2012
save temp_hosp_2012, replace

insheet using "${DATA_SAS}Hospital_Data_2013.tab", tab clear
gen Year=2013
save temp_hosp_2013, replace

insheet using "${DATA_SAS}Hospital_Data_2014.tab", tab clear
gen Year=2014
save temp_hosp_2014, replace

insheet using "${DATA_SAS}Hospital_Data_2015.tab", tab clear
gen Year=2015
save temp_hosp_2015, replace

use temp_hosp_2007, clear
forvalues t=2008/2015 {
	append using temp_hosp_`t'
}
rename org_npi_num NPINUM
rename prvdr_num MCRNUM

bys NPINUM Year: gen obs=_n
keep if obs==1
drop obs
save "${DATA_FINAL}AllHospitals.dta", replace
