/* ------------------------------------------------------------ */
/* TITLE:		 Create Dataset of All Unique Hospitals         */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 5/12/2015										*/
/* DATE EDITED:  2/8/2024										*/
/* CODE FILE ORDER: 3 of XX										*/
/* NOTES:														*/
/*   -- File outputs the following tables to PL027710:			*/
/*		Hospital_Data_2009-2015									*/
/* ------------------------------------------------------------ */

%LET year_data=2015;

/* Create Tables for Aggregate Stays, Charges, Payments by Hospital */
PROC SQL;
	DROP TABLE PL027710.Hospital_DRG_&year_data;
	CREATE TABLE PL027710.Hospital_DRG_&year_data AS
	SELECT ORG_NPI_NUM, CLM_DRG_CD AS DRG, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients, sum(CLM_PMT_AMT) AS Total_McarePymt, sum(CLM_TOT_CHRG_AMT) AS Total_Charges,
		sum(Inpatient_Spend) AS Total_Spend
	FROM PL027710.InpatientStays_&year_data
	GROUP BY ORG_NPI_NUM, CLM_DRG_CD;
QUIT;

PROC SQL;
	DROP TABLE WORK.Hospital_Data;
	CREATE TABLE WORK.Hospital_Data AS
	SELECT ORG_NPI_NUM, max(PRVDR_NUM) AS PRVDR_NUM, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients, sum(CLM_PMT_AMT) AS Total_McarePymt, sum(CLM_TOT_CHRG_AMT) AS Total_Charges,
		sum(Inpatient_Spend) AS Total_Spend
	FROM PL027710.InpatientStays_&year_data
	WHERE ORG_NPI_NUM IS NOT NULL
	GROUP BY ORG_NPI_NUM;
QUIT;


/* Table of NPI and Provider Numbers (to match with zip code data in earlier years) */
PROC SQL;
	DROP TABLE WORK.Hospital_Zip;
	CREATE TABLE WORK.Hospital_Zip AS
	SELECT NPI, SUBSTR(PROV_LOC_ZIP,1,5) AS Zip, PROV_LOC_STATE AS State, PROV_LOC_CITY AS City, Name
	FROM PL027710.NPPES_&year_data;
QUIT;


PROC SQL;
	DROP TABLE WORK.Hospital_DRGWeight;
	CREATE TABLE WORK.Hospital_DRGWeight AS
	SELECT a.ORG_NPI_NUM, a.DRG, a.Total_Admits, b.drgweight, a.Total_Admits*b.drgweight AS Total_DRG,
		a.Total_McarePymt, a.Total_Charges, a.Total_Spend
	FROM PL027710.Hospital_DRG_&year_data AS a
	LEFT JOIN (SELECT * FROM PL027710.DRG_Weights WHERE fyear=&year_data) AS b
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

%IF &year_data<2011 %THEN %DO;
PROC SQL;
	DROP TABLE PL027710.Hospital_Data_&year_data;
	CREATE TABLE PL027710.Hospital_Data_&year_data AS
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
	LEFT JOIN PL027710.NPPES_&year_data AS c
	  ON a.ORG_NPI_NUM=c.NPI
	LEFT JOIN WORK.Hospital_TotalDRG AS d
	ON a.ORG_NPI_NUM=d.ORG_NPI_NUM
	LEFT JOIN PROVIDER.POS_&year_data AS e
	ON a.PRVDR_NUM=e.PROV_NUM
	WHERE a.ORG_NPI_NUM IS NOT NULL;
QUIT;
%END;

%ELSE %DO;
PROC SQL;
	DROP TABLE PL027710.Hospital_Data_&year_data;
	CREATE TABLE PL027710.Hospital_Data_&year_data AS
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
	  d.Total_DRG, e.MDCL_SCHL_AFLTN_CD AS MajorTeaching
	FROM WORK.Hospital_Data AS a
	LEFT JOIN WORK.Hospital_Zip AS b
	ON a.ORG_NPI_NUM=b.NPI
	LEFT JOIN PL027710.NPPES_&year_data AS c
	  ON a.ORG_NPI_NUM=c.NPI
	LEFT JOIN WORK.Hospital_TotalDRG AS d
	ON a.ORG_NPI_NUM=d.ORG_NPI_NUM
	LEFT JOIN PROVIDER.POS_&year_data AS e
	ON a.PRVDR_NUM=e.PRVDR_NUM
	WHERE a.ORG_NPI_NUM IS NOT NULL;
QUIT;
