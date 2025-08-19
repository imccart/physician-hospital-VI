/* ------------------------------------------------------------ */
/* TITLE:		 All inpatient claims among identified elective */
/*				 inpatient stay patients						*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 2/20/2017										*/
/* DATE EDITED:  2/12/2024										*/
/* CODE FILE ORDER: 2 of XX  									*/
/* NOTES:														*/
/*   -- File outputs the following tables to PL027710:			*/
/*		AllIPClaims_2009-2015  									*/
/* ------------------------------------------------------------ */

%macro process_allip_data;
	%do year_data=2009 %to 2015;


	DATA WORK.InpatientClaims_&year_data;
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
		DROP TABLE WORK.IP_Patients;
		CREATE TABLE WORK.IP_Patients AS
		SELECT DISTINCT BENE_ID, CLM_ADMSN_DT AS Initial_Admit, NCH_BENE_DSCHRG_DT AS Initial_Discharge, 
			Inpatient_Spend AS Initial_Spend
		FROM PL027710.INPATIENTSTAYS_&year_data;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.AllIPClaims_&year_data;
		CREATE TABLE PL027710.AllIPClaims_&year_data AS
		SELECT a.BENE_ID, a.CLM_ID, a.CLM_DRG_CD, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD, a.CLM_SRC_IP_ADMSN_CD,
			a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT, a.CLM_ADMSN_DT AS Admit, a.NCH_BENE_DSCHRG_DT AS Discharge,
			a.CLM_PMT_AMT + a.NCH_PRMRY_PYR_CLM_PD_AMT + a.NCH_IP_TOT_DDCTN_AMT AS Inpatient_Spend,
			b.Initial_Admit, b.Initial_Discharge, b.Initial_Spend
		FROM WORK.InpatientClaims_&year_data AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID;
	QUIT;

	%END;

%mend process_allip_data;

%process_allip_data;
