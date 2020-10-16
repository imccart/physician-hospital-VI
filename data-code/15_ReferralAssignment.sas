/* ------------------------------------------------------------ */
/* TITLE:		 Assign Referring Physician to Inpatient Claims */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 1/2/2019										*/
/* DATE EDITED:  10/17/2019										*/
/* CODE FILE ORDER: 4 of XX										*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)   	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		OrthoReferral_2008-2015								*/
/* ------------------------------------------------------------ */
%LET year_data=2015;
%LET year_lag=2014;

/* Identify unique inpatient stays */
PROC SQL;
	DROP TABLE WORK.Unique_Stays;
	CREATE TABLE WORK.Unique_Stays AS
	SELECT DISTINCT BENE_ID, CLM_FROM_DT AS Date, OP_PHYSN_NPI, ORG_NPI_NUM AS Facility_ID
	FROM IMC969SL.MajorJoint_&year_data
	GROUP BY BENE_ID, CLM_FROM_DT, ORG_NPI_NUM, OP_PHYSN_NPI;
QUIT;

DATA WORK.Carrier;
	SET	IMC969SL.OrthoCarrier_&year_data
  		IMC969SL.OrthoCarrier_&year_lag;
RUN;


/* Merge carrier file to inpatient claim */
/* example: take all ortho surgeries in 2010 and merge with all carrier claims of those same patients in 2009 and 2010 */
PROC SQL;
	DROP TABLE WORK.Referrals_&year_data;
	CREATE TABLE WORK.Referrals_&year_data AS
	SELECT a.*, a.Date, b.*
	FROM WORK.Unique_Stays AS a 
	LEFT JOIN WORK.Carrier AS b
		ON a.BENE_ID=b.BENE_ID
		WHERE (b.Visit_Date <= a.Date)
		AND (b.Visit_Date > (a.Date-365)) 
		AND b.Physician_ID NE ''
		AND b.Physician_ID NE a.OP_PHYSN_NPI
	ORDER BY BENE_ID, Physician_ID, Visit_Date, Date;
QUIT;

/* Group merged data by physician, beneficiary, and date of inpatient admission */
PROC SQL;
	DROP TABLE IMC969SL.PreSurgery_Physicians_&year_data;
	CREATE TABLE IMC969SL.PreSurgery_Physicians_&year_data AS
	SELECT Physician_ID, BENE_ID, Date, Phy_Tax_ID, count(BENE_ID) AS Visits, max(Visit_Date) AS Max_Visit_Date FORMAT=DATE9.,
		min(Visit_Date) AS Min_Visit_Date FORMAT=DATE9.
	FROM WORK.Referrals_&year_data
	GROUP BY BENE_ID, Date, Physician_ID, Phy_Tax_ID;
QUIT;

