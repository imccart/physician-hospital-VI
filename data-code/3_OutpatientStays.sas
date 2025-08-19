/* ------------------------------------------------------------ */
/* TITLE:		 Collect outpatient claims data 				*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 2/20/2017										*/
/* DATE EDITED:  2/13/2024										*/
/* CODE FILE ORDER: 3 of XX  									*/
/* NOTES:														*/
/*   -- File outputs the following tables to PL027710:			*/
/*		OutpatientStays_2009-2015 (for all patients)   			*/
/*		AllOPClaims_2009-2015 (for elective IP patients only) */
/* ------------------------------------------------------------ */


%macro process_op_data;
	%do year_data=2009 %to 2015;

	/* Create Table of Outpatient Stays */
	DATA WORK.OutpatientStays;
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

	DATA WORK.OutpatientHCPCS;
		SET	RIF&year_data..OUTPATIENT_REVENUE_01
	  		RIF&year_data..OUTPATIENT_REVENUE_02
			RIF&year_data..OUTPATIENT_REVENUE_03
			RIF&year_data..OUTPATIENT_REVENUE_04
			RIF&year_data..OUTPATIENT_REVENUE_05
			RIF&year_data..OUTPATIENT_REVENUE_06
			RIF&year_data..OUTPATIENT_REVENUE_07
			RIF&year_data..OUTPATIENT_REVENUE_08
			RIF&year_data..OUTPATIENT_REVENUE_09
			RIF&year_data..OUTPATIENT_REVENUE_10
			RIF&year_data..OUTPATIENT_REVENUE_11
			RIF&year_data..OUTPATIENT_REVENUE_12;
	RUN;

	PROC SQL;
		DROP TABLE WORK.HCPCS;
		CREATE TABLE WORK.HCPCS AS
		SELECT DISTINCT BENE_ID, CLM_ID, HCPCS_CD
		FROM WORK.OutpatientHCPCS
		WHERE HCPCS_CD IS NOT NULL;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.HCPCS_OP_&year_data;
		CREATE TABLE PL027710.HCPCS_OP_&year_data AS
		SELECT HCPCS_CD, Count(CLM_ID) AS OP_Count, &year_data AS Year
		FROM WORK.HCPCS
		GROUP BY HCPCS_CD;
	QUIT;


	PROC TRANSPOSE data=WORK.HCPCS out=WORK.ReshapeHCPCS
		(drop=_NAME_ _LABEL_) prefix=Code;
		var HCPCS_CD;
		by BENE_ID CLM_ID;
	RUN;


	PROC SQL;
		DROP TABLE PL027710.OutpatientStays_&year_data;
		CREATE TABLE PL027710.OutpatientStays_&year_data AS
		SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, 
			a.ORG_NPI_NUM, a.OP_PHYSN_NPI,
			a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT, 
			a.CLM_PMT_AMT + a.NCH_PRMRY_PYR_CLM_PD_AMT + a.NCH_BENE_PTB_DDCTBL_AMT + a.NCH_BENE_PTB_COINSRNC_AMT AS OP_Spend,
			a.PRNCPAL_DGNS_CD, a.ICD_DGNS_CD1, a.ICD_DGNS_CD2, a.ICD_DGNS_CD3, a.ICD_DGNS_CD4, a.ICD_DGNS_CD5, 
			a.ICD_DGNS_CD6, a.ICD_DGNS_CD7, a.ICD_DGNS_CD8, a.ICD_DGNS_CD9, a.ICD_DGNS_CD10,
			a.ICD_PRCDR_CD1, a.ICD_PRCDR_CD2, b.CODE1, b.CODE2, b.CODE3, b.CODE4, b.CODE5, b.CODE6, 
			b.CODE7, b.CODE8, b.CODE9, b.CODE10 
		FROM WORK.OutpatientStays AS a
		LEFT JOIN WORK.ReshapeHCPCS AS b
			ON a.CLM_ID=b.CLM_ID AND a.BENE_ID=b.BENE_ID;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.IP_Patients;
		CREATE TABLE WORK.IP_Patients AS
		SELECT DISTINCT BENE_ID, CLM_ADMSN_DT AS Initial_Admit, NCH_BENE_DSCHRG_DT AS Initial_Discharge
		FROM PL027710.INPATIENTSTAYS_&year_data;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.AllOPClaims_&year_data;
		CREATE TABLE PL027710.AllOPClaims_&year_data AS
		SELECT a.*, b.Initial_Admit, b.Initial_Discharge
		FROM PL027710.OutpatientStays_&year_data AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID;
	QUIT;

	%END;

%mend process_op_data;

%process_op_data;


