set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )

******************************************************************
**	Title:		Spending_Data
**	Description:	Form spending and discharge outcomes for each episode
**	Author:		Ian McCarthy
**	Date Created:	11/3/17
**	Date Updated:	6/20/24
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
log using "${LOG_PATH}Spending_`logdate'.log", replace


******************************************************************
** Calculate averages and totals by patient

forvalues y=2009/2015 {
  insheet using "${DATA_SAS}IP_PATIENT_DATA_`y'.tab", tab clear
  gen Year=`y'
  egen tot_claims=rowtotal(totip_claims totop_claims totcarrier_claims), missing
  egen tot_charge=rowtotal(totip_charge totop_charge totcarrier_charge), missing
  egen tot_payment=rowtotal(totip_spend totop_spend totcarrier_spend), missing
  rename totcarrier_rvu tot_rvu
  keep bene_id tot_claims tot_charge tot_payment tot_rvu Year
  save temp_bene_`y', replace
}
use temp_bene_2009, clear
forvalues y=2010/2015 {
  append using temp_bene_`y'
}

forvalues y=2010/2015 {
  preserve
  keep if Year<`y'
  collapse (mean) avg_claims=tot_claims avg_pay=tot_payment avg_charge=tot_charge ///
	(sum) tot_claims tot_pay=tot_payment tot_charge, by(bene_id)
  gen Year=`y'
  replace tot_pay=0 if tot_pay==.
  replace tot_claims=0 if tot_claims==.
  sort bene_id
  save "${DATA_FINAL}BENE_Spending_`y'.dta", replace
  restore
}

******************************************************************
** Form episode measures

forvalues y=2009/2015 {	

	******************************************************************
	/* Collect relevant data from SAS pulls */
	******************************************************************
	** hospital/physician pairs
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep if Year==`y'
	keep NPINUM physician_npi CCR
	bys NPINUM physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save temp_phyhosp_set, replace

	** physician characteristics
	insheet using "${DATA_SAS}MDPPAS_V24_`y'.tab", tab clear
	destring npi, force replace
	rename npi physician_npi
	bys physician_npi: gen obs=_n
	drop if obs>1
	keep physician_npi spec_broad spec_prim_1 spec_prim_1_name
	save temp_physician_mdpps, replace

	** patient characteristics
	insheet using "${DATA_SAS}IP_PATIENT_DATA_`y'.tab", tab clear
	keep bene_id bene_birth_dt race gender 
	save temp_patient, replace
	
	** episode spending measures
	insheet using "${DATA_SAS}EPISODES_`y'.tab", tab clear
	foreach x of varlist initial_mcare_spend initial_mcare_charge initial_ip_spend ip_* op_* carrier_* imaging_* em_* lab_* ip_carrier_* hha_* snf_* {
		replace `x'=0 if `x'==.
	}
	egen episode_charge=rowtotal(initial_mcare_charge ip_charge op_charge carrier_charge snf_charge hha_charge), missing
	egen episode_spend=rowtotal(initial_ip_spend ip_spend op_spend carrier_spend snf_spend hha_spend), missing
	egen episode_claims=rowtotal(ip_claims op_claims carrier_claims snf_claims hha_claims), missing
	egen episode_npis=rowtotal(ip_physicians op_physicians carrier_physicians snf_physicians hha_physicians), missing
	egen episode_events=rowtotal(ip_admits op_events carrier_events snf_events hha_events), missing
	rename carrier_srvc_count episode_service_count
	rename carrier_rvu episode_rvu
	
	** initial inpatient spending measures
	egen admit_charge=rowtotal(initial_mcare_charge ip_carrier_charge), missing
	egen admit_spend=rowtotal(initial_ip_spend ip_carrier_spend), missing
	rename ip_carrier_claims admit_claims
	rename ip_carrier_srvc_count admit_service_count
	rename ip_carrier_rvu admit_rvu
	rename ip_carrier_events admit_events
	rename ip_carrier_physicians admit_physicians
	drop ip_carrier_* initial_mcare_charge initial_ip_spend initial_mcare_spend
	
	** rename to reflect facility 
	rename ip_admits ip_events
	foreach x of varlist ip_claims op_claims hha_claims snf_claims ip_spend op_spend hha_spend snf_spend ///
		ip_events op_events hha_events snf_events ip_charge op_charge hha_charge snf_charge {
			rename `x' facility_`x'
	}
	save temp_full_episode, replace
	
	
	** episode place of service
	insheet using "${DATA_SAS}CARRIER_PLACEOFSERVICE_`y'.tab", tab clear
	*** codes: SNF: 13, 14, 31, 32, 33
	***	   Office: 1 (pharmacy), 11, 15 (mobile), 20, 49, 50, 60, 71, 72
	***	   HHA: 12, 34 (hospice)
	***        IP: 21, 51 (psychiatric), 52 (psychiatric), 61 (rehab)
	***	   OP: 22, 23 (ED), 24 (ASC), 41 (land ambulance), 42 (air/water ambulance), 53 (mental health center), 62 (rehab), 65 (dialysis)
	***	   Lab: 81
	gen type=""
	replace type="lab" if inlist(line_place_of_srvc_cd, 81)
	replace type="op" if inlist(line_place_of_srvc_cd, 22)
	replace type="ip" if inlist(line_place_of_srvc_cd, 21)
	replace type="hha" if inlist(line_place_of_srvc_cd, 12)
	replace type="office" if inlist(line_place_of_srvc_cd, 11)
	replace type="snf" if inlist(line_place_of_srvc_cd, 31)
	replace type="other" if type==""
	foreach x of newlist events claims spend charge srvc_count rvu {
		rename carrier_`x' carrier_`x'_
	}
	rename carrier_srvc_count_ carrier_service_count_
	
	collapse (sum) carrier_events_ carrier_claims_ carrier_spend_ carrier_charge_ carrier_service_count_ carrier_rvu_, by(type bene_id initial_id initial_admit initial_discharge)
	reshape wide carrier_events_ carrier_claims_ carrier_spend_ carrier_charge_ carrier_service_count_ carrier_rvu_, i(bene_id initial_id initial_admit initial_discharge) j(type) string
	save temp_comp_episode, replace
	
	** combine full episode with components from carrier files
	use temp_full_episode, clear
	foreach x of varlist lab_claims lab_physicians lab_mcare_payment lab_srvc_count lab_charge lab_spend lab_rvu lab_events {
		rename `x' tot_`x'
	}
	merge 1:1 bene_id initial_id initial_admit initial_discharge using temp_comp_episode, nogenerate keep(master match)
	foreach x of newlist ip op hha snf {
		foreach z of newlist events claims spend charge {
			egen `x'_`z'=rowtotal(facility_`x'_`z' carrier_`z'_`x'), missing
		}
	}
	foreach x of newlist lab office other {
		foreach z of newlist events claims spend charge {
			rename carrier_`z'_`x' `x'_`z'
		}
	}	
	foreach x of newlist ip op hha snf lab office other {
		rename carrier_rvu_`x' `x'_rvu 
		rename carrier_service_count_`x' `x'_service_count
	}
	
	gen admit=date(initial_admit,"DMY")
	gen discharge=date(initial_discharge,"DMY")
	keep bene_id initial_id admit discharge episode_* admit_* imaging_* em_* lab_* tot_lab_* ip_* op_* snf_* hha_* office_* other_* ///
		carrier_events carrier_claims carrier_physicians carrier_charge carrier_spend
	order bene_id initial_id admit discharge episode_* admit_* ip_* op_* snf_* hha_* imaging_* em_* lab_* tot_lab_* office_* other_* carrier_*
	save temp_episode, replace

	
	******************************************************************
	/* Combine datsets */
	******************************************************************
	insheet using "${DATA_SAS}INPATIENTSTAYS_`y'.tab", tab clear
	gen admit=date(clm_admsn_dt,"DMY")
	gen discharge=date(nch_bene_dschrg_dt,"DMY")
	rename clm_id initial_id
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	rename admtg_dgns_cd main_icd1
	rename prncpal_dgns_cd main_icd2
	keep bene_id initial_id admit discharge NPINUM physician_npi clm_drg_cd dchrg_sts clm_drg_cd icd_dgns_cd* main_icd* drgweight
	
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(match)
	merge 1:1 bene_id initial_id admit discharge using temp_episode, nogenerate keep(match)
	merge m:1 bene_id using temp_patient, nogenerate keep(master match)
	merge m:1 bene_id using "${DATA_FINAL}BENE_Spending_`y'.dta", nogenerate keep(master match)
		
	** Create variables
	gen birthday=date(bene_birth_dt, "DMY")
	format birthday %td
	format discharge %td
	gen age=int( (discharge-birthday)/365.25)
	gen los=discharge-admit+1

	** Quartiles of claims/spending (in prior years)
	replace tot_claims=0 if tot_claims==.
	replace tot_pay=0 if tot_pay==.
	xtile quart_claims=tot_claims, nq(4)
	xtile quart_pay=tot_pay, nq(4)
	tab quart_claims, gen(claim_q)
	tab quart_pay, gen(pay_q)

	** Clean data for analysis
	drop if age<65 
	qui tab race, gen(race_)
	qui tab gender, gen(gender_)

	** race_1 denotes white, gender_1 denotes male
	global PATIENT_VARS race_1 gender_1 age claim_q* pay_q*

	** dishcarge status
	gen Discharge_Home=(dchrg_sts==1)
	gen Discharge_HHC=(dchrg_sts==6)
	gen Discharge_SNF=(dchrg_sts==3)
	gen Discharge_IP=(dchrg_sts==62)
	
	** major diagnostic categories
	gen Ortho=(inrange(clm_drg_cd,453,517))
	gen Respiratory=(inrange(clm_drg_cd,163,208))
	gen Circulatory=(inrange(clm_drg_cd,215,316))
	gen Digestive=(inrange(clm_drg_cd,326,395))
	gen Skin=(inrange(clm_drg_cd,570,607))
	gen Endocrine=(inrange(clm_drg_cd,614,645))
	gen Kidney=(inrange(clm_drg_cd,652,700))

	******************************************************************
	/* Calculate final spending variables */
	******************************************************************	
	drop if admit>=date("01OCT2015","DMY")	
	drop icd_dgns_cd6 icd_dgns_cd7 icd_dgns_cd8 icd_dgns_cd9 icd_dgns_cd10
	rename main_icd1 icd_dgns_cd6
	rename main_icd2 icd_dgns_cd7
	forvalues i=1/7 {
		gen icd9_code`i'=icd_dgns_cd`i'
		icd9 check icd9_code`i', generate(bad_code)
		replace icd9_code`i'="" if bad_code!=0
		icd9 generate cat1_`i'=icd9_code`i', range(001-140)
		icd9 generate cat2_`i'=icd9_code`i', range(140-240)
		icd9 generate cat3_`i'=icd9_code`i', range(240-280)
		icd9 generate cat4_`i'=icd9_code`i', range(280-290)
		icd9 generate cat5_`i'=icd9_code`i', range(290-320)
		icd9 generate cat6_`i'=icd9_code`i', range(320-360)
		icd9 generate cat7_`i'=icd9_code`i', range(360-390)
		icd9 generate cat8_`i'=icd9_code`i', range(390-460)
		icd9 generate cat9_`i'=icd9_code`i', range(460-520)
		icd9 generate cat10_`i'=icd9_code`i', range(520-580)
		icd9 generate cat11_`i'=icd9_code`i', range(580-630)
		icd9 generate cat12_`i'=icd9_code`i', range(630-680)
		icd9 generate cat13_`i'=icd9_code`i', range(680-710)
		icd9 generate cat14_`i'=icd9_code`i', range(710-740)
		icd9 generate cat15_`i'=icd9_code`i', range(740-760)
		icd9 generate cat16_`i'=icd9_code`i', range(760-780)
		icd9 generate cat17_`i'=icd9_code`i', range(780-800)
		icd9 generate cat18_`i'=icd9_code`i', range(800-999)
		gen icd9_group`i'=0
		forvalues g=1/18 {
			replace icd9_group`i'=`g'*cat`g'_`i' if cat`g'_`i'==1
		}
		replace icd9_group`i'=100 if icd_dgns_cd`i'==""
		drop bad_code cat1_* cat2_* cat3_* cat4_* cat5_* cat6_* cat7_* cat8_* cat9_* cat10_* cat11_* cat10_* cat11_* cat12_* cat13_* cat14_* cat15_* cat16_* cat17_* cat18_*
	}

	forvalues i=1/7 {
		gen cat_group`i'=0
		replace cat_group`i'=icd9_group`i'
	}

	** form DRG group dummies
	bys clm_drg_cd: gen drg_count=_N
	replace clm_drg_cd=10000 if drg_count<1000

	** save final data
	keep physician_npi NPINUM bene_id initial_id admit discharge ///
		admit_* drgweight ///
		episode_* carrier_* imaging_* lab_* tot_lab_* em_* snf_* hha_* ip_* op_* office_* other_* ///
		${PATIENT_VARS} cat_group1 cat_group2 cat_group3 cat_group4 cat_group5 clm_drg_cd Discharge_*
					
	save "${DATA_FINAL}PatientLevel_Spend_`y'.dta", replace
	
}


use "${DATA_FINAL}PatientLevel_Spend_2009.dta", clear
gen Year=2009
forvalues t=2010/2015 {
	append using "${DATA_FINAL}PatientLevel_Spend_`t'.dta"
	replace Year=`t' if Year==.
}

save "${DATA_FINAL}PatientLevel_Spend.dta", replace


log close	

