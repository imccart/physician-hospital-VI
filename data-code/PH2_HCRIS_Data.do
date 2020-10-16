******************************************************************
**	Title:			PH2_HCRIS_DataHospital
**	Description:	Collected hospital information data from hospital cost reports. Each file was created
**					seperately for upload into the VRDC.
**	Author:			Ian McCarthy
**	Date Created:	10/9/17
**	Date Updated:	5/15/2020
******************************************************************


******************************************************************
/* Read in HCRIS Data */
******************************************************************
** 2007
insheet using "${DATA_HCRIS}HospitalData_2007.txt", comma clear
gen Year=2007
save temp_hcris_2007, replace


** 2008
insheet using "${DATA_HCRIS}HospitalData_2008.txt", comma clear
gen Year=2008
save temp_hcris_2008, replace


** 2009
insheet using "${DATA_HCRIS}HospitalData_2009.txt", comma clear
gen Year=2009
save temp_hcris_2009, replace


** 2010
insheet using "${DATA_HCRIS}HospitalData_2010a.txt", comma clear
gen Year=2010
save temp_hcris_2010a, replace

insheet using "${DATA_HCRIS}HospitalData_2010b.txt", comma clear
gen Year=2010
save temp_hcris_2010b, replace

use temp_hcris_2010a, clear
append using temp_hcris_2010b
bys rpt_rec_num: gen obs=_n
bys rpt_rec_num: gen maxobs=_N
keep if obs==1
drop obs maxobs
save temp_hcris_2010, replace


** 2011
insheet using "${DATA_HCRIS}HospitalData_2011a.txt", comma clear
gen Year=2011
save temp_hcris_2011a, replace

insheet using "${DATA_HCRIS}HospitalData_2011b.txt", comma clear
gen Year=2011
save temp_hcris_2011b, replace

use temp_hcris_2011a, clear
append using temp_hcris_2011b
bys rpt_rec_num: gen obs=_n
bys rpt_rec_num: gen maxobs=_N
keep if obs==1
drop obs maxobs
save temp_hcris_2011, replace


** 2012
insheet using "${DATA_HCRIS}HospitalData_2012.txt", comma clear
gen Year=2012
save temp_hcris_2012, replace


** 2013
insheet using "${DATA_HCRIS}HospitalData_2013.txt", comma clear
gen Year=2013
save temp_hcris_2013, replace


** 2014
insheet using "${DATA_HCRIS}HospitalData_2014.txt", comma clear
gen Year=2014
save temp_hcris_2014, replace


** 2015
insheet using "${DATA_HCRIS}HospitalData_2015.txt", comma clear
gen Year=2015
save temp_hcris_2015, replace


** Append data
use temp_hcris_2007, clear
forvalues t=2008/2015 {
	append using temp_hcris_`t'
}

******************************************************************
/* Create Final HCRIS Data */
******************************************************************
gen zip_5=substr(zip,1,5)
destring zip_5, replace
drop zip
rename zip_5 zip

** Generate price index
rename provider_number MCRNUM
drop if MCRNUM==.
gen fyear=clock(fy_end,"MDYhms")
format fyear %tc
gsort MCRNUM Year -fyear
by MCRNUM Year: gen obs=_n
drop if obs>1
drop obs

replace intcare_charges=0 if intcare_charges==.
replace ancserv_charges=0 if ancserv_charges==.
gen discount_factor=(1-tot_discounts/tot_charges)
gen price= (ip_charges + intcare_charges + ancserv_charges)*discount_factor - tot_mcarepymt
replace price= price/(total_discharges-mcare_discharges)

** Market Share
bys Year zip: egen Market_Discharges=total(total_discharges)
gen discharge_share=total_discharges/Market_Discharges
save "${DATA_FINAL}HCRIS_Hospital_Level.dta", replace

gen discharge_share2=discharge_share^2
collapse (sum) HHI_Discharge=discharge_share2 TotalBeds=beds (count) Hospitals=MCRNUM, by(zip Year)
sort zip Year
save "${DATA_FINAL}HCRIS_Zip_Level.dta", replace
