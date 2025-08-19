******************************************************************
**	Title:		PH3_Inpatient_PPS_Data
**	Description:	Collect data on hospital case mix and other variables from the inpatient
**			PPS final rule files
**	Author:		Ian McCarthy
**	Date Created:	10/9/17
**	Date Updated:	3/10/24
******************************************************************


******************************************************************
/* Read in Case Mix Adjusted Admissions from Medicare Inpatient PPS Files */
******************************************************************
** 2007 Data
insheet using "${DATA_UPLOAD}imppuf07_apr2007.csv", clear case
rename ProviderNumber MCRNUM
rename TACMIV24 CMI 
rename CASETA24 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(URSPA=="LURBAN" | URSPA=="OURBAN")
rename BEDS Beds
rename ADC Daily_Census
gen Year=2007
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2007, replace


** 2008 Data
insheet using "${DATA_UPLOAD}imppuf08_103107.csv", clear case
rename ProviderNumber MCRNUM
rename TACMIV24 CMI 
rename CASETA24 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(URSPA=="LURBAN" | URSPA=="OURBAN")
rename BEDS Beds
rename ADC Daily_Census
gen Year=2008
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2008, replace


** 2009 Data
insheet using "${DATA_UPLOAD}imppuf09_080929.csv", clear case
rename ProviderNumber MCRNUM
rename TACMIV26 CMI 
rename CASETA26 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(URSPA=="LURBAN" | URSPA=="OURBAN")
rename BEDS Beds
rename AverageDailyCensus Daily_Census
gen Year=2009
rename OperatingCCR OPCCR
rename CapitalCCR CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2009, replace

** 2010 Data
insheet using "${DATA_UPLOAD}FY_2010_Final_Rule_Impact_File_1.txt", clear
rename providernumber MCRNUM
rename tacmiv26 CMI 
rename caseta26 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2010
rename operatingccr OPCCR
rename capitalccr CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2010, replace

** 2011 Data
insheet using "${DATA_UPLOAD}FY_2011_Final_Rule-_IPPS_Impact_File_PUF_1.txt", clear
rename providernumber MCRNUM
rename tacmiv27 CMI 
rename caseta27 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2011
rename operatingccr OPCCR
rename capitalccr CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2011, replace

** 2012 Data
insheet using "${DATA_UPLOAD}FY_2012_Final_Rule-_IPPS_Impact_File_PUF-August_15__2011_1.txt", clear
rename providernumber MCRNUM
rename tacmiv28 CMI 
rename caseta28 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2012
rename operatingccr OPCCR
rename capitalccr CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2012, replace

** 2013 Data
insheet using "${DATA_UPLOAD}FY_2013_Final_Rule_CN_-_IPPS_Impact_File_PUF-March_2013.txt", clear
rename providernumber MCRNUM
rename tacmiv29 CMI 
rename caseta29 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2013
rename operatingccr OPCCR
rename capitalccr CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2013, replace

** 2014 Data
insheet using "${DATA_UPLOAD}FY_2014_Final_Rule_IPPS_Impact_PUF.txt", clear
rename providernumber MCRNUM
rename tacmiv30 CMI 
rename caseta30 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2014
rename operatingccr OPCCR
rename capitalccr CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2014, replace

** 2015 Data
insheet using "${DATA_UPLOAD}FY_2015_IPPS_Final_Rule_Impact_PUF__FR_data_.txt", clear
rename providernumber MCRNUM
rename tacmiv31 CMI 
rename caseta31 Total_Cases
gen Adjusted_Cases=Total_Cases*CMI
gen ln_adj_cases=ln(Adjusted_Cases)
gen Urban=(urspa=="LURBAN" | urspa=="OURBAN")
rename beds Beds
rename averagedailycensus Daily_Census
gen Year=2015
rename operatingccr OPCCR
rename capitalccr CPCCR
gen CCR=OPCCR+CPCCR
keep MCRNUM CMI Total_Cases Adjusted_Cases ln_adj_cases Urban Beds Daily_Census CCR OPCCR CPCCR Year
save temp_pps_2015, replace

** Append years
use temp_pps_2007, clear
forvalues t=2008/2015 {
	append using temp_pps_`t'
}
save "${DATA_FINAL}Hospital_PPS.dta", replace

