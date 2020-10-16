/* ------------------------------------------------------------ */
/* TITLE:		 Create Dataset of All Unique Hospitals         */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 5/12/2015										*/
/* DATE EDITED:  9/25/2017										*/
/* CODE FILE ORDER: 3 of XX										*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		Hospital_Data_2007-2015									*/
/* ------------------------------------------------------------ */
%LET year_data=2015;

/* Create Tables for Aggregate Stays, Charges, Payments by Hospital            */
/* -- 2007 and 2008 have some hospitals with no NPI, so we fill that in with   */
/*    other sources  */
%macro hosp_data;
%IF &year_data=2007 OR &year_data=2008 %THEN %DO;
PROC SQL;
	DROP TABLE WORK.Hospital_Full;
	CREATE TABLE WORK.Hospital_Full AS
	SELECT 
		CASE
			WHEN a.ORG_NPI_NUM NE '' AND a.ORG_NPI_NUM NE '0000000000' THEN a.ORG_NPI_NUM
			WHEN a.ORG_NPI_NUM='' OR a.ORG_NPI_NUM='0000000000' THEN b.NPI
		ELSE ''
		END AS ORG_NPI_NUM, a.PRVDR_NUM,
		a.CLM_DRG_CD, a.CLM_ID, a.BENE_ID, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM IMC969SL.InpatientStays_&year_data AS a
	LEFT JOIN IMC969SL.PRVN_NPI_Merge_&year_data AS b
	ON a.PRVDR_NUM=b.PRVDR_NUM;
QUIT;


PROC SQL;
	DROP TABLE IMC969SL.Hospital_DRG_&year_data;
	CREATE TABLE IMC969SL.Hospital_DRG_&year_data AS
	SELECT ORG_NPI_NUM, CLM_DRG_CD AS DRG, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients
	FROM WORK.Hospital_Full
	GROUP BY ORG_NPI_NUM, CLM_DRG_CD;
QUIT;

PROC SQL;
	DROP TABLE WORK.Hospital_Data;
	CREATE TABLE WORK.Hospital_Data AS
	SELECT ORG_NPI_NUM,	max(PRVDR_NUM) AS PRVDR_NUM, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients, sum(CLM_PMT_AMT) AS Total_McarePymt, sum(CLM_TOT_CHRG_AMT) AS Total_Charges
	FROM WORK.Hospital_Full
	GROUP BY ORG_NPI_NUM;
QUIT;

%END;
%ELSE %DO;
PROC SQL;
	DROP TABLE IMC969SL.Hospital_DRG_&year_data;
	CREATE TABLE IMC969SL.Hospital_DRG_&year_data AS
	SELECT ORG_NPI_NUM, CLM_DRG_CD AS DRG, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients
	FROM IMC969SL.InpatientStays_&year_data
	GROUP BY ORG_NPI_NUM, CLM_DRG_CD;
QUIT;

PROC SQL;
	DROP TABLE WORK.Hospital_Data;
	CREATE TABLE WORK.Hospital_Data AS
	SELECT ORG_NPI_NUM, max(PRVDR_NUM) AS PRVDR_NUM, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients, sum(CLM_PMT_AMT) AS Total_McarePymt, sum(CLM_TOT_CHRG_AMT) AS Total_Charges
	FROM IMC969SL.InpatientStays_&year_data
	WHERE ORG_NPI_NUM IS NOT NULL
	GROUP BY ORG_NPI_NUM;
QUIT;


%END;
%mend hosp_data;

/* Run hospital data macro */
%hosp_data;



/* Table of NPI and Provider Numbers (to match with zip code data in earlier years) */
%macro hosp_zip;
%IF &year_data=2007 OR &year_data=2008 OR &year_data=2009 %THEN %DO;
PROC SQL;
	DROP TABLE WORK.Hospital_Zip;
	CREATE TABLE WORK.Hospital_Zip AS
	SELECT a.PRVDR_NUM, a.NPI, b.STATE_ABBREV AS State, b.ZIP_CD AS Zip, b.CITY, b.FACILITY_NAME AS Name
	FROM IMC969SL.PRVN_NPI_MERGE_&year_data AS a
	LEFT JOIN PROVIDER.POS_&year_data AS b
	ON a.PRVDR_NUM=b.PROV_NUM;
QUIT;
%END;
%ELSE %DO;
PROC SQL;
	DROP TABLE WORK.Hospital_Zip;
	CREATE TABLE WORK.Hospital_Zip AS
	SELECT NPI, SUBSTR(PROV_LOC_ZIP,1,5) AS Zip, PROV_LOC_STATE AS State, PROV_LOC_CITY AS City, Name
	FROM IMC969SL.NPPES_&year_data;
QUIT;
%END;
%mend hosp_zip;

/* Run hospital zip code macro */
%hosp_zip;

PROC SQL;
	DROP TABLE WORK.Hospital_DRGWeight;
	CREATE TABLE WORK.Hospital_DRGWeight AS
	SELECT a.ORG_NPI_NUM, a.DRG, a.Total_Admits, b.drgweight, a.Total_Admits*b.drgweight AS Total_DRG
	FROM IMC969SL.Hospital_DRG_&year_data AS a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=&year_data) AS b
	ON input(a.DRG,18.)=b.drg;
QUIT;

PROC SQL;
	DROP TABLE WORK.Hospital_TotalDRG;
	CREATE TABLE WORK.Hospital_TotalDRG AS
	SELECT ORG_NPI_NUM, sum(Total_DRG) AS Total_DRG
	FROM WORK.Hospital_DRGWeight 
	WHERE ORG_NPI_NUM IS NOT NULL
	GROUP BY ORG_NPI_NUM;
QUIT;


%macro hosp_final;
%IF &year_data=2007 OR &year_data=2008 OR &year_data=2009 %THEN %DO;
PROC SQL;
	DROP TABLE IMC969SL.Hospital_Data_&year_data;
	CREATE TABLE IMC969SL.Hospital_Data_&year_data AS
	SELECT a.*, 
		CASE
			WHEN b.Zip IS NOT NULL THEN b.Zip
			WHEN b.ZIP IS NULL THEN SUBSTR(c.PROV_LOC_ZIP,1,5) 
		ELSE ''
		END AS Zip,
		CASE
			WHEN b.State IS NOT NULL THEN b.State
			WHEN b.State IS NULL THEN c.PROV_LOC_STATE
		ELSE ''
		END AS State,
		CASE
			WHEN b.Name IS NOT NULL THEN b.Name
			WHEN b.Name IS NULL THEN c.Name
		ELSE ''
		END AS Name,
		CASE
			WHEN b.City IS NOT NULL THEN b.City
			WHEN b.City IS NULL THEN c.PROV_LOC_CITY
		ELSE ''
		END AS City,
	  d.Total_DRG, e.MED_SCHL_AFF AS MajorTeaching
	FROM WORK.Hospital_Data AS a
	LEFT JOIN WORK.Hospital_Zip AS b
	ON a.ORG_NPI_NUM=b.NPI
	LEFT JOIN IMC969SL.NPPES_&year_data AS c
	  ON a.ORG_NPI_NUM=c.NPI
	LEFT JOIN WORK.Hospital_TotalDRG AS d
	ON a.ORG_NPI_NUM=d.ORG_NPI_NUM
	LEFT JOIN PROVIDER.POS_&year_data AS e
	ON a.PRVDR_NUM=e.PROV_NUM
	WHERE a.ORG_NPI_NUM IS NOT NULL;
QUIT;
%END;
%ELSE %IF &year_data=2010 %THEN %DO;
PROC SQL;
	DROP TABLE IMC969SL.Hospital_Data_&year_data;
	CREATE TABLE IMC969SL.Hospital_Data_&year_data AS
	SELECT a.*, b.*, c.Total_DRG, d.MED_SCHL_AFF AS MajorTeaching
	FROM WORK.Hospital_Data AS a
	LEFT JOIN WORK.Hospital_Zip AS b
	ON a.ORG_NPI_NUM=b.NPI
	LEFT JOIN WORK.Hospital_TotalDRG AS c
	ON a.ORG_NPI_NUM=c.ORG_NPI_NUM
	LEFT JOIN PROVIDER.POS_&year_data AS d
	ON a.PRVDR_NUM=d.PROV_NUM
	WHERE a.ORG_NPI_NUM IS NOT NULL;
QUIT;
%END;
%ELSE %DO;
PROC SQL;
	DROP TABLE IMC969SL.Hospital_Data_&year_data;
	CREATE TABLE IMC969SL.Hospital_Data_&year_data AS
	SELECT a.*, b.*, c.Total_DRG, d.MDCL_SCHL_AFLTN_CD AS MajorTeaching
	FROM WORK.Hospital_Data AS a
	LEFT JOIN WORK.Hospital_Zip AS b
	ON a.ORG_NPI_NUM=b.NPI
	LEFT JOIN WORK.Hospital_TotalDRG AS c
	ON a.ORG_NPI_NUM=c.ORG_NPI_NUM
	LEFT JOIN PROVIDER.POS_&year_data AS d
	ON a.PRVDR_NUM=d.PRVDR_NUM
	WHERE a.ORG_NPI_NUM IS NOT NULL;
QUIT;
%END;
%mend hosp_final;

%hosp_final;


