/* ------------------------------------------------------------ */
/* TITLE:		 Identify Hospital/Patient Zip Code Pairs       */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 9/18/2017										*/
/* DATE EDITED:  9/20/2017										*/
/* CODE FILE ORDER: Supplemental								*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following table to IMC969SL:			*/
/*		HospitalSet_&distance									*/
/* ------------------------------------------------------------ */
%LET distance=120;

/* First build "market" dataset, with all relevant zip code pairs */
PROC SQL;
	DROP TABLE WORK.UniquePatients;
	CREATE TABLE WORK.UniquePatients AS
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2007
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2008
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2009
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2010
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2011
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2012
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2013
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2014
	UNION
	SELECT DISTINCT BENE_ID, ZIP_CD AS Patient_Zip
		FROM IMC969SL.Patient_Data_2015
;
QUIT;

PROC SQL;
	DROP TABLE WORK.UniquePatient_Zips;
	CREATE TABLE WORK.UniquePatient_Zips AS
	SELECT DISTINCT Patient_Zip
		FROM WORK.UniquePatients;
QUIT;


PROC SQL;
	DROP TABLE WORK.UniqueHospitals;
	CREATE TABLE WORK.UniqueHospitals AS
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2007
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2008
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2009
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2010
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2011
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2012
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2013
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2014
		WHERE Total_Admits>=25
	UNION
	SELECT DISTINCT ORG_NPI_NUM, Zip AS Hosp_Zip
		FROM IMC969SL.Hospital_Data_2015
		WHERE Total_Admits>=25
;
QUIT;

PROC SQL;
	DROP TABLE WORK.UniqueHospital_Zips;
	CREATE TABLE WORK.UniqueHospital_Zips AS
	SELECT DISTINCT Hosp_Zip
		FROM WORK.UniqueHospitals
		WHERE Hosp_Zip IS NOT NULL;
QUIT;

PROC SQL;
	DROP TABLE WORK.HospitalSet;
	CREATE TABLE WORK.HospitalSet AS
	SELECT a.Patient_Zip, b.Hosp_Zip
		FROM WORK.UniquePatient_Zips AS a, WORK.UniqueHospital_Zips AS b;
QUIT;


/* -------------------------------------------------------------------------------------- */
/* Calculate distances from patient and hospital
/* -------------------------------------------------------------------------------------- */
DATA WORK.HospitalSet;
	SET WORK.HospitalSet;
	distance=zipcitydistance(Patient_Zip, Hosp_Zip);
RUN;

PROC SQL;
	DROP TABLE IMC969SL.HospitalSet_&distance;
	CREATE TABLE IMC969SL.HospitalSet_&distance AS
	SELECT * FROM WORK.HospitalSet
	WHERE distance<=&distance AND distance IS NOT NULL;
QUIT;



/* -------------------------------------------------------------------------------------- */
/* Form a patient's physician choice set
/* -------------------------------------------------------------------------------------- */

PROC SQL;
	DROP TABLE WORK.UniquePhysicians;
	CREATE TABLE WORK.UniquePhysicians AS
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2007
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2008
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2009
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2010
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2011
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2012
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2013
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2014
		WHERE OP_Claims>=5
	UNION
	SELECT DISTINCT Physician_NPI, 
		CASE 
			WHEN Carrier_Zip_Primary IS NOT NULL THEN Carrier_Zip_Primary
			WHEN Carrier_Zip_Primary IS NULL THEN NPPES_Zip 
		ELSE ''
		END AS Phy_Zip
		FROM IMC969SL.Physician_Data_2015
		WHERE OP_Claims>=5
;
QUIT;

PROC SQL;
	DROP TABLE WORK.UniquePhysician_Zips;
	CREATE TABLE WORK.UniquePhysician_Zips AS
	SELECT DISTINCT Phy_Zip
		FROM WORK.UniquePhysicians
		WHERE Phy_Zip IS NOT NULL;
QUIT;

PROC SQL;
	DROP TABLE WORK.PhysicianSet;
	CREATE TABLE WORK.PhysicianSet AS
	SELECT a.Patient_Zip, b.Phy_Zip
		FROM WORK.UniquePatient_Zips AS a, WORK.UniquePhysician_Zips AS b;
QUIT;


/* -------------------------------------------------------------------------------------- */
/* Calculate distances from patient and physician
/* -------------------------------------------------------------------------------------- */
%LET distance=60;
DATA WORK.PhysicianSet;
	SET WORK.PhysicianSet;
	distance=zipcitydistance(Patient_Zip, Phy_Zip);
RUN;

PROC SQL;
	DROP TABLE IMC969SL.PhysicianSet_&distance;
	CREATE TABLE IMC969SL.PhysicianSet_&distance AS
	SELECT * FROM WORK.PhysicianSet
	WHERE distance<=&distance AND distance IS NOT NULL;
QUIT;