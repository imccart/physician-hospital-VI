/* ------------------------------------------------------------ */
/* TITLE:		 Create Dataset of All Unique Patients          */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 9/18/2017										*/
/* DATE EDITED:  2/8/2024										*/
/* CODE FILE ORDER: 4 of XX										*/
/* NOTES:														*/
/*   -- If using 2009, be sure to replace RVU_&year_data with   */
/*      RVU_2010 since 2009 data are missing                    */
/*   -- File outputs the following tables to PL027710:			*/
/*		Patient_Data_2009-2015									*/
/* ------------------------------------------------------------ */

/* Create table of unique BENE_IDs from 20% sample files */
PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2009;
	CREATE TABLE PL027710.Bene_20percent_2009 AS
	SELECT DISTINCT BENE_ID, 2009 as Year
	FROM IN027710.BCARCLMSJ09_R4585;
QUIT;

PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2010;
	CREATE TABLE PL027710.Bene_20percent_2010 AS
	SELECT DISTINCT BENE_ID, 2010 as Year
	FROM IN027710.BCARCLMSJ10_R4585;
QUIT;

PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2011;
	CREATE TABLE PL027710.Bene_20percent_2011 AS
	SELECT DISTINCT BENE_ID, 2011 as Year
	FROM IN027710.BCARCLMSJ11_R4585;
QUIT;

PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2012;
	CREATE TABLE PL027710.Bene_20percent_2012 AS
	SELECT DISTINCT BENE_ID, 2012 as Year
	FROM IN027710.BCARCLMSK12_R6723;
QUIT;

PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2013;
	CREATE TABLE PL027710.Bene_20percent_2013 AS
	SELECT DISTINCT BENE_ID, 2013 as Year
	FROM IN027710.BCARCLMSK13_R6723;
QUIT;

PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2014;
	CREATE TABLE PL027710.Bene_20percent_2014 AS
	SELECT DISTINCT BENE_ID, 2014 as Year
	FROM IN027710.BCARCLMSK14_R6723;
QUIT;

PROC SQL;
	DROP TABLE PL027710.Bene_20percent_2015;
	CREATE TABLE PL027710.Bene_20percent_2015 AS
	SELECT DISTINCT BENE_ID, 2015 as Year
	FROM IN027710.BCARCLMSK15_R6723;
QUIT;

%macro process_bene_set;
	%do year_data=2009 %to 2015;
	PROC SQL;
		DROP TABLE WORK.PatientSet_&year_data;
		CREATE TABLE WORK.PatientSet_&year_data AS
			SELECT DISTINCT BENE_ID
			FROM PL027710.InpatientStays_&year_data;
	QUIT;
	%END;
%mend process_bene_set;

%process_bene_set;

DATA WORK.PatientSet_Full;
	SET	WORK.PatientSet_2009
  		WORK.PatientSet_2010
		WORK.PatientSet_2011
		WORK.PatientSet_2012
		WORK.PatientSet_2013
		WORK.PatientSet_2014
		WORK.PatientSet_2015;
RUN;

PROC SQL;
	DROP TABLE WORK.PatientSet;
	CREATE TABLE WORK.PatientSet AS
		SELECT DISTINCT BENE_ID
		FROM WORK.PatientSet_Full;
QUIT;



%macro process_bene_data;
	%do year_data=2009 %to 2015;

	/* Create Tables of Inpatient, Outpatient, and Carrier Claims for 2009 */
/*	DATA WORK.InpatientStack;
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

	DATA WORK.OutpatientStack;
		SET	RIF&year_data..OUTPATIENT_CLAIMS_01
	  		RIF&year_data..OUTPATIENT_CLAIMS_02
			RIF&year_data..OUTPATIENT_CLAIMS_03
			RIF&year_data..OUTPATIENT_CLAIMS_04
			RIF&year_data..OUTPATIENT_CLAIMS_05
			RIF&year_data..OUTPATIENT_CLAIMS_06
			RIF&year_data..OUTPATIENT_CLAIMS_07
			RIF&year_data..OUTPATIENT_CLAIMS_08
			RIF&year_data..OUTPATIENT_CLAIMS_09
			RIF&year_data..OUTPATIENT_CLAIMS_10
			RIF&year_data..OUTPATIENT_CLAIMS_11
			RIF&year_data..OUTPATIENT_CLAIMS_12;
	RUN;

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
		DROP TABLE WORK.IPSmall;
		CREATE TABLE WORK.IPSmall AS
		SELECT BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, 
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend
		FROM WORK.InpatientStack;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.TotalBENE_IP;
		CREATE TABLE WORK.TotalBENE_IP AS
		SELECT BENE_ID, count(CLM_ID) AS TotIP_Claims, sum(CLM_PMT_AMT) AS TotIP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS TotIP_Charge, sum(IP_Spend) AS TotIP_Spend
		FROM WORK.IPSmall
		GROUP BY BENE_ID;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.OPSmall;
		CREATE TABLE WORK.OPSmall AS
		SELECT BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, 
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_BENE_PTB_DDCTBL_AMT + NCH_BENE_PTB_COINSRNC_AMT AS OP_Spend
		FROM WORK.OutpatientStack;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.TotalBENE_OP;
		CREATE TABLE WORK.TotalBENE_OP AS
		SELECT BENE_ID, count(CLM_ID) AS TotOP_Claims, sum(CLM_PMT_AMT) AS TotOP_Mcare_Payment, sum(CLM_TOT_CHRG_AMT) AS TotOP_Charge,
			sum(OP_Spend) AS TotOP_Spend
		FROM WORK.OPSmall
		GROUP BY BENE_ID;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierSmall;
		CREATE TABLE WORK.CarrierSmall AS
		SELECT PRF_PHYSN_NPI, LINE_COINSRNC_AMT, LINE_BENE_PTB_DDCTBL_AMT,
			LINE_NCH_PMT_AMT, LINE_BENE_PRMRY_PYR_PD_AMT, LINE_SBMTD_CHRG_AMT,
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			CLM_ID, BENE_ID, HCPCS_CD, RVU
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.TotalBENE_Carrier;
		CREATE TABLE WORK.TotalBENE_Carrier AS
		SELECT BENE_ID, count(CLM_ID) AS TotCarrier_Claims, sum(LINE_NCH_PMT_AMT) AS TotCarrier_Mcare_Payment, 
			sum(LINE_SBMTD_CHRG_AMT) AS TotCarrier_Charge,
			sum(Carrier_Spend) AS TotCarrier_Spend, sum(RVU) AS TotCarrier_RVU
	    FROM WORK.CarrierSmall
		GROUP BY BENE_ID;
	QUIT;


	PROC SQL;
		DROP TABLE PL027710.Patient_Data_&year_data;
		CREATE TABLE PL027710.Patient_Data_&year_data AS
			SELECT a.BENE_ID, a.STATE_CODE, a.ZIP_CD, a.BENE_BIRTH_DT, a.BENE_DEATH_DT, a.SEX_IDENT_CD AS Gender, a.BENE_RACE_CD AS Race,
				b.*, c.*, d.*
			FROM MBSF.MBSF_ABCD_&year_data AS a
		LEFT JOIN WORK.TotalBENE_IP AS b
			ON a.BENE_ID=b.BENE_ID
		LEFT JOIN WORK.TotalBENE_OP AS c
			ON a.BENE_ID=c.BENE_ID
		LEFT JOIN WORK.TotalBENE_Carrier AS d
			ON a.BENE_ID=d.BENE_ID;
	QUIT;

*/

	PROC SQL;
		DROP TABLE PL027710.IP_Patient_Data_&year_data;
		CREATE TABLE PL027710.IP_Patient_Data_&year_data AS
			SELECT a.BENE_ID, b.*
			FROM WORK.PatientSet AS a
			LEFT JOIN PL027710.Patient_Data_&year_data AS b
			ON a.BENE_ID=b.BENE_ID;
	QUIT;

	%END;
%mend process_bene_data;

%process_bene_data;
