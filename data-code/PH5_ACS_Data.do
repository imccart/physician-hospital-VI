******************************************************************
**	Title:		PH5_ACS_Data
** 	Description:	Collect county demographic data from the ACS. Each ACS data
**			file was created seperately for upload into the VRDC.
**	Author:		Ian McCarthy
**	Date Created:	10/9/17
**	Date Updated:	3/10/24
******************************************************************

******************************************************************
/* Read and Clean ACS Data */
******************************************************************
use "${DATA_UPLOAD}ACS_DATA_2007.dta", clear
gen Year=2007
append using "${DATA_UPLOAD}ACS_DATA_2008.dta"
replace Year=2008 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2009.dta"
replace Year=2009 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2010.dta"
replace Year=2010 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2011.dta"
replace Year=2011 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2012.dta"
replace Year=2012 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2013.dta"
replace Year=2013 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2014.dta"
replace Year=2014 if Year==.
append using "${DATA_UPLOAD}ACS_DATA_2015.dta"
replace Year=2015 if Year==.
drop state county
save "${DATA_FINAL}ACS_Data.dta", replace

