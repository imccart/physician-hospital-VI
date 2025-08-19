******************************************************************
**	Title:		PH1_PhysicianHospitalIntegration
**	Description:	Measure integration for each physician-hospital pair and
**			identify candidate integration NPIs for all SKA physicians
**	Author:		Ian McCarthy
**	Date Created:	10/30/17
**	Date Updated:	3/9/24
******************************************************************


******************************************************************
/* Bi-annual SKA data */
******************************************************************
use "${DATA_UPLOAD}SKA_PhysicianLevel_v2.dta", clear
bys physician_npi Year: gen obs=_n
keep if obs==1
drop obs

keep physician_npi Year SKA_Practice_ID SKA_System_Code SKA_System_Name vert_integrated horz_integrated ///
	zip fips size ihs_prac ihs_new indy_prac ehr avg_exper avg_female adult_pcp multi surg

foreach x of varlist SKA_Practice_ID SKA_System_Code SKA_System_Name vert_integrated horz_integrated ///
	zip fips size ihs_prac ihs_new indy_prac ehr avg_exper avg_female adult_pcp multi surg {
		rename `x' `x'_v1
	}

preserve
keep if Year==2009
drop Year
save temp_ska1_2008, replace
restore

preserve
keep if Year==2009
drop Year
save temp_ska1_2009, replace
restore

preserve
keep if Year==2009
drop Year
save temp_ska1_2010, replace
restore

preserve
keep if Year==2011
drop Year
save temp_ska1_2011, replace
restore

preserve
keep if Year==2011
drop Year
save temp_ska1_2012, replace
restore

preserve
keep if Year==2013
drop Year
save temp_ska1_2013, replace
restore

preserve
keep if Year==2013
drop Year
save temp_ska1_2014, replace
restore

preserve
keep if Year==2015
drop Year
save temp_ska1_2015, replace
restore


******************************************************************
/* Read and Clean Physician Data from SAS Analysis */
******************************************************************

** 2009 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2009.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2009
save temp_phyaff_2009, replace


** 2010 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2010.tab", tab clear
keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2010
save temp_phyaff_2010, replace


** 2011 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2011.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2011
save temp_phyaff_2011, replace


** 2012 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2012.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2012
save temp_phyaff_2012, replace


** 2013 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2013.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

gen byte notnumeric=(real(phy_specialty)==.)
replace phy_specialty="" if notnumeric==1
destring phy_specialty, replace
drop notnumeric

keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2013
save temp_phyaff_2013, replace


** 2014 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2014.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

gen byte notnumeric=(real(phy_specialty)==.)
replace phy_specialty="" if notnumeric==1
destring phy_specialty, replace
drop notnumeric

keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2014
save temp_phyaff_2014, replace


** 2015 Data
insheet using "${DATA_SAS}PHYSICIAN_CHOICE_2015.tab", tab clear
gen byte notnumeric=(real(phy_zip)==.)
replace phy_zip="" if notnumeric==1
destring phy_zip, replace
drop notnumeric

gen byte notnumeric=(real(phy_specialty)==.)
replace phy_specialty="" if notnumeric==1
destring phy_specialty, replace
drop notnumeric

keep if total_phyip_claims>=5
drop if hospital_npi==.
bys physician_npi hospital_npi: gen phy_hosp_obs=_n
drop if phy_hosp_obs>1
drop phy_hosp_obs
gen HospitalShare=phyip_claims/total_phyip_claims
bys physician_npi: gen HospitalCount=_N
gen Year=2015
save temp_phyaff_2015, replace


******************************************************************
/* Data on physician practices from MDPPAS */
******************************************************************
forvalues t=2008(1)2015 {
	insheet using "${DATA_SAS}MDPPAS_V23_`t'.tab", tab clear
	gen birth_date=date(birth_dt, "DMY")
	format birth_date %td
	gen age = (td(1jan`t') - birth_date)/365.25
	replace age=floor(age)
	gen female=(sex=="F")
	
	keep npi age female tin1 tin2 tin1_unq_benes tin2_unq_benes cbsa_cd
	bys npi: gen npi_practice=_N
	drop if npi_practice>1
	bys tin1 cbsa_cd: gen prac_size=_N if tin1!=. & cbsa_cd!=.
	bys tin1 cbsa_cd: egen avg_female=mean(female) if tin1!=. & cbsa_cd!=.
	bys tin1 cbsa_cd: egen avg_age=mean(age) if tin1!=. & cbsa_cd!=.
	
**	keep npi age female tin1 tin2 tin1_unq_benes tin2_unq_benes prac_size avg_female avg_age cbsa_cd
	keep npi age female tin1 tin2 tin1_unq_benes tin2_unq_benes avg_age cbsa_cd
	destring npi, force replace
	rename npi physician_npi
	drop if physician_npi==.
	save temp_npi_practice_`t', replace
} 



******************************************************************
/* Vertical Integration Info from SKA and Observed Claims */
/* - This matching uses information from observed claims by limiting
     the set of possible matches only to those for which physicians have
	 observed billable activity. This avoids a lot of mismatched data
	 due to ambiguous or general hospital names (names are less ambiguous among
	 the set of hospitals for which a physician operates versus the full
	 set of hospitals in the country). */
******************************************************************


***********************************
** Annual SKA data
forvalues t=2009(1)2015 {
	if `t'==2009 {
		insheet using "${DATA_UPLOAD}ska-200910.CSV", clear
	}
	else if `t'==2010 {
		insheet using "${DATA_UPLOAD}ska-201004.CSV", clear
	}
	else if `t'==2011 {
		use "${DATA_UPLOAD}ska-201104.dta", clear
	}
	else if `t'==2012 {
		insheet using "${DATA_UPLOAD}ska-201210.CSV", clear
	}
	else if `t'==2013 {
		insheet using "${DATA_UPLOAD}ska-201310.CSV", clear
	}
	else if `t'==2014 {
		insheet using "${DATA_UPLOAD}ska-201410.CSV", clear
	}
	else if `t'==2015 {
		insheet using "${DATA_UPLOAD}ska-201504.CSV", clear
	}
	 
	rename id SKA_Practice_ID
	rename code4 SKA_System_Code
	rename expl4 SKA_System_Name
	rename code5 SKA_Hospital_Code
	rename expl5 SKA_Hospital_Name
	replace SKA_Hospital_Name=lower(SKA_Hospital_Name)
	replace SKA_System_Name=lower(SKA_System_Name)
	gen multi=(code2=="MUL")
	gen surg=(fs=="T")
	gen indy_prac=(SKA_System_Code=="" & code3=="")

	keep npi SKA_Practice_ID zip fips size multi surg indy_prac SKA_System_Code SKA_System_Name SKA_Hospital_Code SKA_Hospital_Name
	drop if npi==.
	bys npi: gen obs=_n
	keep if obs==1
	drop obs

	rename npi physician_npi
	merge 1:1 physician_npi using temp_ska1_`t', keep(master match) generate(SKA_Version_Merge)
	replace surg_v1=surg if surg_v1==.
	replace size=size_v1 if size==.
	keep physician_npi SKA_Practice_ID SKA_Hospital_Name SKA_System_Name SKA_System_Code SKA_Hospital_Code ///
		zip fips size multi indy_prac surg_v1 avg_female_v1 avg_exper_v1 adult_pcp_v1 ehr_v1
	foreach x of newlist surg avg_exper adult_pcp ehr avg_female {
		rename `x'_v1 `x'
	}
	rename size prac_size
	save temp_ska_`t', replace
}

/*
** compare versions of SKA
use temp_ska_2008, clear
browse physician_npi SKA_Hospital_Name SKA_System_Name SKA_System_Name_v1 surg surg_v1 multi multi_v1 size size_v1 indy_prac indy_prac_v1
*/

***********************************
** raw AHA data
forvalues t=2009(1)2015 {
	local y=substr("`t'",-2,.)
	if `t'==2009 {
		insheet using "${DATA_UPLOAD}pubas`y'.csv", clear case	
		capture confirm variable NPI_NUM
		if (_rc==0) {
			rename NPI_NUM NPINUM
		}		
	}
	else if inrange(`t',2010,2015) {
		insheet using "${DATA_UPLOAD}ASPUB`y'.csv", clear case
	}
	keep MNAME SYSID SYSNAME NPINUM MCRNUM
	destring MCRNUM, force replace
	drop if NPINUM==.
	bys NPINUM: gen obs=_n
	keep if obs==1
	drop obs

	rename NPINUM hospital_npi
	replace MNAME=lower(MNAME)
	replace SYSNAME=lower(SYSNAME)
	rename MNAME AHA_Hospital_Name
	rename SYSNAME AHA_System_Name
	save temp_aha_`t', replace
}


***********************************
** identify integrated pairs among primary operating physicians
forvalues t=2009(1)2015 {
	use temp_phyaff_`t', clear
	merge m:1 physician_npi using temp_ska_`t', generate(SKA_Match) keep(master match)
	merge m:1 hospital_npi using temp_aha_`t', nogenerate keep(master match)
	merge m:1 physician_npi using temp_npi_practice_`t', nogenerate keep(master match)
	replace hosp_name=lower(hosp_name)

	** clean names and deal with very common words 
	** 	- keeping common names for now because they are informative among the set of hospitals for which a physician operates
	foreach x of varlist hosp_name SKA_System_Name SKA_Hospital_Name AHA_System_Name AHA_Hospital_Name {
**		replace `x'=subinstr(`x',"medical center","",.)
**		replace `x'=subinstr(`x',"health","",.)	
**		replace `x'=subinstr(`x',"care","",.)
**		replace `x'=subinstr(`x',"hospital","",.)	
**		replace `x'=subinstr(`x',"system","",.)
**		replace `x'=subinstr(`x',"foundation","",.)
		replace `x'=subinstr(`x',"inc.","",.)
		replace `x'=subinstr(`x',",","",.)
**		replace `x'=subinstr(`x',"university","",.)	
		replace `x'=stritrim(`x')
		replace `x'=strtrim(`x')
	}

	** using system names from SKA and AHA
	gen system_nonmiss=(SKA_System_Name!="" & AHA_System_Name!="")
	strdist SKA_System_Name AHA_System_Name if system_nonmiss==1, generate(AHA_SKA_System_Match)
	bys physician_npi: egen min_match_val=min(AHA_SKA_System_Match)
	bys physician_npi: egen max_match_val=max(AHA_SKA_System_Match)
	gen system_match=(min_match_val==AHA_SKA_System_Match & system_nonmiss==1)
	drop min_match_val max_match_val

	** using hospital names from SKA and AHA
	gen aha_hosp_nonmiss=(SKA_Hospital_Name!="" & AHA_Hospital_Name!="")
	strdist SKA_Hospital_Name AHA_Hospital_Name if aha_hosp_nonmiss==1, generate(AHA_SKA_Hospital_Match)
	bys physician_npi: egen min_match_val=min(AHA_SKA_Hospital_Match)
	bys physician_npi: egen max_match_val=max(AHA_SKA_Hospital_Match)
	gen aha_hosp_match=(min_match_val==AHA_SKA_Hospital_Match & aha_hosp_nonmiss==1)
	drop min_match_val max_match_val

	** using hospital names from SKA and claims
	gen claim_hosp_nonmiss=(SKA_Hospital_Name!="" & hosp_name!="")
	strdist SKA_Hospital_Name hosp_name if claim_hosp_nonmiss==1, generate(Claim_SKA_Hospital_Match)
	bys physician_npi: egen min_match_val=min(Claim_SKA_Hospital_Match)
	bys physician_npi: egen max_match_val=max(Claim_SKA_Hospital_Match)
	gen claim_hosp_match=(min_match_val==Claim_SKA_Hospital_Match & claim_hosp_nonmiss==1)
	drop min_match_val max_match_val

	** using hospital names from AHA and system names from SKA
	gen other_nonmiss=(SKA_System_Name!="" & AHA_Hospital_Name!="")
	strdist SKA_System_Name AHA_Hospital_Name if other_nonmiss==1, generate(Other_Hospital_Match)
	bys physician_npi: egen min_match_val=min(Other_Hospital_Match)
	bys physician_npi: egen max_match_val=max(Other_Hospital_Match)
	gen other_hosp_match=(min_match_val==Other_Hospital_Match & other_nonmiss==1)
	drop min_match_val max_match_val

	** using hospital names from claims and system names from SKA
	gen other_claim_nonmiss=(SKA_System_Name!="" & hosp_name!="")
	strdist SKA_System_Name hosp_name if other_claim_nonmiss==1, generate(Other_Claim_Hospital_Match)
	bys physician_npi: egen min_match_val=min(Other_Claim_Hospital_Match)
	bys physician_npi: egen max_match_val=max(Other_Claim_Hospital_Match)
	gen other_claim_hosp_match=(min_match_val==Other_Claim_Hospital_Match & other_claim_nonmiss==1)
	drop min_match_val max_match_val
	
	
	** assign VI indicators	
	gen VI_any=(SKA_Hospital_Name!="" | SKA_System_Name!="")
	replace VI_any=. if SKA_Match==1
	gen rel_match_aha_sys=AHA_SKA_System_Match/strlen(SKA_System_Name)
	gen rel_match_aha_hosp=AHA_SKA_Hospital_Match/strlen(SKA_Hospital_Name)
	gen rel_match_claim_hosp=Claim_SKA_Hospital_Match/strlen(SKA_Hospital_Name)
	gen rel_match_other_hosp=Other_Hospital_Match/strlen(SKA_System_Name)
	gen rel_match_other_claim_hosp=Other_Claim_Hospital_Match/strlen(SKA_System_Name)
	egen best_match=rowmin(rel_match_aha_sys rel_match_aha_hosp rel_match_claim_hosp rel_match_other_hosp rel_match_other_claim_hosp)

	local step=0
	forvalues i=.25(.25).75 {
		local step=`step'+1
		local l=`i'-0.25
		gen VI_`step'=0
		replace VI_`step'=1 if system_match==1 & rel_match_aha_sys==best_match & best_match<`i' & best_match>=`l'
		replace VI_`step'=1 if aha_hosp_match==1 & rel_match_aha_hosp==best_match & best_match<`i' & best_match>=`l'
		replace VI_`step'=1 if claim_hosp_match==1 & rel_match_claim_hosp==best_match & best_match<`i' & best_match>=`l'
		replace VI_`step'=1 if other_hosp_match==1 & rel_match_other_hosp==best_match & best_match<`i' & best_match>=`l'
		replace VI_`step'=1 if other_claim_hosp_match==1 & rel_match_other_claim_hosp==best_match & best_match<`i' & best_match>=`l'
	}
	gen VI=VI_1 if VI_any==1
	replace VI=VI_2 if VI==0 & VI_any==1
	replace VI=0 if VI_any!=1
	bys physician_npi: egen sum_vi=total(VI)
	gen VI_assign=(sum_vi>0)
	gen VI_missing=(VI_assign==0 & VI_any==1)
	
	drop best_match system_match aha_hosp_match claim_hosp_match other_hosp_match other_claim_hosp_match ///
		system_nonmiss aha_hosp_nonmiss claim_hosp_nonmiss other_nonmiss other_claim_nonmiss rel_match_* ///
		AHA_SKA_Hospital_Match AHA_SKA_System_Match Claim_SKA_Hospital_Match Other_Hospital_Match sum_vi
	save ph_integration_`t', replace
}


***********************************
** identify integrated pairs among other (non-operating) physicians

forvalues t=2009(1)2015 {
	
	** crosswalk for practices matched in ph_integration
	use ph_integration_`t', clear
	keep if SKA_Match==3
	bys SKA_Practice_ID hospital_npi: egen practice_claims=total(phyip_claims)
	bys SKA_Practice_ID hospital_npi: gen obs=_n
	keep if obs==1
	keep SKA_Practice_ID hospital_npi practice_claims
	gsort SKA_Practice_ID hospital_npi -practice_claims
	drop practice_claims
	by SKA_Practice_ID: gen obs=_n
	reshape wide hospital_npi, i(SKA_Practice_ID) j(obs)
	save SKA_NPI_xwalk_`t', replace
	
	** crosswalk for hospital names matched in ph_integration
	use ph_integration_`t', clear
	keep if SKA_Match==3 & SKA_Hospital_Code!=""
	bys SKA_Hospital_Code hospital_npi: egen ska_claims=total(phyip_claims)
	bys SKA_Hospital_Code hospital_npi: gen obs=_n
	keep if obs==1
	keep SKA_Hospital_Code hospital_npi ska_claims
	gsort SKA_Hospital_Code hospital_npi -ska_claims
	drop ska_claims
	by SKA_Hospital_Code: gen obs=_n
	reshape wide hospital_npi, i(SKA_Hospital_Code) j(obs)
	save SKA_code_xwalk_`t', replace
	
	** crosswalk for system names matched in ph_integration
	use ph_integration_`t', clear
	keep if SKA_Match==3 & SKA_System_Code!=""
	bys SKA_System_Code hospital_npi: egen ska_claims=total(phyip_claims)
	bys SKA_System_Code hospital_npi: gen obs=_n
	keep if obs==1
	keep SKA_System_Code hospital_npi ska_claims
	gsort SKA_System_Code hospital_npi -ska_claims
	drop ska_claims
	by SKA_System_Code: gen obs=_n
	reshape wide hospital_npi, i(SKA_System_Code) j(obs)
	save SKA_system_xwalk_`t', replace	
	
	** merge MDPPAS data to SKA and integration based on practice ID
	use temp_npi_practice_`t', clear
	merge m:1 physician_npi using temp_ska_`t', generate(SKA_Match) keep(master match)
	merge m:1 SKA_Practice_ID using SKA_NPI_xwalk_`t', generate(SKA_NPI_Match) keep(master match)
	gen VI_any=(SKA_Hospital_Name!="" | SKA_System_Name!="")
	preserve
	keep if SKA_NPI_Match==3
	keep physician_npi SKA_Practice_ID hospital_npi* VI_any
	save ph_nonop_int1_`t', replace
	
	** for remaining NPIs from SKA, merge with all candidate hospitals based on name
	restore
	keep if SKA_Match==3 & SKA_NPI_Match==1
	merge m:1 SKA_Hospital_Code using SKA_code_xwalk_`t', generate(SKA_Code_Match) keep(master match)
	preserve
	keep if SKA_Code_Match==3
	keep physician_npi SKA_Practice_ID hospital_npi* VI_any
	save ph_nonop_int2_`t', replace
	
	** for remaining NPIs from SKA, merge with all candidate hospitals based on system
	restore
	keep if SKA_Match==3 & SKA_Code_Match==1
	merge m:1 SKA_System_Code using SKA_system_xwalk_`t', generate(SKA_System_Match) keep(master match)
	keep if SKA_System_Match==3
	keep physician_npi SKA_Practice_ID hospital_npi* VI_any
	save ph_nonop_int3_`t', replace

	** merge supplemental physician integration data
	use ph_nonop_int1_`t', clear
	append using ph_nonop_int2_`t'
	append using ph_nonop_int3_`t'
	gen Year=`t'
	save ph_other_integration_`t', replace
}



use ph_integration_2009, clear
forvalues t=2010/2015{
	append using ph_integration_`t', force
}

gen byte nonmiss=!mi(hosp_zip)
sort hospital_npi nonmiss
bys hospital_npi (nonmiss): replace hosp_zip=hosp_zip[_N] if nonmiss==0
drop nonmiss
save "${DATA_FINAL}PhysicianHospital_Integration.dta", replace


use ph_other_integration_2009, clear
forvalues t=2010/2015 {
	append using ph_other_integration_`t', force
}
save "${DATA_FINAL}PhysicianHospital_Other_Integration.dta", replace
