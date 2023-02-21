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

%macro distance_data;
%do j = 2007 %to 2015;
%LET year_data=&j;
/* Create table of physician/DRG totals */
PROC SQL;
	DROP TABLE IMC969SL.Physician_DRG_&year_data;
	CREATE TABLE IMC969SL.Physician_DRG_&year_data AS
	SELECT OP_PHYSN_NPI, CLM_DRG_CD AS DRG, count(distinct CLM_ID) AS Total_Admits,
		count(distinct BENE_ID) AS Total_Patients
	FROM IMC969SL.InpatientStays_&year_data
	WHERE OP_PHYSN_NPI IS NOT NULL
	GROUP BY OP_PHYSN_NPI, CLM_DRG_CD;
QUIT;

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


%do i = 10 %to 30 %by 10;
%LET max_distance=&i;
%LET min_distance=&i-10;
PROC SQL; 
	DROP TABLE WORK.Supp_PhySet_Patients;
	CREATE TABLE WORK.Supp_PhySet_Patients AS
	SELECT a.*, b.BENE_ID
	FROM IMC969SL.PhysicianSet_60 AS a
	LEFT JOIN WORK.Admitted_Patients AS b
	ON a.Patient_Zip=b.ZIP_CD
	WHERE b.ZIP_CD IS NOT NULL
		AND a.distance<&max_distance
		AND a.distance>=&min_distance;
QUIT;

PROC SQL; 
	DROP TABLE WORK.Supp_PhySet_Admits;
	CREATE TABLE WORK.Supp_PhySet_Admits AS
	SELECT a.*, b.CLM_THRU_DT, b.OP_PHYSN_NPI, b.CLM_DRG_CD, &max_distance AS Distance_Type
	FROM WORK.Supp_PhySet_Patients AS a
	LEFT JOIN (SELECT DISTINCT BENE_ID, CLM_THRU_DT, OP_PHYSN_NPI, CLM_DRG_CD
			FROM IMC969SL.InpatientStays_&year_data 
			WHERE OP_PHYSN_NPI IS NOT NULL) AS b
	ON a.BENE_ID=b.BENE_ID
	WHERE a.BENE_ID IS NOT NULL;
QUIT;

PROC SQL; 
	DROP TABLE WORK.Supp_PatientPhy_Choice;
	CREATE TABLE WORK.Supp_PatientPhy_Choice AS
	SELECT a.BENE_ID, b.Physician_NPI, a.Patient_Zip, a.Phy_Zip, a.distance, a.CLM_THRU_DT, a.OP_PHYSN_NPI, a.CLM_DRG_CD, a.Distance_Type
	FROM WORK.Supp_PhySet_Admits AS a
	LEFT JOIN 
		(SELECT DISTINCT Physician_NPI, Phy_Zip
		FROM IMC969SL.Physician_Choice_&year_data
		WHERE Physician_NPI IS NOT NULL) AS b
	ON a.Phy_Zip=b.Phy_Zip
	WHERE a.OP_PHYSN_NPI IS NOT NULL
	ORDER BY a.BENE_ID, a.OP_PHYSN_NPI;
QUIT;

PROC SQL; 
	DROP TABLE WORK.Supp_PatientPhy_Choice2;
	CREATE TABLE WORK.Supp_PatientPhy_Choice2 AS
	SELECT a.*, 
		CASE 
			WHEN b.Total_Admits=. THEN 0
			ELSE b.Total_Admits
		END AS Physician_DRG_Admits
	FROM WORK.Supp_PatientPhy_Choice AS a
	LEFT JOIN IMC969SL.Physician_DRG_&year_data AS b
	ON a.Physician_NPI=b.OP_PHYSN_NPI AND a.CLM_DRG_CD=b.DRG
	HAVING Physician_DRG_Admits>0
	ORDER BY a.BENE_ID, b.OP_PHYSN_NPI;
QUIT;


PROC SQL; 
	DROP TABLE WORK.Patient_PhysicianChoice_&max_distance;
	CREATE TABLE WORK.Patient_PhysicianChoice_&max_distance AS
	SELECT a.BENE_ID, a.Physician_NPI, a.Patient_Zip, a.Phy_Zip, a.distance, a.CLM_THRU_DT, a.CLM_DRG_CD, a.Physician_DRG_Admits,
		CASE
			WHEN a.BENE_ID=b.BENE_ID AND a.Physician_NPI=b.OP_PHYSN_NPI AND a.CLM_THRU_DT=b.CLM_THRU_DT THEN 1
			ELSE 0
		END AS PatientChoice
	FROM WORK.Supp_PatientPhy_Choice2 AS a
	LEFT JOIN (SELECT DISTINCT BENE_ID, OP_PHYSN_NPI, CLM_THRU_DT
			FROM IMC969SL.InpatientStays_&year_data 
			WHERE OP_PHYSN_NPI IS NOT NULL) AS b
	ON a.BENE_ID=b.BENE_ID AND a.OP_PHYSN_NPI=b.OP_PHYSN_NPI AND a.CLM_THRU_DT=b.CLM_THRU_DT
	ORDER BY a.BENE_ID, a.CLM_THRU_DT, a.distance;
QUIT;

%end;

DATA IMC969SL.Patient_PhysicianChoice_&year_data;
	SET	WORK.Patient_PhysicianChoice_10
  		WORK.Patient_PhysicianChoice_20
		WORK.Patient_PhysicianChoice_30;
RUN;
%end;
%mend distance_data;

%distance_data



