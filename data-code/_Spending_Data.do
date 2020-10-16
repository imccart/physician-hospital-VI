set logtype text
capture log close
local logdate = string( d(`c(current_date)'), "%dCYND" )
log using "S:\IMC969\Logs\Episodes\Spending_`logdate'.log", replace

******************************************************************
**	Title:			Spending_Data
**	Description:	Form spending and discharge outcomes for each episode
**	Author:			Ian McCarthy
**	Date Created:	11/3/17
**	Date Updated:	8/4/2020
******************************************************************

******************************************************************
** Preliminaries
set more off
cd "S:\IMC969\Temp and ado files\"
global DATA_SAS "S:\IMC969\SAS Data v2\"
global DATA_DARTMOUTH "S:\IMC969\Stata Uploaded Data\"
global DATA_AHA "S:\IMC969\Stata Uploaded Data\AHA Data\"
global DATA_ACS "S:\IMC969\Stata Uploaded Data\ACS Data\"
global DATA_COMPARE "S:\IMC969\Stata Uploaded Data\Hospital Compare\"
global DATA_HCRIS "S:\IMC969\Stata Uploaded Data\Hospital Cost Reports\"
global DATA_IPPS "S:\IMC969\Stata Uploaded Data\Inpatient PPS\"
global DATA_FINAL "S:\IMC969\Final Data\Physician Agency Episodes\"
global CODE_FILES "S:\IMC969\Stata Code Files\Physician Agency Episodes\"
global RESULTS_FINAL "S:\IMC969\Results\Physician Agency Episodes\"


******************************************************************
** Calculate averages and totals by patient

forvalues y=2007/2015 {
  insheet using "${DATA_SAS}TOTALBENE_`y'.tab", tab clear
  gen Year=`y'
  save temp_bene_`y', replace
}
use temp_bene_2007, clear
forvalues y=2008/2015 {
  append using temp_bene_`y'
}

forvalues y=2008/2015 {
  preserve
  keep if Year<`y'
  collapse (mean) avg_claims=tot_claims avg_pay=tot_payment avg_charge=tot_charge ///
	(sum) tot_claims tot_pay=tot_payment tot_charge, by(bene_id)
  gen Year=`y'
  sort bene_id
  save "${DATA_FINAL}BENE_Spending_`y'.dta", replace
  restore
}


** identify patients in the carrier file
forvalues y=2008/2015 {
	insheet using "${DATA_SAS}CARRIER_`y'.tab", tab clear
	keep bene_id
	save carrier_patient_`y', replace
}
use carrier_patient_2008, clear
forvalues y=2009/2015 {
	append using carrier_patient_`y'
}
bys bene_id: gen obs=_n
keep if obs==1
drop obs
save carrier_patients, replace


forvalues y=2008/2015 {
	
	******************************************************************
	/* Get set of hospitals and physicians from final dataset */
	******************************************************************
	use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
	keep if Year==`y'
	keep NPINUM physician_npi CCR
	bys NPINUM physician_npi: gen obs=_n
	keep if obs==1
	drop obs
	save temp_phyhosp_set, replace


	******************************************************************
	/* Collect patient variables and individual outcome files */
	******************************************************************
	** Import patient data
	insheet using "${DATA_SAS}Patient_Data_`y'.tab", tab clear
	save temp_patient, replace

	** Import inpatient claims
	insheet using "${DATA_SAS}INPATIENTSTAYS_`y'.tab", tab clear
	drop prvdr_num
	rename org_npi_num NPINUM
	rename op_physn_npi physician_npi
	gen discharge=date(nch_bene_dschrg_dt, "DMY")
	replace discharge=date(clm_thru_dt, "DMY") if discharge==.
	gen admit=date(clm_from_dt,"DMY")
	gen admit_month=month(admit)
	save temp_ip_dat, replace
	
	keep bene_id admit clm_pmt_amt
	save ip_dat_small, replace

	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}INPATIENTSTAYS_`y_p1'.tab", tab clear
		drop prvdr_num
		rename org_npi_num NPINUM
		rename op_physn_npi physician_npi
		gen discharge=date(nch_bene_dschrg_dt, "DMY")
		replace discharge=date(clm_thru_dt, "DMY") if discharge==.
		gen admit=date(clm_from_dt,"DMY")
		gen admit_month=month(admit)
		drop if admit_month>3
		save temp_ip_dat_next, replace
		
		keep bene_id admit clm_pmt_amt
		save ip_dat_small_next, replace
	}
	
	
	** Import outpatient claims
	insheet using "${DATA_SAS}OPFINAL_`y'.tab", tab clear
	gen claim_date_op=date(clm_from_dt,"DMY")
	rename clm_pmt_amt pay_op
	rename clm_tot_chrg_amt charge_op
	rename clm_id claim_op
	keep bene_id claim_date_op pay_op charge_op claim_op
	save temp_op_dat, replace

	local y_l1=`y'-1
	insheet using "${DATA_SAS}OPFINAL_`y_l1'.tab", tab clear
	gen claim_date_op=date(clm_from_dt,"DMY")
	rename clm_pmt_amt pay_op
	rename clm_tot_chrg_amt charge_op
	rename clm_id claim_op
	gen claim_month=month(claim_date)
	drop if claim_month<12
	keep bene_id claim_date_op pay_op charge_op claim_op
	save temp_op_dat_prior, replace
	
	use temp_op_dat, clear
	append using temp_op_dat_prior
	save temp_op_dat, replace
	
	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}OPFINAL_`y_p1'.tab", tab clear
		gen claim_date_op=date(clm_from_dt,"DMY")
		rename clm_pmt_amt pay_op
		rename clm_tot_chrg_amt charge_op
		rename clm_id claim_op
		gen claim_month=month(claim_date)
		drop if claim_month>3
		keep bene_id claim_date_op pay_op charge_op claim_op
		save temp_op_dat_next, replace
		
		use temp_op_dat, clear
		append using temp_op_dat_next
		save temp_op_dat, replace
	}
	
		
	** Import carrier claims data
	insheet using "${DATA_SAS}CARRIER_`y'.tab", tab clear
	gen claim_date_carrier=date(claim_date, "DMY")
	replace imaging_claims=0 if imaging_claims==.
	replace em_claims=0 if em_claims==.
	replace lab_claims=0 if lab_claims==.
	gen other_claims=carrier_claims-imaging_claims-em_claims-lab_claims
	keep bene_id claim_date_carrier carrier_claims carrier_charge carrier_pay imaging_claims em_claims lab_claims other_claims
	save temp_carrier_dat, replace
	
	local y_l1=`y'-1
	insheet using "${DATA_SAS}CARRIER_`y_l1'.tab", tab clear
	gen claim_date_carrier=date(claim_date, "DMY")
	gen claim_month=month(claim_date_carrier)
	drop if claim_month<12	
	replace imaging_claims=0 if imaging_claims==.
	replace em_claims=0 if em_claims==.
	replace lab_claims=0 if lab_claims==.
	gen other_claims=carrier_claims-imaging_claims-em_claims-lab_claims	
	keep bene_id claim_date_carrier carrier_claims carrier_charge carrier_pay imaging_claims em_claims lab_claims other_claims
	save temp_carrier_dat_prior, replace
		
	use temp_carrier_dat, clear
	append using temp_carrier_dat_prior
	save temp_carrier_dat, replace
		
		
	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}CARRIER_`y_p1'.tab", tab clear
		gen claim_date_carrier=date(claim_date, "DMY")
		gen claim_month=month(claim_date_carrier)
		drop if claim_month>3
		replace imaging_claims=0 if imaging_claims==.
		replace em_claims=0 if em_claims==.
		replace lab_claims=0 if lab_claims==.
		gen other_claims=carrier_claims-imaging_claims-em_claims-lab_claims
		
		keep bene_id claim_date_carrier carrier_claims carrier_charge carrier_pay imaging_claims em_claims lab_claims other_claims
		save temp_carrier_dat_next, replace
		
		use temp_carrier_dat, clear
		append using temp_carrier_dat_next
		save temp_carrier_dat, replace
	}
	
	
	** Import Full Inpatient claims data
	insheet using "${DATA_SAS}OUTCOMES_`y'.tab", tab clear
	gen claim_date_ip=date(clm_from_dt, "DMY")
	rename clm_id claim_ipfull
	rename clm_tot_chrg_amt charge_ipfull
	rename clm_pmt_amt pay_ipfull
	keep bene_id claim_date_ip claim_ipfull charge_ipfull pay_ipfull
	save temp_ipfull_dat, replace
	
	local y_l1=`y'-1
	insheet using "${DATA_SAS}OUTCOMES_`y_l1'.tab", tab clear
	gen claim_date_ip=date(clm_from_dt, "DMY")
	rename clm_id claim_ipfull
	rename clm_tot_chrg_amt charge_ipfull
	rename clm_pmt_amt pay_ipfull
	gen claim_month=month(claim_date_ip)
	drop if claim_month<12	
	keep bene_id claim_date_ip claim_ipfull charge_ipfull pay_ipfull
	save temp_ipfull_dat_prior, replace
		
	use temp_ipfull_dat, clear
	append using temp_ipfull_dat_prior
	save temp_ipfull_dat, replace
	
	
	if `y'<2015 {
		local y_p1=`y'+1
		insheet using "${DATA_SAS}OUTCOMES_`y_p1'.tab", tab clear
		gen claim_date_ip=date(clm_from_dt, "DMY")
		rename clm_id claim_ipfull
		rename clm_tot_chrg_amt charge_ipfull
		rename clm_pmt_amt pay_ipfull
		gen claim_month=month(claim_date_ip)
		drop if claim_month>3		
		keep bene_id claim_date_ip claim_ipfull charge_ipfull pay_ipfull
		save temp_ipfull_dat_next, replace
		
		use temp_ipfull_dat, clear
		append using temp_ipfull_dat_next
		save temp_ipfull_dat, replace
	}
	
	
	******************************************************************
	/* Merge claims files */
	******************************************************************
	** Identify episodes
	use ip_dat_small, clear
	append using ip_dat_small_next
	
	bys bene_id admit: egen max_pay=max(clm_pmt_amt)
	bys bene_id admit: gen obs_count=_N
	drop if clm_pmt_amt!=max_pay & obs_count>1
	bys bene_id admit: gen obs_count2=_n
	keep if obs_count2==1
	drop obs_count obs_count2 max_pay
	
	tsset bene_id admit
	panelthin, min(90) gen(OK)
	keep if OK
	drop OK
	save temp_episode_dat, replace
	
	use temp_ip_dat, clear	
	bys bene_id admit: egen max_pay=max(clm_pmt_amt)
	bys bene_id admit: gen obs_count=_N
	drop if clm_pmt_amt!=max_pay & obs_count>1
	bys bene_id admit: gen obs_count2=_n
	keep if obs_count2==1
	drop obs_count obs_count2 max_pay
	merge 1:1 bene_id admit using temp_episode_dat, nogenerate keep(match)
	save temp_base_dat, replace
	
	
	** Outpatient claims
	use temp_base_dat, clear
	keep bene_id admit discharge NPINUM physician_npi clm_id admit_month
	
	merge m:m bene_id using temp_op_dat, nogenerate keep(match)
	keep if claim_date_op<=(discharge+90) & claim_date_op>(admit-30)
	
	foreach x of varlist claim_op charge_op pay_op {
		gen pre_`x'=0
		replace pre_`x'=`x' if claim_date_op<admit & claim_date_op>=(admit-30)

		gen admit_`x'=0
		replace admit_`x'=`x' if claim_date_op<=discharge & claim_date_op>=admit

		gen post_`x'=0
		replace post_`x'=`x' if claim_date_op<=(discharge+90) & claim_date_op>discharge
	}

	
	collapse (count) pre_op_claims=pre_claim_op admit_op_claims=admit_claim_op post_op_claims=post_claim_op op_claims=claim_op ///
		(sum) pre_charge_op admit_charge_op post_charge_op charge_op pre_pay_op admit_pay_op post_pay_op pay_op, by(bene_id NPINUM clm_id)
	save temp_op_total, replace
	
	** Carrier claims	
	use temp_base_dat, clear
	keep bene_id admit discharge NPINUM physician_npi clm_id admit_month
	
	merge m:m bene_id using temp_carrier_dat, nogenerate keep(match)
	keep if claim_date_carrier<=(discharge+90) & claim_date_carrier>=(admit-30)
	
	foreach x of varlist carrier_claims carrier_charge carrier_pay imaging_claims em_claims lab_claims other_claims {
		gen pre_`x'=0
		replace pre_`x'=`x' if claim_date_carrier<admit & claim_date_carrier>=(admit-30)

		gen admit_`x'=0
		replace admit_`x'=`x' if claim_date_carrier<=discharge & claim_date_carrier>=admit

		gen post_`x'=0
		replace post_`x'=`x' if claim_date_carrier<=(discharge+90) & claim_date_carrier>discharge
	}
	
	collapse (sum) pre_carrier_claims pre_carrier_charge pre_carrier_pay admit_carrier_claims admit_carrier_charge admit_carrier_pay ///
		post_carrier_claims post_carrier_charge post_carrier_pay ///
		pre_imaging_claims pre_em_claims pre_lab_claims pre_other_claims ///
		post_imaging_claims post_em_claims post_lab_claims post_other_claims ///
		carrier_claims carrier_charge carrier_pay imaging_claims em_claims lab_claims other_claims, by(bene_id NPINUM clm_id)
	save temp_carrier_total, replace

	** Other inpatient claims
	use temp_base_dat, clear
	keep bene_id admit discharge NPINUM physician_npi clm_id admit_month

	merge m:m bene_id using temp_ipfull_dat, nogenerate keep(match)
	keep if claim_date_ip<=(discharge+90) & claim_date_ip>discharge
	collapse (count) ip_claims=claim_ipfull (sum) charge_ipfull pay_ipfull, by(bene_id NPINUM clm_id)
	save temp_ip_total, replace

	
	** Merge datasets
	use temp_base_dat, clear
	
	merge m:1 NPINUM physician_npi using temp_phyhosp_set, nogenerate keep(match)
	merge m:1 bene_id using temp_patient, nogenerate keep(master match)
	merge m:1 bene_id using "${DATA_FINAL}BENE_Spending_`y'.dta", nogenerate keep(master match)
	merge 1:1 bene_id NPINUM clm_id using temp_op_total, generate(OP_Match) keep(master match)	
	merge 1:1 bene_id NPINUM clm_id using temp_ip_total, generate(IP_Match) keep(master match)	
	merge 1:1 bene_id NPINUM clm_id using temp_carrier_total, generate(Carrier_Match) keep(master match)	
	merge m:1 bene_id using carrier_patients, generate(Carrier_Any) keep(master match)
	
	foreach x of varlist op_claims charge_op pay_op pre_op_claims pre_charge_op pre_pay_op admit_op_claims admit_charge_op admit_pay_op ///
		post_op_claims post_charge_op post_pay_op charge_ipfull pay_ipfull ip_claims {
	
		replace `x'=0 if `x'==.
	}
	foreach x of varlist pre_carrier_claims pre_carrier_charge pre_carrier_pay admit_carrier_claims admit_carrier_charge admit_carrier_pay ///
		post_carrier_claims post_carrier_charge post_carrier_pay ///
		pre_imaging_claims pre_lab_claims pre_em_claims pre_other_claims ///
		post_imaging_claims post_lab_claims post_em_claims post_other_claims ///
		carrier_claims carrier_charge carrier_pay imaging_claims em_claims lab_claims other_claims {
	
		replace `x'=0 if `x'==. & Carrier_Any==3
	}
		
		
	** Create variables
	gen birthday=date(bene_birth_dt, "DMY")
	format birthday %td
	format discharge %td
	gen age=int( (discharge-birthday)/365.25)
	gen los=discharge-admit+1

	** Quartiles of claims/spending (in prior years)
	replace tot_pay=0 if tot_pay==.
	replace tot_claims=0 if tot_claims==.
	xtile quart_claims=tot_claims, nq(4)
	xtile quart_pay=tot_pay, nq(4)
	tab quart_claims, gen(claim_q)
	tab quart_pay, gen(pay_q)

	** Clean data for analysis
	drop if age<65 
	qui tab race, gen(race_)
	qui tab gender, gen(gender_)

	** race_1 denotes white, gender_1 denotes male
	global PATIENT_VARS race_1 gender_1 age claim_q2 claim_q3 claim_q4 pay_q2 pay_q3 pay_q4

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
	keep if Carrier_Any==3
	gen episode_charge=clm_tot_chrg_amt + charge_op + charge_ipfull + carrier_charge
	gen episode_pay=clm_pmt_amt + pay_op + pay_ipfull + carrier_pay
	gen episode_claims=ip_claims + op_claims + carrier_claims

	** identify outliers for each variable
	foreach x of varlist clm_pmt_amt clm_tot_chrg_amt episode_charge episode_pay {
		replace `x'=. if `x'<=0
		_pctile `x', percentiles(1 99)
		replace `x'=. if `x'<=r(r1) | `x'>=r(r2)
	}
	replace los=. if los<=0
	_pctile los, percentiles(99)
	replace los=. if los>=r(r1)

	egen ph_group=group(physician_npi NPINUM)
	egen npi_group=group(NPINUM)
	egen phy_group=group(physician_npi)

	forvalues i=1/5 {
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

	forvalues i=1/5 {
		gen cat_group`i'=0
		replace cat_group`i'=icd9_group`i'
	}

	** form DRG group dummies
	bys clm_drg_cd: gen drg_count=_N
	replace clm_drg_cd=10000 if drg_count<1000

	** save final data
	keep physician_npi NPINUM bene_id clm_id admit ///
		clm_tot_chrg_amt clm_pmt_amt charge_op pay_op charge_ipfull pay_ipfull carrier_charge carrier_pay ///
		drgweight los episode_charge episode_pay episode_claims ip_claims op_claims carrier_claims ///
		pre_op_claims pre_charge_op pre_pay_op admit_op_claims admit_charge_op admit_pay_op ///
		post_op_claims post_charge_op post_pay_op pre_carrier_claims pre_carrier_charge pre_carrier_pay ///
		admit_carrier_claims admit_carrier_charge admit_carrier_pay ///
		post_carrier_claims post_carrier_charge post_carrier_pay ///
		pre_imaging_claims pre_em_claims pre_lab_claims pre_other_claims ///
		post_imaging_claims post_em_claims post_lab_claims post_other_claims ///
		imaging_claims em_claims lab_claims other_claims ///
		${PATIENT_VARS} cat_group1 cat_group2 cat_group3 cat_group4 cat_group5 clm_drg_cd Discharge_*
	save "${DATA_FINAL}PatientLevel_Carrier_`y'.dta", replace
	
}


use "${DATA_FINAL}PatientLevel_Carrier_2008.dta", clear
gen Year=2008
forvalues t=2009/2015 {
	append using "${DATA_FINAL}PatientLevel_Carrier_`t'.dta"
	replace Year=`t' if Year==.
}
save "${DATA_FINAL}PatientLevel_Spend.dta", replace


log close	

