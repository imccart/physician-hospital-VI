/* ------------------------------------------------------------ */
/* TITLE:		 Episode Spending	        			        */
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 1/22/2016										*/
/* DATE EDITED:  2/17/2024										*/
/* CODE FILE ORDER: 8 of XXX									*/
/* NOTES:														*/
/*   -- File outputs the following tables to PL027710:			*/
/*		Episodes_2009-2015										*/
/* ------------------------------------------------------------ */

%macro process_episode_data;
	%do year_data=2012 %to 2014;
	%LET year_pre=%eval(&year_data-1);
	%LET year_post=%eval(&year_data+1);



	PROC SQL;
		DROP TABLE WORK.IP_Patients;
		CREATE TABLE WORK.IP_Patients AS
		SELECT DISTINCT BENE_ID, CLM_ADMSN_DT AS Initial_Admit, NCH_BENE_DSCHRG_DT AS Initial_Discharge,
			CLM_ID AS Initial_ID, CLM_PMT_AMT AS Initial_Mcare_Spend,
			CLM_TOT_CHRG_AMT AS Initial_Mcare_Charge, Inpatient_Spend AS Initial_IP_Spend
		FROM PL027710.INPATIENTSTAYS_&year_data;
	QUIT;


	/* Inpatient facility claims */
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
			RIF&year_data..INPATIENT_CLAIMS_12
			RIF&year_post..INPATIENT_CLAIMS_01
			RIF&year_post..INPATIENT_CLAIMS_02
			RIF&year_post..INPATIENT_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.IPSmall;
		CREATE TABLE WORK.IPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend,
			  CLM_THRU_DT-CLM_FROM_DT AS LOS, OP_PHYSN_NPI,
			  b.Initial_Admit, b.Initial_Discharge, b.Initial_ID
		FROM WORK.InpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.IPEpisode;
		CREATE TABLE WORK.IPEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_FROM_DT) AS IP_Admits, count(DISTINCT OP_PHYSN_NPI) AS IP_Physicians,
			count(CLM_ID) AS IP_Claims, sum(CLM_PMT_AMT) AS IP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS IP_Charge, sum(IP_Spend) AS IP_Spend, sum(LOS) AS IP_LOS,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.IP_Physicians_&year_data;
		CREATE TABLE PL027710.IP_Physicians_&year_data AS
		SELECT OP_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_FROM_DT) AS IP_Admits,
			count(CLM_ID) AS IP_Claims, sum(CLM_PMT_AMT) AS IP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS IP_Charge, sum(IP_Spend) AS IP_Spend, sum(LOS) AS IP_LOS,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		GROUP BY OP_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	/* Outpatient facility claims */
	DATA WORK.OutpatientStack;
		SET	RIF&year_pre..OUTPATIENT_CLAIMS_12
			RIF&year_data..OUTPATIENT_CLAIMS_01
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
			RIF&year_data..OUTPATIENT_CLAIMS_12
			RIF&year_post..OUTPATIENT_CLAIMS_01
			RIF&year_post..OUTPATIENT_CLAIMS_02
			RIF&year_post..OUTPATIENT_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.OPSmall;
		CREATE TABLE WORK.OPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT, OP_PHYSN_NPI,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_BENE_PTB_DDCTBL_AMT + NCH_BENE_PTB_COINSRNC_AMT AS OP_Spend,
			  Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OutpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Admit-30 AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.OPEpisode;
		CREATE TABLE WORK.OPEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_FROM_DT) AS OP_Events, count(DISTINCT OP_PHYSN_NPI) AS OP_Physicians,
			count(CLM_ID) AS OP_Claims, sum(CLM_PMT_AMT) AS OP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS OP_Charge, sum(OP_Spend) AS OP_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OPSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.OP_Physicians_&year_data;
		CREATE TABLE PL027710.OP_Physicians_&year_data AS
		SELECT OP_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_FROM_DT) AS OP_Events,
			count(CLM_ID) AS OP_Claims, sum(CLM_PMT_AMT) AS OP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS OP_Charge, sum(OP_Spend) AS OP_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OPSmall
		GROUP BY OP_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	/* Carrier Claims */
	DATA WORK.CarrierStack;
		SET	RIF&year_pre..BCARRIER_LINE_12
			RIF&year_data..BCARRIER_LINE_01
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
			RIF&year_data..BCARRIER_LINE_12
			RIF&year_post..BCARRIER_LINE_01
			RIF&year_post..BCARRIER_LINE_02
			RIF&year_post..BCARRIER_LINE_03;
	RUN;


	PROC SQL;
		DROP TABLE WORK.CarrierSmall;
		CREATE TABLE WORK.CarrierSmall AS
		SELECT a.BENE_ID, CLM_ID, LINE_NCH_PMT_AMT, LINE_SBMTD_CHRG_AMT, CLM_THRU_DT, NCH_CLM_TYPE_CD, PRF_PHYSN_NPI, LINE_SRVC_CNT, LINE_PLACE_OF_SRVC_CD,
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			HCPCS_CD, RVU, BETOS_CD, Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS
		INNER JOIN WORK.IP_Patients AS c
			ON a.BENE_ID=c.BENE_ID
		WHERE CLM_THRU_DT>=Initial_Admit-30 AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.CarrierIP;
		CREATE TABLE WORK.CarrierIP AS
		SELECT a.BENE_ID, CLM_ID, LINE_NCH_PMT_AMT, LINE_SBMTD_CHRG_AMT, CLM_THRU_DT, NCH_CLM_TYPE_CD, PRF_PHYSN_NPI, LINE_SRVC_CNT,
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			HCPCS_CD, RVU, BETOS_CD, Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS
		INNER JOIN WORK.IP_Patients AS c
			ON a.BENE_ID=c.BENE_ID
		WHERE CLM_THRU_DT>=Initial_Admit AND CLM_THRU_DT<=Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Imaging;
		CREATE TABLE WORK.Imaging AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS Imaging_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS Imaging_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Imaging_MCare_Payment,
			sum(LINE_SRVC_CNT) AS Imaging_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Imaging_Charge,
			sum(Carrier_Spend) AS Imaging_Spend,
			count(DISTINCT CLM_THRU_DT) AS Imaging_Events,
			sum(RVU) AS Imaging_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE SUBSTR(BETOS_CD,1,1)="I")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.EM;
		CREATE TABLE WORK.EM AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS EM_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS EM_Physicians,
			sum(LINE_NCH_PMT_AMT) AS EM_MCare_Payment,
			sum(LINE_SRVC_CNT) AS EM_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS EM_Charge,
			sum(Carrier_Spend) AS EM_Spend,
			count(DISTINCT CLM_THRU_DT) AS EM_Events,
			sum(RVU) AS EM_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE SUBSTR(BETOS_CD,1,1)="M")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Lab;
		CREATE TABLE WORK.Lab AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS Lab_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS Lab_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Lab_MCare_Payment,
			sum(LINE_SRVC_CNT) AS Lab_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Lab_Charge,
			sum(Carrier_Spend) AS Lab_Spend,
			count(DISTINCT CLM_THRU_DT) AS Lab_Events,
			sum(RVU) AS Lab_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE (SUBSTR(BETOS_CD,1,1)="T") AND
			(NCH_CLM_TYPE_CD IN ("71", "72")))
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierEpisode;
		CREATE TABLE WORK.CarrierEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.Carrier_PlaceOfService_&year_data;
		CREATE TABLE PL027710.Carrier_PlaceOfService_&year_data AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU, LINE_PLACE_OF_SRVC_CD,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY BENE_ID, LINE_PLACE_OF_SRVC_CD, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.Carrier_Physicians_&year_data;
		CREATE TABLE PL027710.Carrier_Physicians_&year_data AS
		SELECT PRF_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY PRF_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierEpisode_IP;
		CREATE TABLE WORK.CarrierEpisode_IP AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS IP_Carrier_Events,
			count(CLM_ID) AS IP_Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS IP_Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS IP_Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS IP_Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS IP_Carrier_Charge, sum(Carrier_Spend) AS IP_Carrier_Spend,
			sum(RVU) AS IP_Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierIP
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	/* home health claims */
	DATA WORK.HHA;
		SET	RIF&year_data..HHA_CLAIMS_01
	  		RIF&year_data..HHA_CLAIMS_02
			RIF&year_data..HHA_CLAIMS_03
			RIF&year_data..HHA_CLAIMS_04
			RIF&year_data..HHA_CLAIMS_05
			RIF&year_data..HHA_CLAIMS_06
			RIF&year_data..HHA_CLAIMS_07
			RIF&year_data..HHA_CLAIMS_08
			RIF&year_data..HHA_CLAIMS_09
			RIF&year_data..HHA_CLAIMS_10
			RIF&year_data..HHA_CLAIMS_11
			RIF&year_data..HHA_CLAIMS_12
			RIF&year_post..HHA_CLAIMS_01
			RIF&year_post..HHA_CLAIMS_02
			RIF&year_post..HHA_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.HHASmall;
		CREATE TABLE WORK.HHASmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT AS HHA_Spend, AT_PHYSN_NPI, OP_PHYSN_NPI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHA AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.HHAEpisode;
		CREATE TABLE WORK.HHAEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS HHA_Events, count(DISTINCT AT_PHYSN_NPI) AS HHA_Physicians,
			count(CLM_ID) AS HHA_Claims, sum(CLM_PMT_AMT) AS HHA_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS HHA_Charge, sum(HHA_Spend) AS HHA_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHASmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.HHA_Physicians_&year_data;
		CREATE TABLE PL027710.HHA_Physicians_&year_data AS
		SELECT AT_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS HHA_Events,
			count(CLM_ID) AS HHA_Claims, sum(CLM_PMT_AMT) AS HHA_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS HHA_Charge, sum(HHA_Spend) AS HHA_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHASmall
		GROUP BY AT_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	/* snf claims */
	DATA WORK.SNF;
		SET	RIF&year_data..SNF_CLAIMS_01
	  		RIF&year_data..SNF_CLAIMS_02
			RIF&year_data..SNF_CLAIMS_03
			RIF&year_data..SNF_CLAIMS_04
			RIF&year_data..SNF_CLAIMS_05
			RIF&year_data..SNF_CLAIMS_06
			RIF&year_data..SNF_CLAIMS_07
			RIF&year_data..SNF_CLAIMS_08
			RIF&year_data..SNF_CLAIMS_09
			RIF&year_data..SNF_CLAIMS_10
			RIF&year_data..SNF_CLAIMS_11
			RIF&year_data..SNF_CLAIMS_12
			RIF&year_post..SNF_CLAIMS_01
			RIF&year_post..SNF_CLAIMS_02
			RIF&year_post..SNF_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.SNFSmall;
		CREATE TABLE WORK.SNFSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS SNF_Spend, AT_PHYSN_NPI, OP_PHYSN_NPI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNF AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.SNFEpisode;
		CREATE TABLE WORK.SNFEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS SNF_Events, count(DISTINCT AT_PHYSN_NPI) AS SNF_Physicians,
			count(CLM_ID) AS SNF_Claims, sum(CLM_PMT_AMT) AS SNF_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS SNF_Charge, sum(SNF_Spend) AS SNF_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNFSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.SNF_Physicians_&year_data;
		CREATE TABLE PL027710.SNF_Physicians_&year_data AS
		SELECT AT_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS SNF_Events,
			count(CLM_ID) AS SNF_Claims, sum(CLM_PMT_AMT) AS SNF_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS SNF_Charge, sum(SNF_Spend) AS SNF_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNFSmall
		GROUP BY AT_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	/* merge into one episode claims dataset */
	PROC SQL;
		DROP TABLE PL027710.Episodes_&year_data;
		CREATE TABLE PL027710.Episodes_&year_data AS
		SELECT a.*, b.*, c.*, d.*, e.*, f.*, g.*, h.*, i.*, j.*
			FROM WORK.IP_Patients AS a
		LEFT JOIN WORK.IPEpisode AS b
			ON a.BENE_ID=b.BENE_ID AND a.Initial_ID=b.Initial_ID
			AND a.Initial_Admit=b.Initial_Admit AND a.Initial_Discharge=b.Initial_Discharge			
		LEFT JOIN WORK.OPEpisode AS c
			ON a.BENE_ID=c.BENE_ID AND a.Initial_ID=c.Initial_ID
			AND a.Initial_Admit=c.Initial_Admit AND a.Initial_Discharge=c.Initial_Discharge
		LEFT JOIN WORK.CarrierEpisode AS d
			ON a.BENE_ID=d.BENE_ID AND a.Initial_ID=d.Initial_ID
			AND a.Initial_Admit=d.Initial_Admit AND a.Initial_Discharge=d.Initial_Discharge
		LEFT JOIN WORK.Imaging AS e
			ON a.BENE_ID=e.BENE_ID AND a.Initial_ID=e.Initial_ID
			AND a.Initial_Admit=e.Initial_Admit AND a.Initial_Discharge=e.Initial_Discharge
		LEFT JOIN WORK.EM AS f
			ON a.BENE_ID=f.BENE_ID AND a.Initial_ID=f.Initial_ID
			AND a.Initial_Admit=f.Initial_Admit AND a.Initial_Discharge=f.Initial_Discharge
		LEFT JOIN WORK.Lab AS g
			ON a.BENE_ID=g.BENE_ID AND a.Initial_ID=g.Initial_ID
			AND a.Initial_Admit=g.Initial_Admit AND a.Initial_Discharge=g.Initial_Discharge
		LEFT JOIN WORK.CarrierEpisode_IP AS h
			ON a.BENE_ID=h.BENE_ID AND a.Initial_ID=h.Initial_ID
			AND a.Initial_Admit=h.Initial_Admit AND a.Initial_Discharge=h.Initial_Discharge
		LEFT JOIN WORK.HHAEpisode AS i
			ON a.BENE_ID=i.BENE_ID AND a.Initial_ID=i.Initial_ID
			AND a.Initial_Admit=i.Initial_Admit AND a.Initial_Discharge=i.Initial_Discharge
		LEFT JOIN WORK.SNFEpisode AS j
			ON a.BENE_ID=j.BENE_ID AND a.Initial_ID=j.Initial_ID
			AND a.Initial_Admit=j.Initial_Admit AND a.Initial_Discharge=j.Initial_Discharge;
	QUIT;
	%END;

%mend process_episode_data;

%process_episode_data;




/* ********************************************************* */
/* 2009 Only */
/* ********************************************************* */
%LET year_data=2009;
%LET year_post=%eval(&year_data+1);


	/* Initial Inpatient Stays */
	PROC SQL;
		DROP TABLE WORK.IP_Patients;
		CREATE TABLE WORK.IP_Patients AS
		SELECT DISTINCT BENE_ID, CLM_ADMSN_DT AS Initial_Admit, NCH_BENE_DSCHRG_DT AS Initial_Discharge,
			CLM_ID AS Initial_ID, CLM_PMT_AMT AS Initial_Mcare_Spend,
			CLM_TOT_CHRG_AMT AS Initial_Mcare_Charge, Inpatient_Spend AS Initial_IP_Spend
		FROM PL027710.INPATIENTSTAYS_&year_data;
	QUIT;

	/* inpatient claims */
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
			RIF&year_data..INPATIENT_CLAIMS_12
			RIF&year_post..INPATIENT_CLAIMS_01
			RIF&year_post..INPATIENT_CLAIMS_02
			RIF&year_post..INPATIENT_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.IPSmall;
		CREATE TABLE WORK.IPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend,
			  CLM_THRU_DT-CLM_FROM_DT AS LOS, OP_PHYSN_NPI,
			  b.Initial_Admit, b.Initial_Discharge, b.Initial_ID
		FROM WORK.InpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.IPEpisode;
		CREATE TABLE WORK.IPEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_FROM_DT) AS IP_Admits, count(DISTINCT OP_PHYSN_NPI) AS IP_Physicians,
			count(CLM_ID) AS IP_Claims, sum(CLM_PMT_AMT) AS IP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS IP_Charge, sum(IP_Spend) AS IP_Spend, sum(LOS) AS IP_LOS,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.IP_Physicians_&year_data;
		CREATE TABLE PL027710.IP_Physicians_&year_data AS
		SELECT OP_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_FROM_DT) AS IP_Admits,
			count(CLM_ID) AS IP_Claims, sum(CLM_PMT_AMT) AS IP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS IP_Charge, sum(IP_Spend) AS IP_Spend, sum(LOS) AS IP_LOS,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		GROUP BY OP_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	/* outpatient claims */
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
			RIF&year_data..OUTPATIENT_CLAIMS_12
			RIF&year_post..OUTPATIENT_CLAIMS_01
			RIF&year_post..OUTPATIENT_CLAIMS_02
			RIF&year_post..OUTPATIENT_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.OPSmall;
		CREATE TABLE WORK.OPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT, OP_PHYSN_NPI,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_BENE_PTB_DDCTBL_AMT + NCH_BENE_PTB_COINSRNC_AMT AS OP_Spend,
			  Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OutpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Admit-30 AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.OPEpisode;
		CREATE TABLE WORK.OPEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_FROM_DT) AS OP_Events, count(DISTINCT OP_PHYSN_NPI) AS OP_Physicians,
			count(CLM_ID) AS OP_Claims, sum(CLM_PMT_AMT) AS OP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS OP_Charge, sum(OP_Spend) AS OP_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OPSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.OP_Physicians_&year_data;
		CREATE TABLE PL027710.OP_Physicians_&year_data AS
		SELECT OP_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_FROM_DT) AS OP_Events,
			count(CLM_ID) AS OP_Claims, sum(CLM_PMT_AMT) AS OP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS OP_Charge, sum(OP_Spend) AS OP_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OPSmall
		GROUP BY OP_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	/* carrier claims */
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
			RIF&year_data..BCARRIER_LINE_12
			RIF&year_post..BCARRIER_LINE_01
			RIF&year_post..BCARRIER_LINE_02
			RIF&year_post..BCARRIER_LINE_03;
	RUN;


	PROC SQL;
		DROP TABLE WORK.CarrierSmall;
		CREATE TABLE WORK.CarrierSmall AS
		SELECT a.BENE_ID, CLM_ID, LINE_NCH_PMT_AMT, LINE_SBMTD_CHRG_AMT, CLM_THRU_DT, NCH_CLM_TYPE_CD, PRF_PHYSN_NPI, 
			LINE_SRVC_CNT, LINE_PLACE_OF_SRVC_CD,
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			HCPCS_CD, RVU, BETOS_CD, Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS
		INNER JOIN WORK.IP_Patients AS c
			ON a.BENE_ID=c.BENE_ID
		WHERE CLM_THRU_DT>=Initial_Admit-30 AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierIP;
		CREATE TABLE WORK.CarrierIP AS
		SELECT a.BENE_ID, CLM_ID, LINE_NCH_PMT_AMT, LINE_SBMTD_CHRG_AMT, CLM_THRU_DT, NCH_CLM_TYPE_CD, PRF_PHYSN_NPI, LINE_SRVC_CNT,
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			HCPCS_CD, RVU, BETOS_CD, Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS
		INNER JOIN WORK.IP_Patients AS c
			ON a.BENE_ID=c.BENE_ID
		WHERE CLM_THRU_DT>=Initial_Admit AND CLM_THRU_DT<=Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Imaging;
		CREATE TABLE WORK.Imaging AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS Imaging_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS Imaging_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Imaging_MCare_Payment,
			sum(LINE_SRVC_CNT) AS Imaging_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Imaging_Charge,
			sum(Carrier_Spend) AS Imaging_Spend,
			count(DISTINCT CLM_THRU_DT) AS Imaging_Events,
			sum(RVU) AS Imaging_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE SUBSTR(BETOS_CD,1,1)="I")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.EM;
		CREATE TABLE WORK.EM AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS EM_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS EM_Physicians,
			sum(LINE_NCH_PMT_AMT) AS EM_MCare_Payment,
			sum(LINE_SRVC_CNT) AS EM_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS EM_Charge,
			sum(Carrier_Spend) AS EM_Spend,
			count(DISTINCT CLM_THRU_DT) AS EM_Events,
			sum(RVU) AS EM_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE SUBSTR(BETOS_CD,1,1)="M")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Lab;
		CREATE TABLE WORK.Lab AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS Lab_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS Lab_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Lab_MCare_Payment,
			sum(LINE_SRVC_CNT) AS Lab_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Lab_Charge,
			sum(Carrier_Spend) AS Lab_Spend,
			count(DISTINCT CLM_THRU_DT) AS Lab_Events,
			sum(RVU) AS Lab_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE (SUBSTR(BETOS_CD,1,1)="T") AND
			(NCH_CLM_TYPE_CD IN ("71", "72")))
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierEpisode;
		CREATE TABLE WORK.CarrierEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.Carrier_PlaceOfService_&year_data;
		CREATE TABLE PL027710.Carrier_PlaceOfService_&year_data AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU, LINE_PLACE_OF_SRVC_CD,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY BENE_ID, LINE_PLACE_OF_SRVC_CD, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.Carrier_Physicians_&year_data;
		CREATE TABLE PL027710.Carrier_Physicians_&year_data AS
		SELECT PRF_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY PRF_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierEpisode_IP;
		CREATE TABLE WORK.CarrierEpisode_IP AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS IP_Carrier_Events,
			count(CLM_ID) AS IP_Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS IP_Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS IP_Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS IP_Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS IP_Carrier_Charge, sum(Carrier_Spend) AS IP_Carrier_Spend,
			sum(RVU) AS IP_Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierIP
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	DATA WORK.HHA;
		SET	RIF&year_data..HHA_CLAIMS_01
	  		RIF&year_data..HHA_CLAIMS_02
			RIF&year_data..HHA_CLAIMS_03
			RIF&year_data..HHA_CLAIMS_04
			RIF&year_data..HHA_CLAIMS_05
			RIF&year_data..HHA_CLAIMS_06
			RIF&year_data..HHA_CLAIMS_07
			RIF&year_data..HHA_CLAIMS_08
			RIF&year_data..HHA_CLAIMS_09
			RIF&year_data..HHA_CLAIMS_10
			RIF&year_data..HHA_CLAIMS_11
			RIF&year_data..HHA_CLAIMS_12
			RIF&year_post..HHA_CLAIMS_01
			RIF&year_post..HHA_CLAIMS_02
			RIF&year_post..HHA_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.HHASmall;
		CREATE TABLE WORK.HHASmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT AS HHA_Spend, AT_PHYSN_NPI, OP_PHYSN_NPI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHA AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.HHAEpisode;
		CREATE TABLE WORK.HHAEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS HHA_Events, count(DISTINCT AT_PHYSN_NPI) AS HHA_Physicians,
			count(CLM_ID) AS HHA_Claims, sum(CLM_PMT_AMT) AS HHA_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS HHA_Charge, sum(HHA_Spend) AS HHA_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHASmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.HHA_Physicians_&year_data;
		CREATE TABLE PL027710.HHA_Physicians_&year_data AS
		SELECT AT_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS HHA_Events,
			count(CLM_ID) AS HHA_Claims, sum(CLM_PMT_AMT) AS HHA_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS HHA_Charge, sum(HHA_Spend) AS HHA_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHASmall
		GROUP BY AT_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	DATA WORK.SNF;
		SET	RIF&year_data..SNF_CLAIMS_01
	  		RIF&year_data..SNF_CLAIMS_02
			RIF&year_data..SNF_CLAIMS_03
			RIF&year_data..SNF_CLAIMS_04
			RIF&year_data..SNF_CLAIMS_05
			RIF&year_data..SNF_CLAIMS_06
			RIF&year_data..SNF_CLAIMS_07
			RIF&year_data..SNF_CLAIMS_08
			RIF&year_data..SNF_CLAIMS_09
			RIF&year_data..SNF_CLAIMS_10
			RIF&year_data..SNF_CLAIMS_11
			RIF&year_data..SNF_CLAIMS_12
			RIF&year_post..SNF_CLAIMS_01
			RIF&year_post..SNF_CLAIMS_02
			RIF&year_post..SNF_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.SNFSmall;
		CREATE TABLE WORK.SNFSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS SNF_Spend, AT_PHYSN_NPI, OP_PHYSN_NPI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNF AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.SNFEpisode;
		CREATE TABLE WORK.SNFEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS SNF_Events, count(DISTINCT AT_PHYSN_NPI) AS SNF_Physicians,
			count(CLM_ID) AS SNF_Claims, sum(CLM_PMT_AMT) AS SNF_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS SNF_Charge, sum(SNF_Spend) AS SNF_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNFSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.SNF_Physicians_&year_data;
		CREATE TABLE PL027710.SNF_Physicians_&year_data AS
		SELECT AT_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS SNF_Events,
			count(CLM_ID) AS SNF_Claims, sum(CLM_PMT_AMT) AS SNF_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS SNF_Charge, sum(SNF_Spend) AS SNF_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNFSmall
		GROUP BY AT_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE PL027710.Episodes_&year_data;
		CREATE TABLE PL027710.Episodes_&year_data AS
		SELECT a.*, b.*, c.*, d.*, e.*, f.*, g.*, h.*, i.*, j.*
			FROM WORK.IP_Patients AS a
		LEFT JOIN WORK.IPEpisode AS b
			ON a.BENE_ID=b.BENE_ID AND a.Initial_ID=b.Initial_ID
			AND a.Initial_Admit=b.Initial_Admit AND a.Initial_Discharge=b.Initial_Discharge			
		LEFT JOIN WORK.OPEpisode AS c
			ON a.BENE_ID=c.BENE_ID AND a.Initial_ID=c.Initial_ID
			AND a.Initial_Admit=c.Initial_Admit AND a.Initial_Discharge=c.Initial_Discharge
		LEFT JOIN WORK.CarrierEpisode AS d
			ON a.BENE_ID=d.BENE_ID AND a.Initial_ID=d.Initial_ID
			AND a.Initial_Admit=d.Initial_Admit AND a.Initial_Discharge=d.Initial_Discharge
		LEFT JOIN WORK.Imaging AS e
			ON a.BENE_ID=e.BENE_ID AND a.Initial_ID=e.Initial_ID
			AND a.Initial_Admit=e.Initial_Admit AND a.Initial_Discharge=e.Initial_Discharge
		LEFT JOIN WORK.EM AS f
			ON a.BENE_ID=f.BENE_ID AND a.Initial_ID=f.Initial_ID
			AND a.Initial_Admit=f.Initial_Admit AND a.Initial_Discharge=f.Initial_Discharge
		LEFT JOIN WORK.Lab AS g
			ON a.BENE_ID=g.BENE_ID AND a.Initial_ID=g.Initial_ID
			AND a.Initial_Admit=g.Initial_Admit AND a.Initial_Discharge=g.Initial_Discharge
		LEFT JOIN WORK.CarrierEpisode_IP AS h
			ON a.BENE_ID=h.BENE_ID AND a.Initial_ID=h.Initial_ID
			AND a.Initial_Admit=h.Initial_Admit AND a.Initial_Discharge=h.Initial_Discharge
		LEFT JOIN WORK.HHAEpisode AS i
			ON a.BENE_ID=i.BENE_ID AND a.Initial_ID=i.Initial_ID
			AND a.Initial_Admit=i.Initial_Admit AND a.Initial_Discharge=i.Initial_Discharge
		LEFT JOIN WORK.SNFEpisode AS j
			ON a.BENE_ID=j.BENE_ID AND a.Initial_ID=j.Initial_ID
			AND a.Initial_Admit=j.Initial_Admit AND a.Initial_Discharge=j.Initial_Discharge;
	QUIT;


/* ********************************************************* */
/* 2015 Only */
/* ********************************************************* */
%LET year_data=2015;
%LET year_pre=%eval(&year_data-1);


	/* Initial Inpatient Stays */
	PROC SQL;
		DROP TABLE WORK.IP_Patients;
		CREATE TABLE WORK.IP_Patients AS
		SELECT DISTINCT BENE_ID, CLM_ADMSN_DT AS Initial_Admit, NCH_BENE_DSCHRG_DT AS Initial_Discharge,
			CLM_ID AS Initial_ID, CLM_PMT_AMT AS Initial_Mcare_Spend,
			CLM_TOT_CHRG_AMT AS Initial_Mcare_Charge, Inpatient_Spend AS Initial_IP_Spend
		FROM PL027710.INPATIENTSTAYS_&year_data;
	QUIT;


	/* Collect Episode Inpatient Claims */
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
		DROP TABLE WORK.IPSmall;
		CREATE TABLE WORK.IPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend,
			  CLM_THRU_DT-CLM_FROM_DT AS LOS, OP_PHYSN_NPI,
			  b.Initial_Admit, b.Initial_Discharge, b.Initial_ID
		FROM WORK.InpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.IPEpisode;
		CREATE TABLE WORK.IPEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_FROM_DT) AS IP_Admits, count(DISTINCT OP_PHYSN_NPI) AS IP_Physicians,
			count(CLM_ID) AS IP_Claims, sum(CLM_PMT_AMT) AS IP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS IP_Charge, sum(IP_Spend) AS IP_Spend, sum(LOS) AS IP_LOS,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.IP_Physicians_&year_data;
		CREATE TABLE PL027710.IP_Physicians_&year_data AS
		SELECT OP_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_FROM_DT) AS IP_Admits,
			count(CLM_ID) AS IP_Claims, sum(CLM_PMT_AMT) AS IP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS IP_Charge, sum(IP_Spend) AS IP_Spend, sum(LOS) AS IP_LOS,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		GROUP BY OP_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;



	/* Collect Episode Outpatient Claims */
	DATA WORK.OutpatientStack;
		SET	RIF&year_pre..OUTPATIENT_CLAIMS_12
			RIF&year_data..OUTPATIENT_CLAIMS_01
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

	PROC SQL;
		DROP TABLE WORK.OPSmall;
		CREATE TABLE WORK.OPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT, OP_PHYSN_NPI,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_BENE_PTB_DDCTBL_AMT + NCH_BENE_PTB_COINSRNC_AMT AS OP_Spend,
			  Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OutpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Admit-30 AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.OPEpisode;
		CREATE TABLE WORK.OPEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_FROM_DT) AS OP_Events, count(DISTINCT OP_PHYSN_NPI) AS OP_Physicians,
			count(CLM_ID) AS OP_Claims, sum(CLM_PMT_AMT) AS OP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS OP_Charge, sum(OP_Spend) AS OP_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OPSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.OP_Physicians_&year_data;
		CREATE TABLE PL027710.OP_Physicians_&year_data AS
		SELECT OP_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_FROM_DT) AS OP_Events,
			count(CLM_ID) AS OP_Claims, sum(CLM_PMT_AMT) AS OP_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS OP_Charge, sum(OP_Spend) AS OP_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.OPSmall
		GROUP BY OP_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	/* Carrier Claims */
	DATA WORK.CarrierStack;
		SET	RIF&year_pre..BCARRIER_LINE_12
			RIF&year_data..BCARRIER_LINE_01
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
		DROP TABLE WORK.CarrierSmall;
		CREATE TABLE WORK.CarrierSmall AS
		SELECT a.BENE_ID, CLM_ID, LINE_NCH_PMT_AMT, LINE_SBMTD_CHRG_AMT, CLM_THRU_DT, NCH_CLM_TYPE_CD, PRF_PHYSN_NPI, LINE_SRVC_CNT, LINE_PLACE_OF_SRVC_CD,
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			HCPCS_CD, RVU, BETOS_CD, Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS
		INNER JOIN WORK.IP_Patients AS c
			ON a.BENE_ID=c.BENE_ID
		WHERE CLM_THRU_DT>=Initial_Admit-30 AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.CarrierIP;
		CREATE TABLE WORK.CarrierIP AS
		SELECT a.BENE_ID, CLM_ID, LINE_NCH_PMT_AMT, LINE_SBMTD_CHRG_AMT, CLM_THRU_DT, NCH_CLM_TYPE_CD, PRF_PHYSN_NPI, LINE_SRVC_CNT, 
			LINE_COINSRNC_AMT + LINE_BENE_PTB_DDCTBL_AMT + LINE_NCH_PMT_AMT + LINE_BENE_PRMRY_PYR_PD_AMT AS Carrier_Spend,
			HCPCS_CD, RVU, BETOS_CD, Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierStack AS a
		LEFT JOIN (SELECT HCPCS, max(RVU) AS RVU FROM PL027710.RVU_&year_data GROUP BY HCPCS) AS b
			ON a.HCPCS_CD=b.HCPCS
		INNER JOIN WORK.IP_Patients AS c
			ON a.BENE_ID=c.BENE_ID
		WHERE CLM_THRU_DT>=Initial_Admit AND CLM_THRU_DT<=Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Imaging;
		CREATE TABLE WORK.Imaging AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS Imaging_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS Imaging_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Imaging_MCare_Payment,
			sum(LINE_SRVC_CNT) AS Imaging_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Imaging_Charge,
			sum(Carrier_Spend) AS Imaging_Spend,
			count(DISTINCT CLM_THRU_DT) AS Imaging_Events,
			sum(RVU) AS Imaging_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE SUBSTR(BETOS_CD,1,1)="I")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.EM;
		CREATE TABLE WORK.EM AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS EM_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS EM_Physicians,
			sum(LINE_NCH_PMT_AMT) AS EM_MCare_Payment,
			sum(LINE_SRVC_CNT) AS EM_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS EM_Charge,
			sum(Carrier_Spend) AS EM_Spend,
			count(DISTINCT CLM_THRU_DT) AS EM_Events,
			sum(RVU) AS EM_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE SUBSTR(BETOS_CD,1,1)="M")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Lab;
		CREATE TABLE WORK.Lab AS
		SELECT BENE_ID, Initial_Admit, Initial_Discharge, Initial_ID,
			count(CLM_ID) AS Lab_Claims, 
			count(DISTINCT PRF_PHYSN_NPI) AS Lab_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Lab_MCare_Payment,
			sum(LINE_SRVC_CNT) AS Lab_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Lab_Charge,
			sum(Carrier_Spend) AS Lab_Spend,
			count(DISTINCT CLM_THRU_DT) AS Lab_Events,
			sum(RVU) AS Lab_RVU
		FROM (SELECT * FROM WORK.CarrierSmall WHERE (SUBSTR(BETOS_CD,1,1)="T") AND
			(NCH_CLM_TYPE_CD IN ("71", "72")))
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierEpisode;
		CREATE TABLE WORK.CarrierEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.Carrier_PlaceOfService_&year_data;
		CREATE TABLE PL027710.Carrier_PlaceOfService_&year_data AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU, LINE_PLACE_OF_SRVC_CD,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY BENE_ID, LINE_PLACE_OF_SRVC_CD, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.Carrier_Physicians_&year_data;
		CREATE TABLE PL027710.Carrier_Physicians_&year_data AS
		SELECT PRF_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS Carrier_Events,
			count(CLM_ID) AS Carrier_Claims,
			sum(LINE_NCH_PMT_AMT) AS Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS Carrier_Charge, sum(Carrier_Spend) AS Carrier_Spend,
			sum(RVU) AS Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierSmall
		GROUP BY PRF_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.CarrierEpisode_IP;
		CREATE TABLE WORK.CarrierEpisode_IP AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS IP_Carrier_Events,
			count(CLM_ID) AS IP_Carrier_Claims, count(DISTINCT PRF_PHYSN_NPI) AS IP_Carrier_Physicians,
			sum(LINE_NCH_PMT_AMT) AS IP_Carrier_Mcare_Payment, sum(LINE_SRVC_CNT) AS IP_Carrier_SRVC_Count,
			sum(LINE_SBMTD_CHRG_AMT) AS IP_Carrier_Charge, sum(Carrier_Spend) AS IP_Carrier_Spend,
			sum(RVU) AS IP_Carrier_RVU,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.CarrierIP
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	/* Collect Episode HHA Claims */
	DATA WORK.HHA;
		SET	RIF&year_data..HHA_CLAIMS_01
	  		RIF&year_data..HHA_CLAIMS_02
			RIF&year_data..HHA_CLAIMS_03
			RIF&year_data..HHA_CLAIMS_04
			RIF&year_data..HHA_CLAIMS_05
			RIF&year_data..HHA_CLAIMS_06
			RIF&year_data..HHA_CLAIMS_07
			RIF&year_data..HHA_CLAIMS_08
			RIF&year_data..HHA_CLAIMS_09
			RIF&year_data..HHA_CLAIMS_10
			RIF&year_data..HHA_CLAIMS_11
			RIF&year_data..HHA_CLAIMS_12;	
	RUN;

	PROC SQL;
		DROP TABLE WORK.HHASmall;
		CREATE TABLE WORK.HHASmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT AS HHA_Spend, AT_PHYSN_NPI, OP_PHYSN_NPI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHA AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.HHAEpisode;
		CREATE TABLE WORK.HHAEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS HHA_Events, count(DISTINCT AT_PHYSN_NPI) AS HHA_Physicians,
			count(CLM_ID) AS HHA_Claims, sum(CLM_PMT_AMT) AS HHA_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS HHA_Charge, sum(HHA_Spend) AS HHA_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHASmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.HHA_Physicians_&year_data;
		CREATE TABLE PL027710.HHA_Physicians_&year_data AS
		SELECT AT_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS HHA_Events,
			count(CLM_ID) AS HHA_Claims, sum(CLM_PMT_AMT) AS HHA_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS HHA_Charge, sum(HHA_Spend) AS HHA_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.HHASmall
		GROUP BY AT_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	/* Collect Episode SNF Claims */
	DATA WORK.SNF;
		SET	RIF&year_data..SNF_CLAIMS_01
	  		RIF&year_data..SNF_CLAIMS_02
			RIF&year_data..SNF_CLAIMS_03
			RIF&year_data..SNF_CLAIMS_04
			RIF&year_data..SNF_CLAIMS_05
			RIF&year_data..SNF_CLAIMS_06
			RIF&year_data..SNF_CLAIMS_07
			RIF&year_data..SNF_CLAIMS_08
			RIF&year_data..SNF_CLAIMS_09
			RIF&year_data..SNF_CLAIMS_10
			RIF&year_data..SNF_CLAIMS_11
			RIF&year_data..SNF_CLAIMS_12;
	RUN;

	PROC SQL;
		DROP TABLE WORK.SNFSmall;
		CREATE TABLE WORK.SNFSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, CLM_FROM_DT, CLM_THRU_DT,
			CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS SNF_Spend, AT_PHYSN_NPI, OP_PHYSN_NPI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNF AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_FROM_DT>=Initial_Discharge AND CLM_THRU_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.SNFEpisode;
		CREATE TABLE WORK.SNFEpisode AS
		SELECT BENE_ID, count(DISTINCT CLM_THRU_DT) AS SNF_Events, count(DISTINCT AT_PHYSN_NPI) AS SNF_Physicians,
			count(CLM_ID) AS SNF_Claims, sum(CLM_PMT_AMT) AS SNF_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS SNF_Charge, sum(SNF_Spend) AS SNF_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNFSmall
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE PL027710.SNF_Physicians_&year_data;
		CREATE TABLE PL027710.SNF_Physicians_&year_data AS
		SELECT AT_PHYSN_NPI, BENE_ID, count(DISTINCT CLM_THRU_DT) AS SNF_Events,
			count(CLM_ID) AS SNF_Claims, sum(CLM_PMT_AMT) AS SNF_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS SNF_Charge, sum(SNF_Spend) AS SNF_Spend,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM WORK.SNFSmall
		GROUP BY AT_PHYSN_NPI, BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE PL027710.Episodes_&year_data;
		CREATE TABLE PL027710.Episodes_&year_data AS
		SELECT a.*, b.*, c.*, d.*, e.*, f.*, g.*, h.*, i.*, j.*
			FROM WORK.IP_Patients AS a
		LEFT JOIN WORK.IPEpisode AS b
			ON a.BENE_ID=b.BENE_ID AND a.Initial_ID=b.Initial_ID
			AND a.Initial_Admit=b.Initial_Admit AND a.Initial_Discharge=b.Initial_Discharge			
		LEFT JOIN WORK.OPEpisode AS c
			ON a.BENE_ID=c.BENE_ID AND a.Initial_ID=c.Initial_ID
			AND a.Initial_Admit=c.Initial_Admit AND a.Initial_Discharge=c.Initial_Discharge
		LEFT JOIN WORK.CarrierEpisode AS d
			ON a.BENE_ID=d.BENE_ID AND a.Initial_ID=d.Initial_ID
			AND a.Initial_Admit=d.Initial_Admit AND a.Initial_Discharge=d.Initial_Discharge
		LEFT JOIN WORK.Imaging AS e
			ON a.BENE_ID=e.BENE_ID AND a.Initial_ID=e.Initial_ID
			AND a.Initial_Admit=e.Initial_Admit AND a.Initial_Discharge=e.Initial_Discharge
		LEFT JOIN WORK.EM AS f
			ON a.BENE_ID=f.BENE_ID AND a.Initial_ID=f.Initial_ID
			AND a.Initial_Admit=f.Initial_Admit AND a.Initial_Discharge=f.Initial_Discharge
		LEFT JOIN WORK.Lab AS g
			ON a.BENE_ID=g.BENE_ID AND a.Initial_ID=g.Initial_ID
			AND a.Initial_Admit=g.Initial_Admit AND a.Initial_Discharge=g.Initial_Discharge
		LEFT JOIN WORK.CarrierEpisode_IP AS h
			ON a.BENE_ID=h.BENE_ID AND a.Initial_ID=h.Initial_ID
			AND a.Initial_Admit=h.Initial_Admit AND a.Initial_Discharge=h.Initial_Discharge
		LEFT JOIN WORK.HHAEpisode AS i
			ON a.BENE_ID=i.BENE_ID AND a.Initial_ID=i.Initial_ID
			AND a.Initial_Admit=i.Initial_Admit AND a.Initial_Discharge=i.Initial_Discharge
		LEFT JOIN WORK.SNFEpisode AS j
			ON a.BENE_ID=j.BENE_ID AND a.Initial_ID=j.Initial_ID
			AND a.Initial_Admit=j.Initial_Admit AND a.Initial_Discharge=j.Initial_Discharge;
	QUIT;
