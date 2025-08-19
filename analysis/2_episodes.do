******************************************************************
**	Title:		Episodes
**	Description:	Estimate effects by episode
**	Author:		Ian McCarthy
**	Date Created:	11/30/17
**	Date Updated:	6/20/24
******************************************************************

********************************************
** FE estimates for spending
use "${DATA_FINAL}FinalEpisodesData.dta", clear
est clear	
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	qui reghdfe `x' PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui reghdfe `x' PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local county "X"
	estadd local patient "X"
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local hosp "X"
	estadd local county "X"
	estadd local patient "X"
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_spend4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local hosp "X"
	estadd local county "X"
	estadd local patient "X"
	estadd local quality "X"
	
}

** Display Results
label variable PH_VI "Integrated"
label variable hosp_episodes "Episodes"
label variable Labor_Nurse "Nurse FTEs"
label variable Labor_Other "Other FTEs"
label variable Beds "Bed Size (100s)"
label variable Profit "For-profit"
label variable System "System Affiliation"
label variable MajorTeaching "Major Teaching"
label variable Hospital_VI "Any Integration"

esttab fe_spend1_7 fe_spend2_7 fe_spend3_7 fe_spend4_7 using "${RESULTS_FINAL}app_charge_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
		
		
esttab fe_spend1_8 fe_spend2_8 fe_spend3_8 fe_spend4_8 using "${RESULTS_FINAL}app_spend_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab fe_spend1_9 fe_spend2_9 fe_spend3_9 fe_spend4_9 using "${RESULTS_FINAL}app_events_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
		
esttab fe_spend1_10 fe_spend2_10 fe_spend3_10 fe_spend4_10 using "${RESULTS_FINAL}app_service_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

		
esttab fe_spend1_11 fe_spend2_11 fe_spend3_11 fe_spend4_11 using "${RESULTS_FINAL}app_rvu_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
		

esttab fe_spend1_12 fe_spend2_12 fe_spend3_12 fe_spend4_12 using "${RESULTS_FINAL}app_claims_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
		
		
********************************************
** Event Study for PH VI
use "${DATA_FINAL}FinalEpisodesData.dta", clear
gen low=.
replace low=Year if PH_VI==1
bys physician_npi NPINUM: egen first=min(low)
bys physician_npi NPINUM: egen ever_vi=max(PH_VI)
bys physician_npi NPINUM: egen count_vi=total(PH_VI)
bys physician_npi NPINUM: gen count_obs=_N
gen always_vi=(count_obs==count_vi)
drop low
gen time=(Year-first)+1
replace time=0 if ever_vi==0
tab time, gen(ev_full)
gen never_vi=(ever_vi==0)
save temp_event_data, replace

/*
** Traditional twfe event study
reghdfe ln_ep_spend ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff1
coefplot ev_coeff1, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Log Episode Payments") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventPay_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventPay_TWFE.png", as(png) replace	


reghdfe ln_ep_charge ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff2
coefplot ev_coeff2, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Log Episode Charges") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventCharge_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventCharge_TWFE.png", as(png) replace	


reghdfe ln_ep_service ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff3
coefplot ev_coeff3, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Log Episode Service Count") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventService_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventService_TWFE.png", as(png) replace	


reghdfe ln_ep_rvu ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ///
	i.month if always_vi==0, ///
	absorb($ABSORB_VARS) cluster(physician_npi)
est store ev_coeff3
coefplot ev_coeff3, keep(ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 ev_full11 ) vert ytitle("Log Episode RVUs") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4" ev_full11="+5") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventRVU_TWFE", replace
graph export "${RESULTS_FINAL}f2_EventRVU_TWFE.png", as(png) replace	

	
** Sun and Abraham
use temp_event_data, clear
replace ev_full10=1 if ev_full11==1

eventstudyinteract ln_ep_spend ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa1

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Payments") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventPay_SA", replace
graph export "${RESULTS_FINAL}f2_EventPay_SA.png", as(png) replace	


eventstudyinteract ln_ep_charge ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa2

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Charges") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventCharge_SA", replace
graph export "${RESULTS_FINAL}f2_EventCharge_SA.png", as(png) replace	


eventstudyinteract ln_ep_service ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa3

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode Service Count") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventService_SA", replace
graph export "${RESULTS_FINAL}f2_EventService_SA.png", as(png) replace	


eventstudyinteract ln_ep_rvu ev_full1 ev_full2 ev_full3 ev_full4 ev_full6 ev_full7 ev_full8 ev_full9 ev_full10 if always_vi==0, ///
	cohort(first) control_cohort(never_vi) absorb($ABSORB_VARS) vce(cluster physician_npi)
est store ev_sa3

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix list C
coefplot matrix(C[1]), se(C[2]) vert ytitle("Log Episode RVUs") xtitle("Period") xline(4.5) ///
	coeflabels(ev_full1="-4" ev_full2="-3" ev_full3="-2" ev_full4="-1" ev_full6="0" ev_full7="+1" ev_full8="+2" ev_full9="+3" ev_full10="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventRVU_SA", replace
graph export "${RESULTS_FINAL}f2_EventRVU_SA.png", as(png) replace	
*/
	
** Callaway and Sant'Anna
use temp_event_data, clear
gen cs_time=first
replace cs_time=0 if ever_vi==0

csdid2 ln_ep_spend, time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
estat event, window(-5 -4)
matrix C_pre=r(b)
mata st_matrix("A_pre",diagonal(sqrt(st_matrix("r(V)"))))
matrix A_pre=A_pre'

estat event
matrix C = r(b)
mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
matrix A=A'

matrix C2=(C_pre[1,1], C[1,5..6], 0,C[1,7..11])
matrix A2=(A_pre[1,1], A[1,5..6],0,A[1,7..11])
coefplot matrix(C2), se(A2) vert ytitle("Log Episode Spending") xtitle("Period") ///
	coeflabels(c1="-4+" tm3="-3" tm2="-2" c4="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventPay_CSDID", replace
graph export "${RESULTS_FINAL}f2_EventPay_CSDID.png", as(png) replace


csdid2 ln_ep_charge, time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
estat event, window(-5 -4)
matrix C_pre=r(b)
mata st_matrix("A_pre",diagonal(sqrt(st_matrix("r(V)"))))
matrix A_pre=A_pre'

estat event
matrix C = r(b)
mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
matrix A=A'

matrix C2=(C_pre[1,1], C[1,5..6], 0,C[1,7..11])
matrix A2=(A_pre[1,1], A[1,5..6],0,A[1,7..11])
coefplot matrix(C2), se(A2) vert ytitle("Log Episode Charges") xtitle("Period") ///
	coeflabels(c1="-4+" tm3="-3" tm2="-2" c4="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventCharge_CSDID", replace
graph export "${RESULTS_FINAL}f2_EventCharge_CSDID.png", as(png) replace



csdid2 ln_ep_service, time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
estat event, window(-5 -4)
matrix C_pre=r(b)
mata st_matrix("A_pre",diagonal(sqrt(st_matrix("r(V)"))))
matrix A_pre=A_pre'

estat event
matrix C = r(b)
mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
matrix A=A'

matrix C2=(C_pre[1,1], C[1,5..6], 0,C[1,7..11])
matrix A2=(A_pre[1,1], A[1,5..6],0,A[1,7..11])
coefplot matrix(C2), se(A2) vert ytitle("Log Episode Service Count") xtitle("Period") ///
	coeflabels(c1="-4+" tm3="-3" tm2="-2" c4="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventService_CSDID", replace
graph export "${RESULTS_FINAL}f2_EventService_CSDID.png", as(png) replace


csdid2 ln_ep_rvu, time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
estat event, window(-5 -4)
matrix C_pre=r(b)
mata st_matrix("A_pre",diagonal(sqrt(st_matrix("r(V)"))))
matrix A_pre=A_pre'

estat event
matrix C = r(b)
mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
matrix A=A'

matrix C2=(C_pre[1,1], C[1,5..6], 0,C[1,7..11])
matrix A2=(A_pre[1,1], A[1,5..6],0,A[1,7..11])
coefplot matrix(C2), se(A2) vert ytitle("Log Episode RVUs") xtitle("Period") ///
	coeflabels(c1="-4+" tm3="-3" tm2="-2" c4="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventRVU_CSDID", replace
graph export "${RESULTS_FINAL}f2_EventRVU_CSDID.png", as(png) replace


csdid2 ln_ep_events, time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
estat event, window(-5 -4)
matrix C_pre=r(b)
mata st_matrix("A_pre",diagonal(sqrt(st_matrix("r(V)"))))
matrix A_pre=A_pre'

estat event
matrix C = r(b)
mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
matrix A=A'

matrix C2=(C_pre[1,1], C[1,5..6], 0,C[1,7..11])
matrix A2=(A_pre[1,1], A[1,5..6],0,A[1,7..11])
coefplot matrix(C2), se(A2) vert ytitle("Log Episode Events") xtitle("Period") ///
	coeflabels(c1="-4+" tm3="-3" tm2="-2" c4="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventEvents_CSDID", replace
graph export "${RESULTS_FINAL}f2_EventEvents_CSDID.png", as(png) replace


csdid2 ln_ep_claims, time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
estat event, window(-5 -4)
matrix C_pre=r(b)
mata st_matrix("A_pre",diagonal(sqrt(st_matrix("r(V)"))))
matrix A_pre=A_pre'

estat event
matrix C = r(b)
mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
matrix A=A'

matrix C2=(C_pre[1,1], C[1,5..6], 0,C[1,7..11])
matrix A2=(A_pre[1,1], A[1,5..6],0,A[1,7..11])
coefplot matrix(C2), se(A2) vert ytitle("Log Episode Claims") xtitle("Period") ///
	coeflabels(c1="-4+" tm3="-3" tm2="-2" c4="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
graph save "${RESULTS_FINAL}f2_EventClaims_CSDID", replace
graph export "${RESULTS_FINAL}f2_EventClaims_CSDID.png", as(png) replace

		
********************************************
** FE-IV 
use "${DATA_FINAL}FinalEpisodesData.dta", clear


** first-stage
reghdfe PH_VI i.Year i.month $PATIENT_VARS total_revchange, absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

reghdfe PH_VI i.Year i.month $PATIENT_VARS $COUNTY_VARS total_revchange, absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

reghdfe PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month total_revchange, absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

** reduced form
reghdfe ln_ep_spend total_revchange i.month i.Year, absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

reghdfe ln_ep_spend total_revchange i.Year i.month $PATIENT_VARS $COUNTY_VARS, absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

reghdfe ln_ep_spend Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS total_revchange i.month i.Year, absorb($ABSORB_VARS) cluster(physician_npi)
test total_revchange

		
** iv estimates		
local step=0
foreach x of varlist $OUTCOMES_SPEND {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb(physician_npi NPINUM) cluster(physician_npi)
	est store feiv_spend1_`step'
	estadd local NPI "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"
	gen samp1b_`step'=e(sample)

	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"
	gen samp1_`step'=e(sample)
	
	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	gen samp2_`step'=e(sample)
		
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"
	gen samp3_`step'=e(sample)
	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality any_comp readmit (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_spend5_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"
	estadd local quality "X"
	gen samp4_`step'=e(sample)
	
}


** Display Results
esttab feiv_spend1_1 feiv_spend2_1 feiv_spend3_1 feiv_spend4_1 feiv_spend5_1 using "${RESULTS_FINAL}t4_levcharge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

	
esttab feiv_spend1_2 feiv_spend2_2 feiv_spend3_2 feiv_spend4_2 feiv_spend5_2 using "${RESULTS_FINAL}t4_levspend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	

esttab feiv_spend1_3 feiv_spend2_3 feiv_spend3_3 feiv_spend4_3 feiv_spend5_3 using "${RESULTS_FINAL}t4_levevents_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

esttab feiv_spend1_4 feiv_spend2_4 feiv_spend3_4 feiv_spend4_4 feiv_spend5_4 using "${RESULTS_FINAL}t4_levrvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	
esttab feiv_spend1_5 feiv_spend2_5 feiv_spend3_5 feiv_spend4_5 feiv_spend5_5 using "${RESULTS_FINAL}t4_levservice_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
		

esttab feiv_spend1_6 feiv_spend2_6 feiv_spend3_6 feiv_spend4_6 feiv_spend5_6 using "${RESULTS_FINAL}t4_levclaims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
		
	
esttab feiv_spend1_7 feiv_spend2_7 feiv_spend3_7 feiv_spend4_7 feiv_spend5_7 using "${RESULTS_FINAL}t4_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_spend1_8 feiv_spend2_8 feiv_spend3_8 feiv_spend4_8 feiv_spend5_8 using "${RESULTS_FINAL}t4_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_spend1_9 feiv_spend2_9 feiv_spend3_9 feiv_spend4_9 feiv_spend5_9 using "${RESULTS_FINAL}t4_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_spend1_10 feiv_spend2_10 feiv_spend3_10 feiv_spend4_10 feiv_spend5_10 using "${RESULTS_FINAL}t4_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

	
esttab feiv_spend1_11 feiv_spend2_11 feiv_spend3_11 feiv_spend4_11 feiv_spend5_11 using "${RESULTS_FINAL}t4_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

	
esttab feiv_spend1_12 feiv_spend2_12 feiv_spend3_12 feiv_spend4_12 feiv_spend5_12 using "${RESULTS_FINAL}t4_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N NPI pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician and Hospital FE" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

	
********************************************
** Investigate changes in quality
use "${DATA_FINAL}FinalEpisodesData.dta", clear

local step=0
foreach x of varlist $OUTCOMES_QUAL {
	local step=`step'+1
	
	** OLS estimates
	qui reghdfe `x' PH_VI $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_qual1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui reghdfe `x' PH_VI $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_qual2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"
	estadd local county "X"
	
	qui reghdfe `x' PH_VI Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month, ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store fe_qual3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local hosp "X"
	estadd local county "X"
		
	
	** IV estimates
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_qual1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"
	
	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_qual2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"		
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_qual3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"
	
}

** Display Results
esttab fe_qual1_1 fe_qual2_1 fe_qual3_1 using "${RESULTS_FINAL}app_quality_mort_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars")) ///
	nonum collabels(none) gaps noobs


esttab fe_qual1_2 fe_qual2_2 fe_qual3_2 using "${RESULTS_FINAL}app_quality_readmit_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab fe_qual1_5 fe_qual2_5 fe_qual3_5 using "${RESULTS_FINAL}app_quality_comp_fe.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars")) ///
	nonum collabels(none) gaps noobs
	
	
esttab feiv_qual1_1 feiv_qual2_1 feiv_qual3_1 using "${RESULTS_FINAL}app_quality_mort_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_qual1_2 feiv_qual2_2 feiv_qual3_2 using "${RESULTS_FINAL}app_quality_readmit_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_qual1_5 feiv_qual2_5 feiv_qual3_5 using "${RESULTS_FINAL}app_quality_comp_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars")) ///
	nonum collabels(none) gaps noobs
		

		
		
****************************************************************************************
** Components of episode
****************************************************************************************	
use "${DATA_FINAL}FinalEpisodesData.dta", clear
gen li_spend=tot_lab_spend+imaging_spend
gen li_charge=tot_lab_charge+imaging_charge
gen li_service=tot_lab_srvc_count+imaging_srvc_count
gen li_rvu=tot_lab_rvu + imaging_rvu
gen li_events=tot_lab_events + imaging_events
gen li_claims=tot_lab_claims + imaging_claims
sum episode_spend ip_spend op_spend hha_spend snf_spend tot_lab_spend office_spend em_spend imaging_spend li_spend
sum episode_service_count ip_service_count op_service_count hha_service_count snf_service_count tot_lab_srvc_count office_service_count em_srvc_count imaging_srvc_count li_service
sum episode_rvu ip_rvu op_rvu hha_rvu snf_rvu tot_lab_rvu office_rvu em_rvu imaging_rvu li_rvu
sum episode_events ip_events op_events hha_events snf_events tot_lab_events office_events em_events imaging_events li_events
sum episode_claims ip_claims op_claims hha_claims snf_claims tot_lab_claims office_claims em_claims imaging_claims li_claims

** charges
local step=0
foreach x of varlist episode_charge ip_charge op_charge hha_charge snf_charge office_charge {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compcharge1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"
	
	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compcharge2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compcharge3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"
	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compcharge4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"
	estadd local quality "X"
	
}


** Display Results
esttab feiv_compcharge1_1 feiv_compcharge2_1 feiv_compcharge3_1 feiv_compcharge4_1 using "${RESULTS_FINAL}t5_episode_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_compcharge1_2 feiv_compcharge2_2 feiv_compcharge3_2 feiv_compcharge4_2 using "${RESULTS_FINAL}t5_ip_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compcharge1_3 feiv_compcharge2_3 feiv_compcharge3_3 feiv_compcharge4_3 using "${RESULTS_FINAL}t5_op_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compcharge1_4 feiv_compcharge2_4 feiv_compcharge3_4 feiv_compcharge4_4 using "${RESULTS_FINAL}t5_hha_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_compcharge1_5 feiv_compcharge2_5 feiv_compcharge3_5 feiv_compcharge4_5 using "${RESULTS_FINAL}t5_snf_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
	
esttab feiv_compcharge1_6 feiv_compcharge2_6 feiv_compcharge3_6 feiv_compcharge4_6 using "${RESULTS_FINAL}t5_office_charge_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

	
** payments
local step=0
foreach x of varlist episode_spend ip_spend op_spend hha_spend snf_spend office_spend {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comppay1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comppay2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comppay3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comppay4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

** Display Results
esttab feiv_comppay1_1 feiv_comppay2_1 feiv_comppay3_1 feiv_comppay4_1 using "${RESULTS_FINAL}t5_episode_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_comppay1_2 feiv_comppay2_2 feiv_comppay3_2 feiv_comppay4_2 using "${RESULTS_FINAL}t5_ip_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_comppay1_3 feiv_comppay2_3 feiv_comppay3_3 feiv_comppay4_3 using "${RESULTS_FINAL}t5_op_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_comppay1_4 feiv_comppay2_4 feiv_comppay3_4 feiv_comppay4_4 using "${RESULTS_FINAL}t5_hha_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_comppay1_5 feiv_comppay2_5 feiv_comppay3_5 feiv_comppay4_5 using "${RESULTS_FINAL}t5_snf_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_comppay1_6 feiv_comppay2_6 feiv_comppay3_6 feiv_comppay4_6 using "${RESULTS_FINAL}t5_office_pay_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


	
	
** events
local step=0
foreach x of varlist episode_events ip_events op_events hha_events snf_events office_events {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compevent1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compevent2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compevent3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compevent4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

** Display Results
esttab feiv_compevent1_1 feiv_compevent2_1 feiv_compevent3_1 feiv_compevent4_1 using "${RESULTS_FINAL}t5_episode_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compevent1_2 feiv_compevent2_2 feiv_compevent3_2 feiv_compevent4_2 using "${RESULTS_FINAL}t5_ip_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compevent1_3 feiv_compevent2_3 feiv_compevent3_3 feiv_compevent4_3 using "${RESULTS_FINAL}t5_op_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_compevent1_4 feiv_compevent2_4 feiv_compevent3_4 feiv_compevent4_4 using "${RESULTS_FINAL}t5_hha_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_compevent1_5 feiv_compevent2_5 feiv_compevent3_5 feiv_compevent4_5 using "${RESULTS_FINAL}t5_snf_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_compevent1_6 feiv_compevent2_6 feiv_compevent3_6 feiv_compevent4_6 using "${RESULTS_FINAL}t5_office_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
	

	
** service count
local step=0
foreach x of varlist episode_service_count ip_service_count op_service_count hha_service_count snf_service_count office_service_count {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compservice1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compservice2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compservice3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compservice4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

** Display Results
esttab feiv_compservice1_1 feiv_compservice2_1 feiv_compservice3_1 feiv_compservice4_1 using "${RESULTS_FINAL}t5_episode_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compservice1_2 feiv_compservice2_2 feiv_compservice3_2 feiv_compservice4_2 using "${RESULTS_FINAL}t5_ip_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compservice1_3 feiv_compservice2_3 feiv_compservice3_3 feiv_compservice4_3 using "${RESULTS_FINAL}t5_op_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_compservice1_4 feiv_compservice2_4 feiv_compservice3_4 feiv_compservice4_4 using "${RESULTS_FINAL}t5_hha_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_compservice1_5 feiv_compservice2_5 feiv_compservice3_5 feiv_compservice4_5 using "${RESULTS_FINAL}t5_snf_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_compservice1_6 feiv_compservice2_6 feiv_compservice3_6 feiv_compservice4_6 using "${RESULTS_FINAL}t5_office_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

** RVU
local step=0
foreach x of varlist episode_rvu ip_rvu op_rvu hha_rvu snf_rvu office_rvu {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comprvu1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comprvu2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comprvu3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_comprvu4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

** Display Results
esttab feiv_comprvu1_1 feiv_comprvu2_1 feiv_comprvu3_1 feiv_comprvu4_1 using "${RESULTS_FINAL}t5_episode_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_comprvu1_2 feiv_comprvu2_2 feiv_comprvu3_2 feiv_comprvu4_2 using "${RESULTS_FINAL}t5_ip_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_comprvu1_3 feiv_comprvu2_3 feiv_comprvu3_3 feiv_comprvu4_3 using "${RESULTS_FINAL}t5_op_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_comprvu1_4 feiv_comprvu2_4 feiv_comprvu3_4 feiv_comprvu4_4 using "${RESULTS_FINAL}t5_hha_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_comprvu1_5 feiv_comprvu2_5 feiv_comprvu3_5 feiv_comprvu4_5 using "${RESULTS_FINAL}t5_snf_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_comprvu1_6 feiv_comprvu2_6 feiv_comprvu3_6 feiv_comprvu4_6 using "${RESULTS_FINAL}t5_office_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


** Claims
local step=0
foreach x of varlist episode_claims ip_claims op_claims hha_claims snf_claims office_claims {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compclaims1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compclaims2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compclaims3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_compclaims4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

** Display Results
esttab feiv_compclaims1_1 feiv_compclaims2_1 feiv_compclaims3_1 feiv_compclaims4_1 using "${RESULTS_FINAL}t5_episode_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compclaims1_2 feiv_compclaims2_2 feiv_compclaims3_2 feiv_compclaims4_2 using "${RESULTS_FINAL}t5_ip_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab feiv_compclaims1_3 feiv_compclaims2_3 feiv_compclaims3_3 feiv_compclaims4_3 using "${RESULTS_FINAL}t5_op_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_compclaims1_4 feiv_compclaims2_4 feiv_compclaims3_4 feiv_compclaims4_4 using "${RESULTS_FINAL}t5_hha_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs


esttab feiv_compclaims1_5 feiv_compclaims2_5 feiv_compclaims3_5 feiv_compclaims4_5 using "${RESULTS_FINAL}t5_snf_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_compclaims1_6 feiv_compclaims2_6 feiv_compclaims3_6 feiv_compclaims4_6 using "${RESULTS_FINAL}t5_office_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
	
** total labs and imaging from betos codes
est clear
local step=0
foreach x of varlist li_spend li_rvu li_service li_events li_claims {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

esttab feiv_totlab1_1 feiv_totlab2_1 feiv_totlab3_1 feiv_totlab4_1 using "${RESULTS_FINAL}t5_labimage_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_totlab1_2 feiv_totlab2_2 feiv_totlab3_2 feiv_totlab4_2 using "${RESULTS_FINAL}t5_labimage_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_totlab1_3 feiv_totlab2_3 feiv_totlab3_3 feiv_totlab4_3 using "${RESULTS_FINAL}t5_labimage_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

esttab feiv_totlab1_4 feiv_totlab2_4 feiv_totlab3_4 feiv_totlab4_4 using "${RESULTS_FINAL}t5_labimage_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	


esttab feiv_totlab1_5 feiv_totlab2_5 feiv_totlab3_5 feiv_totlab4_5 using "${RESULTS_FINAL}t5_labimage_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

	
** e&m visits from betos codes
est clear
local step=0
foreach x of varlist em_spend em_rvu em_srvc_count em_events em_claims {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_em1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_em2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_em3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_em4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

esttab feiv_em1_1 feiv_em2_1 feiv_em3_1 feiv_em4_1 using "${RESULTS_FINAL}t5_em_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_em1_2 feiv_em2_2 feiv_em3_2 feiv_em4_2 using "${RESULTS_FINAL}t5_em_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_em1_3 feiv_em2_3 feiv_em3_3 feiv_em4_3 using "${RESULTS_FINAL}t5_em_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	

esttab feiv_em1_4 feiv_em2_4 feiv_em3_4 feiv_em4_4 using "${RESULTS_FINAL}t5_em_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	

esttab feiv_em1_5 feiv_em2_5 feiv_em3_5 feiv_em4_5 using "${RESULTS_FINAL}t5_em_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

	
** total labs from betos codes
est clear
local step=0
foreach x of varlist tot_lab_spend tot_lab_rvu tot_lab_srvc_count tot_lab_events tot_lab_claims {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

esttab feiv_totlab1_1 feiv_totlab2_1 feiv_totlab3_1 feiv_totlab4_1 using "${RESULTS_FINAL}t5_lab_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_totlab1_2 feiv_totlab2_2 feiv_totlab3_2 feiv_totlab4_2 using "${RESULTS_FINAL}t5_lab_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_totlab1_3 feiv_totlab2_3 feiv_totlab3_3 feiv_totlab4_3 using "${RESULTS_FINAL}t5_lab_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

esttab feiv_totlab1_4 feiv_totlab2_4 feiv_totlab3_4 feiv_totlab4_4 using "${RESULTS_FINAL}t5_lab_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	


esttab feiv_totlab1_5 feiv_totlab2_5 feiv_totlab3_5 feiv_totlab4_5 using "${RESULTS_FINAL}t5_lab_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	
	
** imaging from betos codes
est clear
local step=0
foreach x of varlist imaging_spend imaging_rvu imaging_srvc_count imaging_events imaging_claims {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_totlab4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

esttab feiv_totlab1_1 feiv_totlab2_1 feiv_totlab3_1 feiv_totlab4_1 using "${RESULTS_FINAL}t5_image_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_totlab1_2 feiv_totlab2_2 feiv_totlab3_2 feiv_totlab4_2 using "${RESULTS_FINAL}t5_image_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_totlab1_3 feiv_totlab2_3 feiv_totlab3_3 feiv_totlab4_3 using "${RESULTS_FINAL}t5_image_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	
esttab feiv_totlab1_4 feiv_totlab2_4 feiv_totlab3_4 feiv_totlab4_4 using "${RESULTS_FINAL}t5_image_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

esttab feiv_totlab1_5 feiv_totlab2_5 feiv_totlab3_5 feiv_totlab4_5 using "${RESULTS_FINAL}t5_image_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	


** all professional services
est clear
local step=0
foreach x of varlist carrier_spend episode_rvu episode_service_count carrier_events carrier_claims {
	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_prof1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_prof2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_prof3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"	
	estadd local hosp "X"

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store feiv_prof4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	estadd local hosp "X"
	estadd local quality "X"
	
}

esttab feiv_prof1_1 feiv_prof2_1 feiv_prof3_1 feiv_prof4_1 using "${RESULTS_FINAL}t5_prof_spend_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab feiv_prof1_2 feiv_prof2_2 feiv_prof3_2 feiv_prof4_2 using "${RESULTS_FINAL}t5_prof_rvu_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab feiv_prof1_3 feiv_prof2_3 feiv_prof3_3 feiv_prof4_3 using "${RESULTS_FINAL}t5_prof_service_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	

esttab feiv_prof1_4 feiv_prof2_4 feiv_prof3_4 feiv_prof4_4 using "${RESULTS_FINAL}t5_prof_events_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	
	

esttab feiv_prof1_5 feiv_prof2_5 feiv_prof3_5 feiv_prof4_5 using "${RESULTS_FINAL}t5_prof_claims_feiv.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs	

	
/*	
** event studies for components of episode
use temp_event_data, clear
gen cs_time=first
replace cs_time=0 if ever_vi==0

foreach x of varlist ln_ip_spend ln_op_spend ln_carrier_spend ln_snf_spend ln_hha_spend {
	csdid2 `x', time(Year) gvar(cs_time) notyet cluster(physician_npi) method(reg)
	estat event
	matrix C = r(b)
	matrix C2=(C[1,3..6],0,C[1,7..11])
	mata st_matrix("A",diagonal(sqrt(st_matrix("r(V)"))))
	matrix A=A'
	matrix A2=(A[1,3..6],0,A[1,7..11])
	coefplot matrix(C2), se(A2) vert ytitle("Log Episode RVUs") xtitle("Period") ///
		coeflabels(tm5="-5" tm4="-4" tm3="-3" tm2="-2" c5="-1" tp0="0" tp1="+1" tp2="+2" tp3="+3" tp4="+4") yline(0, lwidth(vvthin) lcolor(gray))
	graph save "${RESULTS_FINAL}csdid_comp_`x'", replace
	graph export "${RESULTS_FINAL}csdid_comp_`x'.png", as(png) replace
}	
*/


****************************************************************************************
** Examine referral patterns
****************************************************************************************
use "${DATA_FINAL}FinalEpisodesData.dta", clear
merge 1:1 bene_id initial_id physician_npi NPINUM using "${DATA_FINAL}ReferralData.dta"
keep if _merge==3
drop _merge

foreach x of varlist episode_spend_vi episode_spend_no_vi episode_rvu_vi episode_rvu_no_vi episode_service_vi episode_service_no_vi episode_events_vi episode_events_no_vi episode_claims_vi episode_claims_no_vi {
	replace `x'=0 if `x'==.
	replace `x'=. if `x'<0
	_pctile `x', percentiles(99)
	replace `x'=r(r1) if `x'>=r(r1)
}

local step=0
foreach x of varlist episode_spend_vi episode_spend_no_vi episode_rvu_vi episode_rvu_no_vi episode_service_vi episode_service_no_vi episode_events_vi episode_events_no_vi episode_claims_vi episode_claims_no_vi {

	local step=`step'+1
	
	qui ivreghdfe `x' $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store refer1_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"
	gen samp1_`step'=e(sample)

	qui ivreghdfe `x' $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store refer2_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local county "X"
	gen samp2_`step'=e(sample)

	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store refer3_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local hosp "X"
	estadd local county "X"
	gen samp3_`step'=e(sample)
	
	qui ivreghdfe `x' Hospital_VI $HOSP_CONTROLS $COUNTY_VARS $PATIENT_VARS i.Year i.month mortality readmit any_comp (PH_VI=total_revchange), ///
		absorb($ABSORB_VARS) cluster(physician_npi)
	est store refer4_`step'
	estadd local pair "X"
	estadd local year "X"
	estadd local month "X"
	estadd local patient "X"	
	estadd local hosp "X"
	estadd local county "X"
	estadd local quality "X"
	gen samp4_`step'=e(sample)
	
}


** Display Results
esttab refer1_1 refer2_1 refer3_1 refer4_1 using "${RESULTS_FINAL}t7_refer_pay_vi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab refer1_2 refer2_2 refer3_2 refer4_2 using "${RESULTS_FINAL}t7_refer_pay_novi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab refer1_3 refer2_3 refer3_3 refer4_3 using "${RESULTS_FINAL}t7_refer_rvu_vi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
esttab refer1_4 refer2_4 refer3_4 refer4_4 using "${RESULTS_FINAL}t7_refer_rvu_novi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab refer1_5 refer2_5 refer3_5 refer4_5 using "${RESULTS_FINAL}t7_refer_service_vi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab refer1_6 refer2_6 refer3_6 refer4_6 using "${RESULTS_FINAL}t7_refer_service_novi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab refer1_7 refer2_7 refer3_7 refer4_7 using "${RESULTS_FINAL}t7_refer_events_vi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab refer1_8 refer2_8 refer3_8 refer4_8 using "${RESULTS_FINAL}t7_refer_events_novi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	

esttab refer1_9 refer2_9 refer3_9 refer4_9 using "${RESULTS_FINAL}t7_refer_claims_vi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs

esttab refer1_10 refer2_10 refer3_10 refer4_10 using "${RESULTS_FINAL}t7_refer_claims_novi.tex", replace ///
	f label booktabs b(3) p(3) eqlabels(none) alignment(S) ///
	mtitle("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	cells("b(fmt(%9.3fc)star)" "se(par)") ///
	keep(PH_VI) ///
	stats(N pair year month patient county hosp quality, fmt(%9.0fc) ///
	   label("Observations" "Physician-Hospital FE" "Year FE" "Month FE" "Patient Vars" "County Vars" "Hospital Vars" "Quality Vars")) ///
	nonum collabels(none) gaps noobs
	
/*	
** event studies for referral patterns
gen low=.
replace low=Year if PH_VI==1
bys physician_npi NPINUM: egen first=min(low)
bys physician_npi NPINUM: egen ever_vi=max(PH_VI)
bys physician_npi NPINUM: egen count_vi=total(PH_VI)
bys physician_npi NPINUM: gen count_obs=_N
gen always_vi=(count_obs==count_vi)
drop low
gen time=(Year-first)+1
replace time=0 if ever_vi==0
tab time, gen(ev_full)
gen never_vi=(ever_vi==0)
gen cs_time=first
replace cs_time=0 if ever_vi==0

foreach x of varlist vi_phy_claims other_nonvi_claims pay_vi_phy pay_novi_phy ln_pay_vi_phy ln_pay_novi_phy {
	csdid `x', time(Year) gvar(cs_time) notyet cluster(physician_npi)
	csdid_estat event
	csdid_plot, ytitle(Estimated ATT)
	gr_edit .xaxis1.reset_rule 10, tickset(major) ruletype(suggest) 
	graph save "${RESULTS_FINAL}csdid_`x'", replace
	graph export "${RESULTS_FINAL}csdid_`x'.png", as(png) replace
}	
*/
	
	
