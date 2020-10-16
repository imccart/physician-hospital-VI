******************************************************************
**	Title:			PH4_AHA_Data
**	Description:	Collect hospital characteristics from AHA annual surveys
**	Author:			Ian McCarthy
**	Date Created:	10/9/16
**	Date Updated:	5/15/2020
******************************************************************

******************************************************************
/* Read and clean AHA data */
******************************************************************

************************************
** 2007 data
insheet using "${DATA_AHA}pubas07.csv", clear case

drop DBEGM DBEGD DBEGY DENDM DENDD DENDY FISM FISD FISY MADMIN TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
	gen `x'_clean=date(`x',"MDY")
	drop `x'
	rename `x'_clean `x'
	format `x' %td
}
gen AHAYEAR=2007
tostring MLOCZIP, replace
replace SYSTELN=subinstr(SYSTELN,"-","",1)
destring SYSTELN, replace
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
rename HCFAID MCRNUM
gen AHAMBR2=(AHAMBR=="Y")
drop AHAMBR
rename AHAMBR2 AHAMBR
save temp_data_2007, replace


************************************
** 2008 data
insheet using "${DATA_AHA}pubas08.csv", clear case

drop DBEGM DBEGD DBEGY DENDM DENDD DENDY FISM FISD FISY MADMIN TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
	gen `x'_clean=date(`x',"MDY")
	drop `x'
	rename `x'_clean `x'
	format `x' %td
}
gen AHAYEAR=2008
tostring MLOCZIP, replace
replace SYSTELN=subinstr(SYSTELN,"-","",1)
destring SYSTELN, replace
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
rename NPI_NUM NPINUM
save temp_data_2008, replace


************************************
** 2009 data
insheet using "${DATA_AHA}pubas09.csv", clear case

drop DBEGM DBEGD DBEGY DENDM DENDD DENDY FISM FISD FISY MADMIN TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
	gen `x'_clean=date(`x',"MDY")
	drop `x'
	rename `x'_clean `x'
	format `x' %td
}
gen AHAYEAR=2009
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2009, replace


************************************
** 2010 data
insheet using "${DATA_AHA}ASPUB10.csv", clear case
replace EHLTH="0" if EHLTH=="N"
replace EHLTH="" if EHLTH=="." | EHLTH=="2"
destring EHLTH, replace

drop TELNO NETPHONE MLOS
foreach x of varlist DTBEG DTEND FISYR {
	gen `x'_clean=date(`x',"MDY")
	drop `x'
	rename `x'_clean `x'
	format `x' %td
}
gen AHAYEAR=2010
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2010, replace


************************************
** 2011 data
insheet using "${DATA_AHA}ASPUB11.csv", clear case

drop TELNO NETPHONE 
foreach x of varlist DTBEG DTEND FISYR {
	gen `x'_clean=date(`x',"MDY")
	drop `x'
	rename `x'_clean `x'
	format `x' %td
}
gen AHAYEAR=2011
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2011, replace


************************************
** 2012 data
insheet using "${DATA_AHA}ASPUB12.csv", clear case

drop TELNO NETPHONE 
foreach x of varlist DTBEG DTEND FISYR {
	gen `x'_clean=date(`x',"MDY")
	drop `x'
	rename `x'_clean `x'
	format `x' %td
}
gen AHAYEAR=2012
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2012, replace


************************************
** 2013 data
insheet using "${DATA_AHA}ASPUB13.csv", clear case

drop TELNO NETPHONE 
foreach x of varlist DTBEG DTEND FISYR {
	todate `x', gen(`x'_clean) p(mmddyy) cend(2100)
	drop `x'
	rename `x'_clean `x'
}
gen byte notnumeric=(real(MCRNUM)==. & MCRNUM!="")
replace MCRNUM="" if notnumeric==1
destring MCRNUM, replace

gen AHAYEAR=2013
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2013, replace


************************************
** 2014 data
insheet using "${DATA_AHA}ASPUB14.csv", clear case

drop TELNO NETPHONE 
foreach x of varlist DTBEG DTEND FISYR {
	todate `x', gen(`x'_clean) p(mmddyy) cend(2100)
	drop `x'
	rename `x'_clean `x'
}
gen byte notnumeric=(real(MCRNUM)==. & MCRNUM!="")
replace MCRNUM="" if notnumeric==1
destring MCRNUM, replace

gen AHAYEAR=2014
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2014, replace


************************************
** 2015 data
insheet using "${DATA_AHA}ASPUB15.csv", clear case

drop TELNO NETPHONE 
foreach x of varlist DTBEG DTEND FISYR {
	todate `x', gen(`x'_clean) p(mmddyy) cend(2100)
	drop `x'
	rename `x'_clean `x'
}
gen byte notnumeric=(real(MCRNUM)==. & MCRNUM!="")
replace MCRNUM="" if notnumeric==1
destring MCRNUM, replace

gen AHAYEAR=2015
gen fips=string(FSTCD)+"_"+string(FCNTYCD)
sort fips
save temp_data_2015, replace


************************************
** Append All Years
use temp_data_2007, clear
forvalues t=2008/2015 {
	append using temp_data_`t'
}

rename AHAYEAR Year
gen double NPINUM_old=NPINUM
gen byte nonmiss=!mi(NPINUM)
bys ID (nonmiss): replace NPINUM=NPINUM[_N] if nonmiss==0
drop nonmiss NPINUM_old

******************************************************************
/* Create AHA variables of interest */
******************************************************************

replace SERV=49 if SERV==48   /* Assign "other" to chronic specialty hospitals */
replace SERV=49 if SERV==45   /* Assign "other" to ENT specialty hospitals */
replace MNGT=0 if MNGT==.
replace NETWRK=0 if NETWRK==.

** Ownership type (control code)
label define Own_Lab 1 "Govt, Not Federal" 2 "Not-for-profit" 3 "For-profit" 4 "Govt, Federal"
gen Own_Type=inrange(CNTRL,12,16) + 2*inrange(CNTRL,21,23) + 3*inrange(CNTRL,30,33) + 4*inrange(CNTRL,41,48)
label values Own_Type Own_Lab
gen Government=(Own_Type==1)
gen Nonprofit=(Own_Type==2)
gen Profit=(Own_Type==3)

** General Service Type
label define Service_Lab 1 "General" 2 "Specialty"
gen Service_Type=inrange(SERV,10,13) + 2*inrange(SERV,22,90)
label values Service_Type Service_Lag

** Service Detail
label define Service_Detail_Lab 10 "General" 13 "Surgical" 33 "Respiratory" 41 "Cancer" ///
  42 "Heart" 44 "OBGYN" 47 "Orthopedic" 49 "Other Specialty"
label values SERV Service_Detail_Lab
gen General=(SERV==10)
gen Surgical=(SERV==13)
gen Respiratory=(SERV==33)
gen Cancer=(SERV==41)
gen Heart=(SERV==42)
gen OBGYN=(SERV==44)
gen Ortho=(SERV==47)
gen Other=(SERV==49)

** Vertical Integration 
foreach x of newlist HOS SYS NET {
  rename GPWW`x' GPW`x'
  rename OPHO`x' OPH`x'
  rename CPHO`x' CPH`x'
  rename FOUND`x' FND`x'
  rename EQMOD`x' EQM`x'
}
label define Int_Lab 0 "NONE" 1 "IPA" 2 "GPW" 3 "OPH" 4 "CPS" 5 "MSO" 6 "ISM" 7 "EQUITY"
foreach x of newlist HOS SYS NET {
  gen Int_`x'=0
  replace Int_`x'=1 if IPA`x'==1
  replace Int_`x'=2 if GPW`x'==1
  replace Int_`x'=3 if OPH`x'==1
  replace Int_`x'=4 if CPH`x'==1
  replace Int_`x'=5 if MSO`x'==1
  replace Int_`x'=6 if ISM`x'==1
  replace Int_`x'=7 if EQM`x'==1
  label values Int_`x' Int_Lab
}
replace Int_HOS=7 if PHYGP==1

label define Int_Lab_2 0 "NONE" 1 "Support" 2 "Referrals" 3 "Employee" 4 "Equity"
gen Int_HOS_2=0
replace Int_HOS_2=1 if IPAHOS==1 | GPWHOS==1 | MSOHOS==1
replace Int_HOS_2=2 if OPHHOS==1 | CPHHOS==1 | FNDHOS==1
replace Int_HOS_2=3 if ISMHOS==1
replace Int_HOS_2=4 if EQMHOS==1 | PHYGP==1
label values Int_HOS_2 Int_Lab_2

** System Participation
gen System=(SYSID!=. | MHSMEMB==1)
label variable System "Member of Larger System"

** Hospital Size
label variable BDTOT "Total Staffed Facility Beds"
replace BDTOT=BDTOT/100

** Teaching Status
gen Teaching_Hospital=(FTRES>10) if FTRES!=.
gen Teaching_Hospital1=(MAPP8==1) if MAPP8!=.
gen Teaching_Hospital2=(MAPP3==1 | MAPP5==1 | MAPP8==1 | MAPP13==1)

** Labor Market Variables
gen Labor_Phys=FTEMD
gen Labor_Residents=FTERES
gen Labor_Nurse=FTERN+FTELPN
gen Labor_Other=FTEH-Labor_Phys-Labor_Residents-Labor_Nurse
replace Labor_Other=. if Labor_Other<=0

** Capital Variables
gen Capital_Imaging=MAMMSHOS+ACLABHOS+ENDOCHOS+ENDOUHOS+REDSHOS+CTSCNHOS+DRADFHOS+EBCTHOS+FFDMHOS+MRIHOS+IMRIHOS ///
   + MSCTHOS+MSCTGHOS+PETHOS+PETCTHOS+SPECTHOS+ULTSNHOS
gen Capital_CareSetting=AMBSHOS+EMDEPHOS
gen Capital_Services=ICLABHOS+ADTCHOS+ADTEHOS+CHTHHOS+CAOSHOS+ONCOLHOS+RASTHOS+IMRTHOS+PTONHOS

** Clean data
bys MCRNUM Year: gen mcr_obs=_N
drop if mcr_obs>4
drop if NPINUM==. & mcr_obs>1 

drop mcr_obs
bys MCRNUM Year: gen mcr_obs=_N
bys MCRNUM Year: egen max_beds=max(BDTOT)
drop if mcr_obs>1 & BDTOT<max_beds

keep NPINUM MCRNUM MNAME SYSID SYSNAME Year COMMTY Teaching_Hospital* BDTOT SERV System Int_HOS Int_HOS_2 Service_Type Government Nonprofit Profit General ///
  Surgical Respiratory Cancer Heart OBGYN Ortho Other HSACODE HSANAME HRRCODE HRRNAME Labor_* Capital_* fips
sort MCRNUM Year
save "${DATA_FINAL}AHA_Data.dta", replace

