/* ------------------------------------------------------------ */
/* TITLE:		 Incoroporate Medpar Data for IP Stays  		*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 11/12/2018										*/
/* DATE EDITED:  11/25/2018										*/
/* CODE FILE ORDER: 11 of XX  									*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		Medpare_2007-2015  								*/
/* ------------------------------------------------------------ */
%LET year_data=2015;

/* Find final set of patients */
PROC SQL;
	DROP TABLE WORK.Patients;
	CREATE TABLE WORK.Patients AS
	SELECT DISTINCT BENE_ID, CLM_FROM_DT, ORG_NPI_NUM
		FROM IMC969SL.INPATIENTSTAYS_&year_data 
		WHERE ORG_NPI_NUM IS NOT NULL AND OP_PHYSN_NPI IS NOT NULL;
QUIT;


/* Pull Medpar data for each patient */
PROC SQL;
	DROP TABLE WORK.Medpar_&year_data;
	CREATE TABLE WORK.Medpar_&year_data AS
	SELECT BENE_ID, ADMSN_DT, ORG_NPI_NUM, PRVT_ROOM_DAY_CNT AS Private_Days, SEMIPRVT_ROOM_DAY_CNT AS SemiPrivate_Days,
		INTNSV_CARE_DAY_CNT AS ICU_Days, PHRMCY_CHRG_AMT AS Pharm_Charge, MDCL_SUPLY_CHRG_AMT AS MedicalSupply_Charge,
		PHYS_THRPY_CHRG_AMT AS PhyTherapy_Charge, BLOOD_ADMIN_CHRG_AMT AS BloodAdmin_Charge, 
		OPRTG_ROOM_CHRG_AMT AS OperatingRoom_Charge, ANSTHSA_CHRG_AMT AS Anesthesia_Charge, 
		LAB_CHRG_AMT AS Lab_Charge, RDLGY_CHRG_AMT AS Radiology_Charge, MRI_CHRG_AMT AS MRI_Charge,
		RDLGY_DGNSTC_IND_SW AS Radiology_Diag, RDLGY_CT_SCAN_IND_SW AS Radiology_CT, 
		SRGCL_PRCDR_CD_CNT AS Procedure_Count, CARE_IMPRVMT_MODEL_1_CD AS PFP_1,
		CARE_IMPRVMT_MODEL_2_CD AS PFP_2, CARE_IMPRVMT_MODEL_3_CD AS PFP_3, CARE_IMPRVMT_MODEL_4_CD AS PFP_4,
		VBP_PRTCPNT_IND_CD AS VBP_Ind, VBP_ADJSTMT_PCT AS VBP_Percent, BNDLD_MODEL_DSCNT_PCT AS BundledPayment_Percent,
		HRR_PRTCPNT_IND_CD AS HRR_Ind, HRR_ADJSTMT_PCT AS HRR_Percent
	FROM MEDPAR.MEDPAR_&year_data;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.Medpar_&year_data;
	CREATE TABLE IMC969SL.Medpar_&year_data AS
	SELECT a.*
		FROM WORK.Medpar_&year_data AS a
		INNER JOIN WORK.Patients AS b
		ON a.BENE_ID=b.BENE_ID AND a.ADMSN_DT=b.CLM_FROM_DT AND a.ORG_NPI_NUM=b.ORG_NPI_NUM;
QUIT;