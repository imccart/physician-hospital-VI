/* ------------------------------------------------------------ */
/* TITLE:		 Create Dataset of All Unique Patients          */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 9/18/2017										*/
/* DATE EDITED:  10/22/2018										*/
/* CODE FILE ORDER: 4 of XX										*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		Patient_Data_2007-2015									*/
/* ------------------------------------------------------------ */
%LET year_data=2015;

PROC SQL;
	DROP TABLE WORK.Patient_Data;
	CREATE TABLE WORK.Patient_Data AS
		SELECT BENE_ID, STATE_CODE, ZIP_CD, BENE_BIRTH_DT, BENE_DEATH_DT, SEX_IDENT_CD AS Gender, BENE_RACE_CD AS Race
		FROM MBSF.MBSF_ABCD_&year_data;
QUIT;


PROC SQL;
	DROP TABLE WORK.PatientSet1;
	CREATE TABLE WORK.PatientSet1 AS
		SELECT DISTINCT BENE_ID
		FROM IMC969SL.InpatientStays_&year_data
		UNION ALL
		SELECT DISTINCT BENE_ID
		FROM IMC969SL.OutpatientStays_&year_data;
QUIT;

PROC SQL;
	DROP TABLE WORK.PatientSet;
	CREATE TABLE WORK.PatientSet AS
		SELECT DISTINCT BENE_ID
		FROM WORK.PatientSet1;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.Patient_Data_&year_data;
	CREATE TABLE IMC969SL.Patient_Data_&year_data AS
		SELECT a.BENE_ID, b.*
		FROM WORK.PatientSet AS a
		LEFT JOIN WORK.Patient_Data AS b
		ON a.BENE_ID=b.BENE_ID;
QUIT;
