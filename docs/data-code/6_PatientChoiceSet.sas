/* ------------------------------------------------------------ */
/* TITLE:		 Traditional Patient Choice Set	   				*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 9/18/2017										*/
/* DATE EDITED:  9/27/2017										*/
/* CODE FILE ORDER: 6 of XX										*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		Patient_Choice_2007-2015			   					*/
/* ------------------------------------------------------------ */
%LET distance=120;
%LET bigdistance=100;
%LET smalldistance=35;
%LET year_data=2015;

/* -------------------------------------------------------------------------------------- */
/* Merge zip code pairs to data on patients, then hospitals, and then observed choices
/* -------------------------------------------------------------------------------------- */
PROC SQL; 
	DROP TABLE WORK.Admitted_Patients;
	CREATE TABLE WORK.Admitted_Patients AS
	SELECT a.*
	FROM IMC969SL.Patient_Data_&year_data AS a
	LEFT JOIN (SELECT DISTINCT BENE_ID FROM 
		IMC969SL.InpatientStays_&year_data 
		WHERE OP_PHYSN_NPI IS NOT NULL) AS b
	ON a.BENE_ID=b.BENE_ID
	WHERE b.BENE_ID IS NOT NULL;
QUIT;

PROC SQL; 
	DROP TABLE IMC969SL.Supp_HospitalSet_Patients;
	CREATE TABLE IMC969SL.Supp_HospitalSet_Patients AS
	SELECT a.*, b.BENE_ID
	FROM IMC969SL.HospitalSet_&distance	AS a
	LEFT JOIN WORK.Admitted_Patients AS b
	ON a.Patient_Zip=b.ZIP_CD
	WHERE b.ZIP_CD IS NOT NULL;
QUIT;

PROC SQL; 
	DROP TABLE IMC969SL.Supp_HospitalSet_Admits;
	CREATE TABLE IMC969SL.Supp_HospitalSet_Admits AS
	SELECT a.*, b.CLM_THRU_DT, b.OP_PHYSN_NPI, b.CLM_DRG_CD
	FROM IMC969SL.Supp_HospitalSet_Patients	AS a
	LEFT JOIN (SELECT DISTINCT BENE_ID, ORG_NPI_NUM, CLM_THRU_DT, OP_PHYSN_NPI, CLM_DRG_CD
			FROM IMC969SL.InpatientStays_&year_data 
			WHERE OP_PHYSN_NPI IS NOT NULL) AS b
	ON a.BENE_ID=b.BENE_ID
	WHERE a.BENE_ID IS NOT NULL;
QUIT;


PROC SQL; 
	DROP TABLE IMC969SL.Supp_Patient_Choice;
	CREATE TABLE IMC969SL.Supp_Patient_Choice AS
	SELECT a.BENE_ID, b.ORG_NPI_NUM, a.Patient_Zip, a.Hosp_Zip, a.distance, a.CLM_THRU_DT, a.OP_PHYSN_NPI, a.CLM_DRG_CD, b.MajorTeaching
	FROM IMC969SL.Supp_HospitalSet_Admits AS a
	LEFT JOIN IMC969SL.Hospital_Data_&year_data AS b
	ON a.Hosp_Zip=b.Zip
	WHERE b.ORG_NPI_NUM IS NOT NULL
	ORDER BY a.BENE_ID, b.ORG_NPI_NUM;
QUIT;

DATA IMC969SL.Supp_Patient_Choice;
	SET IMC969SL.Supp_Patient_Choice;
	IF MajorTeaching NE 1 AND distance>&smalldistance THEN delete;
	IF MajorTeaching=1 AND distance>&bigdistance THEN delete;
RUN;


PROC SQL; 
	DROP TABLE IMC969SL.Supp_Patient_Choice_Small;
	CREATE TABLE IMC969SL.Supp_Patient_Choice_Small AS
	SELECT a.*, 
		CASE 
			WHEN b.Total_Admits=. THEN 0
			ELSE b.Total_Admits
		END AS Hospital_DRG_Admits
	FROM IMC969SL.Supp_Patient_Choice AS a
	LEFT JOIN IMC969SL.Hospital_DRG_&year_data AS b
	ON a.ORG_NPI_NUM=b.ORG_NPI_NUM AND a.CLM_DRG_CD=b.DRG
	HAVING Hospital_DRG_Admits>0
	ORDER BY a.BENE_ID, b.ORG_NPI_NUM;
QUIT;


PROC SQL; 
	DROP TABLE IMC969SL.Patient_Choice_&year_data;
	CREATE TABLE IMC969SL.Patient_Choice_&year_data AS
	SELECT a.BENE_ID, a.ORG_NPI_NUM, a.Patient_Zip, a.Hosp_Zip, a.distance, a.CLM_THRU_DT, a.OP_PHYSN_NPI, a.CLM_DRG_CD, a.Hospital_DRG_Admits,
		CASE
			WHEN a.BENE_ID=b.BENE_ID AND a.ORG_NPI_NUM=b.ORG_NPI_NUM AND a.CLM_THRU_DT=b.CLM_THRU_DT THEN 1
			ELSE 0
		END AS PatientChoice
	FROM IMC969SL.Supp_Patient_Choice_Small AS a
	LEFT JOIN (SELECT DISTINCT BENE_ID, ORG_NPI_NUM, CLM_THRU_DT
			FROM IMC969SL.InpatientStays_&year_data 
			WHERE OP_PHYSN_NPI IS NOT NULL) AS b
	ON a.BENE_ID=b.BENE_ID AND a.ORG_NPI_NUM=b.ORG_NPI_NUM AND a.CLM_THRU_DT=b.CLM_THRU_DT
	ORDER BY a.BENE_ID, a.CLM_THRU_DT, a.distance;
QUIT;


PROC SQL; 
	DROP TABLE IMC969SL.Choice_Sets_&year_data;
	CREATE TABLE IMC969SL.Choice_Sets_&year_data AS
	SELECT a.BENE_ID, a.ORG_NPI_NUM, a.Patient_Zip, a.Hosp_Zip, a.distance, a.CLM_THRU_DT, a.OP_PHYSN_NPI, a.CLM_DRG_CD, a.Hospital_DRG_Admits,
		a.PatientChoice,
		CASE
			WHEN a.ORG_NPI_NUM=b.ORG_NPI_NUM AND a.OP_PHYSN_NPI=b.OP_PHYSN_NPI THEN 1
			ELSE 0
		END AS Physician_Set
	FROM IMC969SL.Patient_Choice_&year_data AS a
	LEFT JOIN (SELECT DISTINCT ORG_NPI_NUM, OP_PHYSN_NPI
			FROM IMC969SL.InpatientStays_&year_data 
			WHERE OP_PHYSN_NPI IS NOT NULL) AS b
	ON a.ORG_NPI_NUM=b.ORG_NPI_NUM AND a.OP_PHYSN_NPI=b.OP_PHYSN_NPI
	ORDER BY a.BENE_ID, a.CLM_THRU_DT, a.distance;
QUIT;

