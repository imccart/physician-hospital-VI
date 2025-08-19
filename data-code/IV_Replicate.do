******************************************************************
**	Title:		Replication
**	Description:	Replicate Dranove and Ody regression results
**	Author:		Ian McCarthy
**	Date Created:	4/26/18
**	Date Updated:	3/22/24
******************************************************************

******************************************************************
/* Collect physician quantity data per hcpcs in 2008 */

** from carrier file
insheet using "${DATA_SAS}HCPCS_2008.tab", tab clear
rename hcpcs_cd hcpcs
rename physician_id physician_npi
destring physician_npi, replace force
drop if physician_npi==.
drop year
save temp_office_hcpcs, replace

** from outpatient claims
insheet using "${DATA_SAS}HCPCS_OP_PHYSICIAN_2008.tab", tab clear
rename value hcpcs
rename count op_ph_claims
bys physician_npi hcpcs: egen op_claims=sum(op_ph_claims)
bys physician_npi hcpcs: gen obs=_n
keep if obs==1

keep physician_npi hcpcs op_claims
save temp_op_hcpcs, replace

** combine to find substitutable codes
use temp_office_hcpcs, clear
merge 1:1 physician_npi hcpcs using temp_op_hcpcs, keep(master match) nogenerate

bys hcpcs: egen tot_carrier=total(carrier_claims)
bys hcpcs: egen tot_op=total(op_claims)

gen tot_hcpcs = tot_carrier + tot_op
gen carrier_perc = tot_carrier/tot_hcpcs
drop if carrier_perc>0.70
gen carrier_share=carrier_claims/tot_carrier
gen op_share=op_claims/tot_op

keep physician_npi hcpcs carrier_claims op_claims carrier_share op_share
rename carrier_claims office_claims
rename carrier_share office_share
save temp_quant_data_2008, replace

******************************************************************
** Raw physician differential payment following Dranove and Ody

forvalues t=2008/2015 {
	insheet using "${DATA_UPLOAD}PFS_update_data.txt", tab clear

	foreach x of varlist price_nonfac_trans price_nonfac_orig_2007 price_fac_orig_2007 price_nonfac_orig_2010 price_fac_orig_2010 priceff_opps ///
		dprice_fac_2007 dprice_nonfac_2007 dprice_fac_2010 dprice_nonfac_2010 dpct_price_rel_2007 dpct_price_rel_2010 dprice_rel_2007 dprice_rel_2010 {
		replace `x'="" if `x'=="NA"
		destring `x', replace
	}

	gen dp_office_2007 = ((year-2006)/4)*dprice_nonfac_2007 if year<2010
	replace dp_office_2007 = dprice_nonfac_2007 if year>=2010

	gen dp_facility_2007 = ((year-2006)/4)*dprice_fac_2007 if year<2010
	replace dp_facility_2007 = dprice_fac_2007 if year>=2010

	gen dp_rel_2007 = ((year-2006)/4)*dprice_rel_2007 if year<2010
	replace dp_rel_2007 = dprice_rel_2007 if year>=2010

	gen dp_office_2010 = 0 if year<2010
	replace dp_office_2010 = ((year-2009)/4)*dprice_nonfac_2010 if year>=2010
	replace dp_office_2010 = dprice_nonfac_2010 if year>2013

	gen dp_facility_2010 = 0 if year<2010
	replace dp_facility_2010 = ((year-2009)/4)*dprice_fac_2010 if year>=2010
	replace dp_facility_2010 = dprice_fac_2010 if year>2013

	gen dp_rel_2010 = 0 if year<2010
	replace dp_rel_2010 = ((year-2009)/4)*dprice_rel_2010 if year>=2010
	replace dp_rel_2010 = dprice_rel_2010 if year>2013

	if `t'>2013 {
		keep if year==2013
	} 
	else if `t'<=2013 {
		keep if year==`t'
	}
	drop year
	save temp_pfs_data, replace


	** merge price differential and quantity data
	use temp_quant_data_2008, clear
	merge m:1 hcpcs using temp_pfs_data, keep(match) nogenerate

	replace op_share=0 if op_share==.
	replace office_share=0 if office_share==.
	replace office_claims=0 if office_claims==.
	replace op_claims=0 if op_claims==.

	gen normrev_denom=office_claims*price_nonfac_orig_2007
	bys physician_npi: egen tot_denom=sum(normrev_denom)
	bys physician_npi: egen tot_office=sum(office_claims)

	foreach y in 2007 2010 {
		foreach loc in facility office rel {
			replace dp_`loc'_`y'=0 if dp_`loc'_`y'<0
			gen rev_change_`loc'_`y' = dp_`loc'_`y'*office_claims
			gen normrev_change_`loc'_`y' = dp_`loc'_`y'*office_claims*price_nonfac_orig_2007
			
			bys physician_npi: egen totchange_`loc'_`y'=sum(normrev_change_`loc'_`y')
			replace totchange_`loc'_`y'=totchange_`loc'_`y'/tot_denom
		}
	}


	bys physician_npi: gen obs=_n
	keep if obs==1
	keep physician_npi normrev_change_* rev_change_* totchange_* tot_office

	save temp_rev_change, replace
	save "${DATA_FINAL}PFS_Revenue_`t'.dta", replace
}


use "${DATA_FINAL}PFS_Revenue_2008.dta", clear
gen Year=2008
forvalues t=2009/2015 {
	append using "${DATA_FINAL}PFS_Revenue_`t'.dta"
	replace Year=`t' if Year==.
}
save "${DATA_FINAL}PFS_Revenue_Replicate.dta", replace


******************************************************************
** Replication of Dranove and Ody regression

use "${DATA_FINAL}PhysicianHospital_Data.dta", clear
drop VI
replace PH_VI=0 if PH_VI==.
bys physician_npi Year: egen VI=max(PH_VI)
bys physician_npi Year: gen u_obs=_n
keep if u_obs==1

keep SKA_Practice_ID physician_npi indy_prac avg_exper avg_female multi surg Year VI tin1 phy_zip PH_VI
save temp_phy_vi, replace


** descriptive graph
use "${DATA_FINAL}PFS_Revenue_Replicate.dta", clear
merge 1:1 physician_npi Year using temp_phy_vi, keep(match) nogenerate
drop if tin1==. | phy_zip==.
bys tin1 : egen ever_vi=max(VI)
bys tin1 phy_zip Year: egen practice_revchange=total(totchange_rel_2010)
bys tin1 phy_zip Year: egen practice_office=total(tot_office)
bys tin1 phy_zip Year: gen obs=_n
keep if obs==1
collapse (mean) revchange=practice_revchange [aweight=tot_office], by(Year ever_vi)
graph twoway (connected revchange Year if ever_vi==1, color(black)) (connected revchange Year if ever_vi==0, color(black) lpattern(dash)), ///
	ytitle("Mean Relative Revenue Increase") xtitle("Year") legend(off) xlabel(2009(1)2015) ylabel(0(25)150) ///
	text(50 2012.5 "Non-Integrated", place(e)) text(130 2013 "Integrated", place(e))
graph save "${RESULTS_FINAL}f3_raw_iv_graph", replace
graph export "${RESULTS_FINAL}f3_raw_iv_graph.png", as(png) replace		


** assessment of first-stage
use "${DATA_FINAL}PFS_Revenue_Replicate.dta", clear
merge 1:1 physician_npi Year using temp_phy_vi, keep(match) nogenerate

gen normchange=0
gen change=0
forvalues t=2010/2015 {
	gen change2007_`t'=rev_change_rel_2007*(Year==`t')
	gen change2010_`t'=rev_change_rel_2010*(Year==`t')
	gen normchange2007_`t'=totchange_rel_2007*(Year==`t')
	gen normchange2010_`t'=totchange_rel_2010*(Year==`t')
	gen facility_change2010_`t'=rev_change_facility_2010*(Year==`t')
	gen office_change2010_`t'=rev_change_office_2010*(Year==`t')	
	gen facility_change2007_`t'=rev_change_facility_2007*(Year==`t')
	gen office_change2007_`t'=rev_change_office_2007*(Year==`t')
	replace normchange=normchange2010_`t' if Year==`t' & Year>=2010
	replace change=change2010_`t' if Year==`t' & Year>=2010
}
reg VI normchange2007_* normchange2010_* i.Year, cluster(physician_npi)
predict pred_ever_vi
est store ev_coeff

coefplot ev_coeff, keep(normchange2010_2008 normchange2010_2009 normchange2010_2010 normchange2010_2011 normchange2010_2012 normchange2010_2013 normchange2010_2014 normchange2010_2015) vert ytitle("Percentage Point Increase in" "Probability of Integration") xtitle("Year") ///
	coeflabels(normchange2010_2008="2008" normchange2010_2009="2009" normchange2010_2010="2010" normchange2010_2011="2011" normchange2010_2012="2012" normchange2010_2013="2013" normchange2010_2014="2014" normchange2010_2015="2015") yline(0, lwidth(vthin) lcolor(gray)) rescale(1550) ylabel(-2(1)2)
graph save "${RESULTS_FINAL}f4_iv_estimates", replace
graph export "${RESULTS_FINAL}f4_iv_estimates.png", as(png) replace	

reg VI normchange2007_* normchange2010_* i.Year, absorb(physician_npi) cluster(physician_npi)
est store ev_coeff

coefplot ev_coeff, keep(normchange2010_2008 normchange2010_2009 normchange2010_2010 normchange2010_2011 normchange2010_2012 normchange2010_2013 normchange2010_2014 normchange2010_2015) vert ytitle("Percentage Point Increase in" "Probability of Integration") xtitle("Year") ///
	coeflabels(normchange2010_2008="2008" normchange2010_2009="2009" normchange2010_2010="2010" normchange2010_2011="2011" normchange2010_2012="2012" normchange2010_2013="2013" normchange2010_2014="2014" normchange2010_2015="2015") yline(0, lwidth(vthin) lcolor(gray)) rescale(1550) ylabel(-2(1)2)
graph save "${RESULTS_FINAL}f4_iv_estimates_fe", replace
graph export "${RESULTS_FINAL}f4_iv_estimates_fe.png", as(png) replace	


keep physician_npi pred_ever_vi Year
sort physician_npi
save "${DATA_FINAL}Predicted_EverVI.dta", replace


