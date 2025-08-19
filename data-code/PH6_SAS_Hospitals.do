******************************************************************
**	Title:		PH6_SAS_HospitalsHospital
**	Description:	Collected hospital information from the CMS Medicare Claims Files. This
**			creates a "master" set of hospitals by NPINUM.
**	Author:		Ian McCarthy
**	Date Created:	10/9/17
**	Date Updated:	3/10/24
******************************************************************

******************************************************************
/* Read and Clean Hospital Data from SAS Analysis */
******************************************************************
forvalues t=2009/2015 {

	insheet using "${DATA_SAS}HOSPITAL_DATA_`t'.tab", tab clear
	gen byte notnumeric=(real(prvdr_num)==. & prvdr_num!="")
	replace prvdr_num="" if notnumeric==1
	destring prvdr_num, replace
	drop notnumeric
	gen Year=`t'
	save temp_hosp_`t', replace

}

use temp_hosp_2009, clear
forvalues t=2010/2015 {
	append using temp_hosp_`t'
}
rename org_npi_num NPINUM
rename prvdr_num MCRNUM

bys NPINUM Year: gen obs=_n
keep if obs==1
drop obs
save "${DATA_FINAL}AllHospitals.dta", replace
