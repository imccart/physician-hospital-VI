******************************************************************
**	Title:		PH7_PFP_Data
**	Description:	Collect hospital data on participation in bundled payment programs
**	Author:		Ian McCarthy
**	Date Created:	10/16/17
**	Date Updated:	3/11/24
******************************************************************

** Import Medpar data (for bundled payment indicators)
forvalues y=2009/2015 {
	insheet using "${DATA_SAS}MEDPAR_`y'.tab", tab clear
	rename org_npi_num NPINUM
	gen bp_1=0
	gen bp_2=0
	gen bp_3=0
	gen bp_4=0
	forvalues i=1/4 {
		replace bp_1=1 if pfp_`i'==61
		replace bp_2=1 if pfp_`i'==62
		replace bp_3=1 if pfp_`i'==63
		replace bp_4=1 if pfp_`i'==64
	}
	collapse (mean) bp_1 bp_2 bp_3 bp_4, by(NPINUM)
	gen Year=`y'
	save temp_bundle_`y', replace
}

use temp_bundle_2009, clear
forvalues y=2010/2015 {
	append using temp_bundle_`y'
}

keep NPINUM Year bp_*
save "${DATA_FINAL}PFP_Data.dta", replace
