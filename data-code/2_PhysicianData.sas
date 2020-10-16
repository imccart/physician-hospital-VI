/* ------------------------------------------------------------ */
/* TITLE:		 Create Dataset of All Unique Physician IDs     */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 5/12/2015										*/
/* DATE EDITED:  9/25/2017										*/
/* CODE FILE ORDER: 2 of XX										*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		Physician_Data_2007 - 2015  						    */
/* ------------------------------------------------------------ */

%LET year_data=2015;
%LET carrier_year_data=K15_R6723;
/* KXX_R6723 applies to 2007, 2008, 2012-2015 */

/*
%LET year_data=2011;
%LET carrier_year_data=J11_R4585; */
/* JXX_R4585 applies to 2009, 2010, 2011 (original data request) */

/* Physicians in Outpatient Office Claims Data (Carrier File) */
%macro phy_data;
%IF &year_data=2007 OR &year_data=2008 %THEN %DO;
PROC SQL;
	DROP TABLE WORK.Carrier_Full;
	CREATE TABLE WORK.Carrier_Full AS
	SELECT CASE 
			WHEN a.PRF_PHYSN_NPI NE '' AND a.PRF_PHYSN_NPI NE '0000000000' THEN a.PRF_PHYSN_NPI
			WHEN a.PRF_PHYSN_NPI='' OR a.PRF_PHYSN_NPI='0000000000' THEN b.NPI
		ELSE ''
		END AS Physician_NPI, a.CLM_ID, a.BENE_ID, a.PRVDR_SPCLTY, a.TAX_NUM, a.PRVDR_ZIP, a.BETOS_CD
    FROM IN027710.BCARLINE&carrier_year_data AS a
	LEFT JOIN IMC969SL.UPIN_NPI_Merge_&year_data AS b
		ON a.PRF_PHYSN_UPIN=b.OP_PHYSN_UPIN;
QUIT;

PROC SQL;
	DROP TABLE WORK.Physician_Carrier;
	CREATE TABLE WORK.Physician_Carrier AS
	SELECT Physician_NPI, count(distinct CLM_ID) AS Carrier_Claims, count(distinct BENE_ID) AS Carrier_Patients
    FROM WORK.Carrier_Full
	WHERE Physician_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND Physician_NPI IS NOT NULL
	GROUP BY Physician_NPI;
QUIT;

/* Find Physician Specialties */
PROC SQL;
	DROP TABLE WORK.Physician_Specialty;
	CREATE TABLE WORK.Physician_Specialty AS
	SELECT Physician_NPI, PRVDR_SPCLTY AS Specialty, count(distinct CLM_ID) AS Claims
	FROM WORK.Carrier_Full
	WHERE Physician_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND Physician_NPI IS NOT NULL
	GROUP BY Physician_NPI, PRVDR_SPCLTY
	ORDER BY Physician_NPI, PRVDR_SPCLTY;
QUIT;

/* Find Physician Tax IDs */
PROC SQL;
	DROP TABLE WORK.Physician_TaxIDs;
	CREATE TABLE WORK.Physician_TaxIDs AS
	SELECT Physician_NPI, TAX_NUM AS TaxID, count(distinct CLM_ID) AS Claims
	FROM WORK.Carrier_Full
	WHERE Physician_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND Physician_NPI IS NOT NULL
	GROUP BY Physician_NPI, TAX_NUM
	ORDER BY Physician_NPI, TAX_NUM;
QUIT;


/* Find Physician Practice Location (based on "Evaluation and Management" billing) */
PROC SQL;
	DROP TABLE WORK.Physician_Location;
	CREATE TABLE WORK.Physician_Location AS
	SELECT Physician_NPI, PRVDR_ZIP AS Zip, count(distinct CLM_ID) AS Claims
	FROM WORK.Carrier_Full
	WHERE Physician_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND Physician_NPI IS NOT NULL 
		AND (FIRST(BETOS_CD)="M")
	GROUP BY Physician_NPI, PRVDR_ZIP
	ORDER BY Physician_NPI, PRVDR_ZIP;
QUIT;

%END;
%ELSE %DO;
PROC SQL;
	DROP TABLE WORK.Physician_Carrier;
	CREATE TABLE WORK.Physician_Carrier AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI,
		count(distinct CLM_ID) AS Carrier_Claims, count(distinct BENE_ID) AS Carrier_Patients
    FROM IN027710.BCARLINE&carrier_year_data
	WHERE PRF_PHYSN_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND PRF_PHYSN_NPI IS NOT NULL
	GROUP BY PRF_PHYSN_NPI;
QUIT;

/* Find Physician Specialties */
PROC SQL;
	DROP TABLE WORK.Physician_Specialty;
	CREATE TABLE WORK.Physician_Specialty AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, PRVDR_SPCLTY AS Specialty, count(distinct CLM_ID) AS Claims
	FROM IN027710.BCARLINE&carrier_year_data
	WHERE PRF_PHYSN_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND PRF_PHYSN_NPI IS NOT NULL
	GROUP BY PRF_PHYSN_NPI, PRVDR_SPCLTY
	ORDER BY PRF_PHYSN_NPI, PRVDR_SPCLTY;
QUIT;

/* Find Physician Tax IDs */
PROC SQL;
	DROP TABLE WORK.Physician_TaxIDs;
	CREATE TABLE WORK.Physician_TaxIDs AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, TAX_NUM AS TaxID, count(distinct CLM_ID) AS Claims
	FROM IN027710.BCARLINE&carrier_year_data
	WHERE PRF_PHYSN_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND PRF_PHYSN_NPI IS NOT NULL
	GROUP BY PRF_PHYSN_NPI, TAX_NUM
	ORDER BY PRF_PHYSN_NPI, TAX_NUM;
QUIT;


/* Find Physician Practice Location (based on "Evaluation and Management" billing) */
PROC SQL;
	DROP TABLE WORK.Physician_Location;
	CREATE TABLE WORK.Physician_Location AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, PRVDR_ZIP AS Zip, count(distinct CLM_ID) AS Claims
	FROM IN027710.BCARLINE&carrier_year_data
	WHERE PRF_PHYSN_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999')
		AND PRF_PHYSN_NPI IS NOT NULL 
		AND (FIRST(BETOS_CD)="M")
	GROUP BY PRF_PHYSN_NPI, PRVDR_ZIP
	ORDER BY PRF_PHYSN_NPI, PRVDR_ZIP;
QUIT;

%END;
%mend phy_data;


/* Run physician macro */
%phy_data;


/* Create "wide" data for physician specialties */
PROC SORT DATA=WORK.Physician_Specialty OUT=WORK.Physician_Specialty;
	BY Physician_NPI DESCENDING Claims;
RUN;

DATA WORK.Physician_Specialty;
SET WORK.Physician_Specialty;
	BY Physician_NPI;
	IF first.Physician_NPI THEN n=1;
	ELSE n+1;
RUN;

%MACRO temp_wide(varname,prefix);
PROC TRANSPOSE DATA=WORK.Physician_Specialty
	OUT=WORK.Wide_Phy_&varname PREFIX=&prefix;
	BY Physician_NPI;
	ID n;
VAR &varname;
RUN;

%MEND temp_wide;
%temp_wide(Specialty, Specialty_);
%temp_wide(Claims, Claims_);

DATA WORK.Physician_Specialty_Claims;
SET WORK.Physician_Specialty;
	MERGE WORK.Wide_Phy_Specialty (drop=_name_)
		  WORK.Wide_Phy_Claims (drop=_name_);
RUN;


/* Create "wide" data for physician tax IDs */
PROC SORT DATA=WORK.Physician_TaxIDs OUT=WORK.Physician_TaxIDs;
	BY Physician_NPI DESCENDING Claims;
RUN;

DATA WORK.Physician_TaxIDs;
SET WORK.Physician_TaxIDs;
	BY Physician_NPI;
	IF first.Physician_NPI THEN n=1;
	ELSE n+1;
RUN;

%MACRO temp_wide(varname,prefix);
PROC TRANSPOSE DATA=WORK.Physician_TaxIDs
	OUT=WORK.Wide_Phy_&varname PREFIX=&prefix;
	BY Physician_NPI;
	ID n;
VAR &varname;
RUN;

%MEND temp_wide;
%temp_wide(TaxID, TaxID_);
%temp_wide(Claims, Claims_);

DATA WORK.Physician_TaxID_Claims;
SET WORK.Physician_TaxIDs;
	MERGE WORK.Wide_Phy_TaxID (drop=_name_)
		  WORK.Wide_Phy_Claims (drop=_name_);
RUN;


/* Create "wide" data for physician location (zip code) */
PROC SORT DATA=WORK.Physician_Location OUT=WORK.Physician_Location;
	BY Physician_NPI DESCENDING Claims;
RUN;

DATA WORK.Physician_Location;
SET WORK.Physician_Location;
	BY Physician_NPI;
	IF first.Physician_NPI THEN n=1;
	ELSE n+1;
RUN;

%MACRO temp_wide(varname,prefix);
PROC TRANSPOSE DATA=WORK.Physician_Location
	OUT=WORK.Wide_Phy_&varname PREFIX=&prefix;
	BY Physician_NPI;
	ID n;
VAR &varname;
RUN;

%MEND temp_wide;
%temp_wide(Zip, Zip_);
%temp_wide(Claims, Claims_);

DATA WORK.Physician_Location_Claims;
SET WORK.Physician_Location;
	MERGE WORK.Wide_Phy_Zip (drop=_name_)
		  WORK.Wide_Phy_Claims (drop=_name_);
RUN;



/* Operating and Attending Physicians in Inpatient Institutional Claims Data */
/* -- Operating physicians only (not worried about attending physicians) */

PROC SQL;
	DROP TABLE WORK.OP_Physician_Inpatient;
	CREATE TABLE WORK.OP_Physician_Inpatient AS
	SELECT OP_PHYSN_NPI AS Physician_NPI, count(distinct CLM_ID) AS OP_Inpatient_Claims, count(distinct BENE_ID) AS OP_Inpatient_Patients, 
        count(distinct ORG_NPI_NUM) AS OP_Inpatient_Facilities
    FROM IMC969SL.InpatientStays_&year_data
	GROUP BY OP_PHYSN_NPI;
QUIT;

DATA WORK.Physician_Inpatient_All;
	SET WORK.OP_Physician_Inpatient;
	ARRAY vars OP_Inpatient_Claims OP_Inpatient_Patients OP_Inpatient_Facilities;
	DO OVER vars;
	IF vars=. THEN vars=0;
	END;
RUN;

PROC SQL;
	DROP TABLE WORK.Physician_Inpatient;
	CREATE TABLE WORK.Physician_Inpatient AS
	SELECT Physician_NPI, sum(OP_Inpatient_Claims) AS OP_Claims, sum(OP_Inpatient_Patients) AS OP_Patients,
		sum(OP_Inpatient_Facilities) AS OP_Facilities
	FROM WORK.Physician_Inpatient_All
	WHERE Physician_NPI IS NOT NULL
	GROUP BY Physician_NPI
	ORDER BY Physician_NPI;
QUIT;

/* Append Physician Inpatient and Carrier Data */
DATA WORK.Physician_Append;
	SET WORK.Physician_Carrier
		WORK.Physician_Inpatient;
RUN;


/* Extract Unique Physician IDs from Full Physician Dataset */
PROC SQL;
	DROP TABLE WORK.Physicians;
	CREATE TABLE WORK.Physicians AS
	SELECT DISTINCT Physician_NPI
	FROM WORK.Physician_Append
	ORDER BY Physician_NPI;
QUIT;


/* Merge Unique Physician IDs with Inpatient and Carrier Data */
/* -- Also merge with NPPES data, tax ID, and specialty data */
PROC SQL;
	DROP TABLE IMC969SL.Physician_Data_&year_data;
	CREATE TABLE IMC969SL.Physician_Data_&year_data AS 
	SELECT a.*, b.*, c.*, SUBSTR(d.Zip_1,1,5) AS Carrier_Zip_Primary,
	  SUBSTR(d.Zip_2,1,5) AS Carrier_Zip_Secondary,
	  e.Specialty_1 AS Primary_Specialty, e.Specialty_2 AS Secondary_Specialty, 
	  f.TaxID_1 AS Primary_TaxID, f.TaxID_2 AS Secondary_TaxID,
	  g.Entity_Type_Code AS NPPES_EntityCode, g.Credent AS NPPES_Cred, SUBSTR(g.PROV_LOC_ZIP,1,5) AS NPPES_Zip,
      g.PROV_LOC_STATE AS NPPES_State, g.PROV_LOC_CITY AS NPPES_City, g.Specialty_HPTC AS NPPES_HPTC,
	  g.UPDATE_DATE AS NPPES_Update
	FROM WORK.Physicians AS a
	LEFT JOIN WORK.Physician_Carrier AS b
	  ON a.Physician_NPI=b.Physician_NPI
	LEFT JOIN WORK.Physician_Inpatient AS c
	  ON a.Physician_NPI=c.Physician_NPI
	LEFT JOIN WORK.Physician_Location_Claims AS d
	  ON a.Physician_NPI=d.Physician_NPI
	LEFT JOIN WORK.Physician_Specialty_Claims AS e
	  ON a.Physician_NPI=e.Physician_NPI
	LEFT JOIN WORK.Physician_TaxID_Claims AS f
	  ON a.Physician_NPI=f.Physician_NPI
	LEFT JOIN IMC969SL.NPPES_&year_data AS g
	  ON a.Physician_NPI=g.NPI
	ORDER BY Physician_NPI;
QUIT;
