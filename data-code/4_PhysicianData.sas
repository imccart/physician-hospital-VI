/* ------------------------------------------------------------ */
/* TITLE:		 Create Datasets of Physician Info by Year      */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 5/12/2015										*/
/* DATE EDITED:  6/20/2024										*/
/* CODE FILE ORDER: 4 of XX										*/
/* NOTES:														*/
/*   -- File outputs the following tables to PL027710...		*/
/*		- Physician_Data_2009 - 2015:   						*/
/*		  These files contain physician-level spedning, claims, */
/*		  etc. among physicians included in the original 		*/
/*		  inpatient data (planned, elective IP stays)		    */
/*	    - HCPCS_OFFICE_2009 - 2015								*/
/*	    - HCPCS_OP_2009 - 2015									*/
/*		- HCPCS_ALL_2009 - 2015
/* ------------------------------------------------------------ */

%LET year_data=2015;

/* Operating physicians from IP stays only */
PROC SQL;
	DROP TABLE WORK.Physicians;
	CREATE TABLE WORK.Physicians AS
	SELECT DISTINCT OP_PHYSN_NPI as Physician_NPI
		FROM PL027710.INPATIENTSTAYS_&year_data 
		WHERE OP_PHYSN_NPI IS NOT NULL;
QUIT;


/* Carrier Claims */
DATA WORK.CarrierStack;
	SET	RIF&year_data..BCARRIER_LINE_01
  		RIF&year_data..BCARRIER_LINE_02
		RIF&year_data..BCARRIER_LINE_03
		RIF&year_data..BCARRIER_LINE_04
		RIF&year_data..BCARRIER_LINE_05
		RIF&year_data..BCARRIER_LINE_06
		RIF&year_data..BCARRIER_LINE_07
		RIF&year_data..BCARRIER_LINE_08
		RIF&year_data..BCARRIER_LINE_09
		RIF&year_data..BCARRIER_LINE_10
		RIF&year_data..BCARRIER_LINE_11
		RIF&year_data..BCARRIER_LINE_12;
RUN;

PROC SQL;
	DROP TABLE WORK.Carrier_Small;
	CREATE TABLE WORK.Carrier_Small AS
	SELECT a.PRF_PHYSN_NPI, a.LINE_COINSRNC_AMT, a.LINE_BENE_PTB_DDCTBL_AMT, CLM_THRU_DT, LINE_SRVC_CNT,
		a.LINE_NCH_PMT_AMT, a.LINE_BENE_PRMRY_PYR_PD_AMT, a.LINE_PLACE_OF_SRVC_CD,
		a.LINE_COINSRNC_AMT + a.LINE_BENE_PTB_DDCTBL_AMT + a.LINE_NCH_PMT_AMT + a.LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
		a.CLM_ID, a.BENE_ID, a.PRVDR_SPCLTY, a.TAX_NUM, a.PRVDR_ZIP, a.BETOS_CD, 
		a.HCPCS_CD, b.RVU
    FROM WORK.CarrierStack AS a
	LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
		ON a.HCPCS_CD=b.HCPCS
	INNER JOIN WORK.Physicians AS c
		ON a.PRF_PHYSN_NPI=c.Physician_NPI
	WHERE (PRF_PHYSN_NPI NOT IN ('9999999991','9999999992','9999999993','9999999994','9999999995','9999999996','9999999997','9999999998','9999999999'))
		AND (PRF_PHYSN_NPI IS NOT NULL);
QUIT;

/* Sum by physician and hcpcs codes, by code and place of service */
PROC SQL;
	DROP TABLE PL027710.HCPCS_ALL_&year_data;
	CREATE TABLE PL027710.HCPCS_ALL_&year_data AS
	SELECT PRF_PHYSN_NPI AS Physician_ID, count(CLM_ID) AS Carrier_Claims,
		count(distinct CLM_THRU_DT) AS Carrier_Events,
		sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
		count(distinct BENE_ID) AS Carrier_Patients, 
		sum(Carrier_Spend) AS Carrier_Spend,
		HCPCS_CD, sum(RVU) AS Carrier_RVUs, LINE_PLACE_OF_SRVC_CD AS Place
  	FROM WORK.Carrier_Small
  	WHERE PRF_PHYSN_NPI IS NOT NULL AND HCPCS_CD IS NOT NULL
  	GROUP BY PRF_PHYSN_NPI, HCPCS_CD, LINE_PLACE_OF_SRVC_CD;
QUIT;


/* Sum by physician and hcpcs codes, office setting only */
PROC SQL;
	DROP TABLE PL027710.HCPCS_Office_&year_data;
	CREATE TABLE PL027710.HCPCS_Office_&year_data AS
	SELECT PRF_PHYSN_NPI AS Physician_ID, count(CLM_ID) AS Carrier_Claims, 
		count(distinct BENE_ID) AS Carrier_Patients, 
		sum(Carrier_Spend) AS Carrier_Spend,
		count(distinct CLM_THRU_DT) AS Carrier_Events,
		sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
		HCPCS_CD, sum(RVU) AS Carrier_RVUs
  	FROM WORK.Carrier_Small
  	WHERE PRF_PHYSN_NPI IS NOT NULL AND HCPCS_CD IS NOT NULL AND LINE_PLACE_OF_SRVC_CD='11'
  	GROUP BY PRF_PHYSN_NPI, HCPCS_CD;
QUIT;


/* Sum by physician and hcpcs code, outpatient setting only */
PROC SQL;
	DROP TABLE PL027710.HCPCS_OP_&year_data;
	CREATE TABLE PL027710.HCPCS_OP_&year_data AS
	SELECT PRF_PHYSN_NPI AS Physician_ID, count(CLM_ID) AS Carrier_Claims, 
		count(distinct BENE_ID) AS Carrier_Patients, 
		sum(Carrier_Spend) AS Carrier_Spend,
		HCPCS_CD, sum(RVU) AS Carrier_RVUs,
		count(distinct CLM_THRU_DT) AS Carrier_Events,
		sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count
  	FROM WORK.Carrier_Small
  	WHERE PRF_PHYSN_NPI IS NOT NULL AND HCPCS_CD IS NOT NULL AND LINE_PLACE_OF_SRVC_CD IN ('22','24')
  	GROUP BY PRF_PHYSN_NPI, HCPCS_CD;
QUIT;


/* Sum to physician level */
PROC SQL;
	DROP TABLE WORK.Physician_Carrier;
	CREATE TABLE WORK.Physician_Carrier AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, sum(LINE_NCH_PMT_AMT) AS MC_Carrier_Spend,
		sum(Carrier_Spend) AS Carrier_Spend, sum(RVU) AS Carrier_RVUs,
		count(CLM_ID) AS Carrier_Claims, count(distinct BENE_ID) AS Carrier_Patients,
		count(distinct CLM_THRU_DT) AS Carrier_Events,
		sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count
    FROM WORK.Carrier_Small
	GROUP BY PRF_PHYSN_NPI;
QUIT;


/* Inpatient Claims */
DATA WORK.InpatientStack;
	SET	RIF&year_data..INPATIENT_CLAIMS_01
  		RIF&year_data..INPATIENT_CLAIMS_02
		RIF&year_data..INPATIENT_CLAIMS_03
		RIF&year_data..INPATIENT_CLAIMS_04
		RIF&year_data..INPATIENT_CLAIMS_05
		RIF&year_data..INPATIENT_CLAIMS_06
		RIF&year_data..INPATIENT_CLAIMS_07
		RIF&year_data..INPATIENT_CLAIMS_08
		RIF&year_data..INPATIENT_CLAIMS_09
		RIF&year_data..INPATIENT_CLAIMS_10
		RIF&year_data..INPATIENT_CLAIMS_11
		RIF&year_data..INPATIENT_CLAIMS_12;
RUN;

PROC SQL;
	DROP TABLE WORK.Inpatient_Small;
	CREATE TABLE WORK.Inpatient_Small AS
	SELECT BENE_ID, OP_PHYSN_NPI AS Physician_NPI, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, 
		  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend
	FROM WORK.InpatientStack AS a
	INNER JOIN WORK.Physicians AS b
		ON a.OP_PHYSN_NPI=b.Physician_NPI;
QUIT;


PROC SQL;
	DROP TABLE WORK.Physician_IP;
	CREATE TABLE WORK.Physician_IP AS
	SELECT Physician_NPI, count(CLM_ID) AS TotIP_Claims, 
		count(DISTINCT BENE_ID) AS IP_Patients,
		sum(CLM_PMT_AMT) AS TotIP_Mcare_Payment, 
		sum(CLM_TOT_CHRG_AMT) AS TotIP_Charge, sum(IP_Spend) AS TotIP_Spend,
		count(DISTINCT CLM_FROM_DT) AS TotIP_Admits
	FROM WORK.Inpatient_Small
	GROUP BY Physician_NPI;
QUIT;


/* Outpatient */
PROC SQL;
	DROP TABLE WORK.Physician_OP;
	CREATE TABLE WORK.Physician_OP AS
	SELECT OP_PHYSN_NPI AS Physician_NPI, count(DISTINCT BENE_ID) AS OP_Patients,
		count(CLM_ID) AS TotOP_Claims, sum(CLM_TOT_CHRG_AMT) AS TotOP_Charge, 
		sum(CLM_PMT_AMT) AS TotOP_Pay, sum(OP_Spend) AS TotOP_Spend,
		count(DISTINCT CLM_FROM_DT) AS TotOP_Admits
	FROM PL027710.OutpatientStays_&year_data AS a
	INNER JOIN WORK.Physicians AS b
		ON a.OP_PHYSN_NPI=b.Physician_NPI
	WHERE OP_PHYSN_NPI IS NOT NULL
	GROUP BY OP_PHYSN_NPI;
QUIT;


/* Find Physician Specialties */
PROC SQL;
	DROP TABLE WORK.Physician_Specialty;
	CREATE TABLE WORK.Physician_Specialty AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, PRVDR_SPCLTY AS Specialty, count(distinct CLM_ID) AS Claims	
	FROM WORK.Carrier_Small
	GROUP BY PRF_PHYSN_NPI, PRVDR_SPCLTY
	ORDER BY PRF_PHYSN_NPI, PRVDR_SPCLTY;
QUIT;


/* Find Physician Tax IDs */
PROC SQL;
	DROP TABLE WORK.Physician_TaxIDs;
	CREATE TABLE WORK.Physician_TaxIDs AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, TAX_NUM AS TaxID, count(distinct CLM_ID) AS Claims
	FROM WORK.Carrier_Small
	GROUP BY PRF_PHYSN_NPI, TAX_NUM
	ORDER BY PRF_PHYSN_NPI, TAX_NUM;
QUIT;


/* Find Physician Practice Location (based on "Evaluation and Management" billing) */
PROC SQL;
	DROP TABLE WORK.Physician_Location;
	CREATE TABLE WORK.Physician_Location AS
	SELECT PRF_PHYSN_NPI AS Physician_NPI, PRVDR_ZIP AS Zip, count(distinct CLM_ID) AS Claims
	FROM WORK.Carrier_Small
	WHERE FIRST(BETOS_CD)="M"
	GROUP BY PRF_PHYSN_NPI, PRVDR_ZIP
	ORDER BY PRF_PHYSN_NPI, PRVDR_ZIP;
QUIT;



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


/* Merge Unique Physician IDs with Inpatient, Outpatient, and Carrier Data */
/* -- Also merge with NPPES data, tax ID, and specialty data */
PROC SQL;
	DROP TABLE PL027710.Physician_Data_&year_data;
	CREATE TABLE PL027710.Physician_Data_&year_data AS 
	SELECT a.*, b.*, c.*, h.*, SUBSTR(d.Zip_1,1,5) AS Carrier_Zip_Primary,
	  SUBSTR(d.Zip_2,1,5) AS Carrier_Zip_Secondary,
	  e.Specialty_1 AS Primary_Specialty, e.Specialty_2 AS Secondary_Specialty, 
	  f.TaxID_1 AS Primary_TaxID, f.TaxID_2 AS Secondary_TaxID,
	  g.Entity_Type_Code AS NPPES_EntityCode, g.Credent AS NPPES_Cred, SUBSTR(g.PROV_LOC_ZIP,1,5) AS NPPES_Zip,
      g.PROV_LOC_STATE AS NPPES_State, g.PROV_LOC_CITY AS NPPES_City, g.Specialty_HPTC AS NPPES_HPTC,
	  g.UPDATE_DATE AS NPPES_Update
	FROM WORK.Physicians AS a
	LEFT JOIN WORK.Physician_Carrier AS b
	  ON a.Physician_NPI=b.Physician_NPI
	LEFT JOIN WORK.Physician_IP AS c
	  ON a.Physician_NPI=c.Physician_NPI
	LEFT JOIN WORK.Physician_OP AS h
	  ON a.Physician_NPI=h.Physician_NPI
	LEFT JOIN WORK.Physician_Location_Claims AS d
	  ON a.Physician_NPI=d.Physician_NPI
	LEFT JOIN WORK.Physician_Specialty_Claims AS e
	  ON a.Physician_NPI=e.Physician_NPI
	LEFT JOIN WORK.Physician_TaxID_Claims AS f
	  ON a.Physician_NPI=f.Physician_NPI
	LEFT JOIN PL027710.NPPES_&year_data AS g
	  ON a.Physician_NPI=g.NPI
	ORDER BY Physician_NPI;
QUIT;


