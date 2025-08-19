******************************************************************
**	Title:		Summary stats
**	Description:	Summary tables and figures
**	Author:		Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	5/6/24
******************************************************************

use "${DATA_FINAL}FinalEpisodesData.dta", clear

** total counts
count
count if unique_phy==1
count if unique_hosp==1
count if unique_pair==1

** counts by year
tab Year
tab Year if phy_obs==1
tab Year if hosp_obs==1
tab Year if fips_obs==1

** physician/hospital vars (Table 1 Summary Stats)
label variable episode_charge "Charges"
label variable episode_spend "Medicare Payments"
label variable ln_ep_charge "Log Charges"
label variable ln_ep_spend "Log Payments"
label variable episode_service_count "Service Count"
label variable episode_rvu "RVUs"
label variable episode_events "Events"
label variable episode_claims "Claims"
label variable mortality "Mortality"
label variable readmit "Readmission"
label variable any_sepsis "Sepsis"
label variable any_ssi "SSI"
label variable any_comp "Any Complication"
label variable PH_VI "Integrated"

forvalues t=2010/2015 {
	estpost sum ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} PH_VI if Year==`t'
	est store sum_phy_hosp_`t'
}
estpost sum ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} PH_VI
est store sum_phy_hosp_all
estpost sum ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} if PH_VI==1
est store sum_phy_hosp_vi1
estpost sum ${OUTCOMES_SPEND} ${OUTCOMES_QUAL} if PH_VI==0
est store sum_phy_hosp_vi0

esttab sum_phy_hosp_2010 sum_phy_hosp_2011 sum_phy_hosp_2012 sum_phy_hosp_2013 sum_phy_hosp_2014 sum_phy_hosp_2015 ///
	sum_phy_hosp_all sum_phy_hosp_vi0 sum_phy_hosp_vi1 using "${RESULTS_FINAL}t1_episode_sum.tex", replace ///
	stats(N, fmt(%9.0fc) labels("\midrule Observations")) ///
	mtitle("2010" "2011" "2012" "2013" "2014" "2015" "Total" "Total No VI" "Total VI") ///
	cells(mean(fmt(%9.3fc)) sd(par)) label booktabs nonum collabels(none) gaps f noobs
	
	
** physician vars (Table 2 Summary Stats)
label variable phy_episodes "Episodes"
label variable prac_size "Practice Size"
label variable avg_exper "Experience"
label variable avg_female "Female"
label variable adult_pcp "Includes PCP"
label variable multi "Multi-specialty"
label variable surg "Surgery Center"
label variable indy_prac "Independent"
label variable Physician_VI "Integrated"

forvalues t=2010/2015 {
	estpost sum phy_episodes ${PHYSICIAN_VARS} Physician_VI if phy_obs==1 & Year==`t'
	est store sum_phy_`t'
}
estpost sum phy_episodes ${PHYSICIAN_VARS} Physician_VI if phy_obs==1
est store sum_phy_all

estpost sum phy_episodes ${PHYSICIAN_VARS} if phy_obs==1 & Physician_VI==1
est store sum_phy_vi1
estpost sum phy_episodes ${PHYSICIAN_VARS} if phy_obs==1 & Physician_VI==0
est store sum_phy_vi0


esttab sum_phy_2010 sum_phy_2011 sum_phy_2012 sum_phy_2013 sum_phy_2014 sum_phy_2015 sum_phy_all sum_phy_vi0 sum_phy_vi1 using "${RESULTS_FINAL}t2_phy_sum.tex", replace ///
	stats(N, fmt(%9.0fc) labels("\midrule Observations")) ///
	mtitle("2010" "2011" "2012" "2013" "2014" "2015" "Total" "Total No VI" "Total VI") ///
	cells(mean(fmt(%9.3fc)) sd(par)) label booktabs nonum collabels(none) gaps f noobs



** hospital vars (Table 3 Summary Stats)
label variable hosp_episodes "Episodes"
label variable Labor_Phys "Physician FTEs"
label variable Labor_Residents "Resident FTEs"
label variable Labor_Nurse "Nurse FTEs"
label variable Labor_Other "Other FTEs"
label variable Beds "Bed Size (100s)"
label variable Profit "For-profit"
label variable System "System Affiliation"
label variable MajorTeaching "Major Teaching"
label variable Hospital_VI "Integrated"

forvalues t=2010/2015 {
	estpost sum hosp_episodes ${HOSP_CONTROLS} Hospital_VI if hosp_obs==1 & Year==`t'
	est store sum_hosp_`t'
}
estpost sum hosp_episodes ${HOSP_CONTROLS} Hospital_VI if hosp_obs==1
est store sum_hosp_all
estpost sum hosp_episodes ${HOSP_CONTROLS} if hosp_obs==1 & Hospital_VI==0
est store sum_hosp_vi0
estpost sum hosp_episodes ${HOSP_CONTROLS} if hosp_obs==1 & Hospital_VI==1
est store sum_hosp_vi1


esttab sum_hosp_2010 sum_hosp_2011 sum_hosp_2012 sum_hosp_2013 sum_hosp_2014 sum_hosp_2015 sum_hosp_all sum_hosp_vi0 sum_hosp_vi1 using "${RESULTS_FINAL}t3_hosp_sum.tex", replace ///
	stats(N, fmt(%9.0fc) labels("\midrule Observations")) ///
	mtitle("2010" "2011" "2012" "2013" "2014" "2015" "Total" "Total No VI" "Total VI") ///
	cells(mean(fmt(%9.3fc)) sd(par)) label booktabs nonum collabels(none) gaps f noobs


** histogram of DRGs for episodes (Figure 1)
preserve
drop if clm_drg_cd==10000 | clm_drg_cd==0
bys clm_drg_cd: gen drg_count=_N
keep if drg_count>11000
tab clm_drg_cd

gen t_count=0.001
graph bar (sum) t_count, over(clm_drg_cd) ytitle("Frequency of Top DRG Codes (1000s)") ///
	legend(off) plotregion(margin(medium)) intensity(60) blabel(bar, format(%3.0f))
graph save "${RESULTS_FINAL}f1_TopDRGs", replace
graph export "${RESULTS_FINAL}f1_TopDRGs.png", as(png) replace	
restore

** examine timing of integration by pairs
use "${DATA_FINAL}FinalEpisodesData.dta", clear
bys phy_hosp: egen min_year=min(Year)
bys phy_hosp VI: egen min_vi_year=min(Year)
replace min_vi_year=. if VI==0
bys phy_hosp: egen min_vi_year2=min(min_vi_year)
bys phy_hosp: egen ever_VI=max(VI)
bys phy_hosp Year: gen phy_hosp_episodes=_N
bys phy_hosp Year: gen phy_hosp_obs=_n
keep if phy_hosp_obs==1

count if min_year<min_vi_year & ever_VI==1
local pre_vi_pair=r(N)
count if ever_VI==1
local all_vi_pair=r(N)
local ratio=(`pre_vi_pair'/`all_vi_pair')*100
display "`pre_vi_pair' pair-years with pre-integration episodes, out of `all_vi_pair' pairs, or `ratio'%"

** operations among integrated physicians at non-integrated hospitals
count if Physician_VI==1 & PH_VI!=1
