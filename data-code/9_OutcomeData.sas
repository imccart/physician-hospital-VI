/* ------------------------------------------------------------ */
/* TITLE:		 Find Inpatient Stays from broader set to identify */
/*				 complications and readmissions					*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 7/1/2019										*/
/* DATE EDITED:  2/27/2024										*/
/* CODE FILE ORDER: 9 of XX  									*/
/* NOTES:														*/
/*   -- File outputs the following tables to PL027710:			*/
/*		Outcomes_2009-2015	  							    	*/
/* ------------------------------------------------------------ */


%macro process_outcomes_data;
	%do year_data=2009 %to 2014;
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
			RIF&year_data..INPATIENT_CLAIMS_12
			RIF&year_post..INPATIENT_CLAIMS_01
			RIF&year_post..INPATIENT_CLAIMS_02
			RIF&year_post..INPATIENT_CLAIMS_03;
	RUN;

	PROC SQL;
		DROP TABLE WORK.IPSmall;
		CREATE TABLE WORK.IPSmall AS
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, 
			  CLM_ADMSN_DT AS Admit, NCH_BENE_DSCHRG_DT AS Discharge,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend,
			  ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD,
			  ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
			  ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10,
			  b.Initial_Admit, b.Initial_Discharge, b.Initial_ID
		FROM WORK.InpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_ADMSN_DT>=Initial_Admit AND NCH_BENE_DSCHRG_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Readmit;
		CREATE TABLE WORK.Readmit AS
		SELECT BENE_ID, count(DISTINCT CLM_ID) AS Readmit_Claims, sum(CLM_PMT_AMT) AS Readmit_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS Readmit_Charge, sum(IP_Spend) AS Readmit_Spend,
			min(Admit) AS First_Readmit, min(Discharge) AS First_Discharge,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall WHERE CLM_ID NE Initial_ID AND Admit>Initial_Discharge)
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.SSI;
		CREATE TABLE WORK.SSI AS
		SELECT BENE_ID, min(Admit) AS First_SSI, count(DISTINCT CLM_ID) AS SSI_Claims, 1 as SSI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ICD_DGNS_CD1 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD2 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD3 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD4 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD5 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD6 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD7 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD8 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD9 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD10 IN ("99832", "99831", "56722", "9985", "99851", "99859")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.PrimarySSI;
		CREATE TABLE WORK.PrimarySSI AS
		SELECT BENE_ID, min(Admit) AS First_PrimarySSI, 
			count(DISTINCT CLM_ID) AS PrimarySSI_Claims, 1 as PrimarySSI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ADMTG_DGNS_CD IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR PRNCPAL_DGNS_CD IN ("99832", "99831", "56722", "9985", "99851", "99859")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.Sepsis;
		CREATE TABLE WORK.Sepsis AS
		SELECT BENE_ID, min(Admit) AS First_Sepsis, 
			count(DISTINCT CLM_ID) AS Sepsis_Claims, 1 as Sepsis,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ICD_DGNS_CD1 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD2 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD3 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD4 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD5 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD6 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD7 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD8 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD9 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD10 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.PrimarySepsis;
		CREATE TABLE WORK.PrimarySepsis AS
		SELECT BENE_ID, min(Admit) AS First_PrimarySepsis, 
			count(DISTINCT CLM_ID) AS PrimarySepsis_Claims, 1 as PrimarySepsis,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ADMTG_DGNS_CD IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR PRNCPAL_DGNS_CD IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE PL027710.Outcomes_&year_data;
		CREATE TABLE PL027710.Outcomes_&year_data AS
		SELECT a.*, b.*, c.*, d.*, e.*, f.*
			FROM WORK.IP_Patients AS a
		LEFT JOIN WORK.Readmit AS b
			ON a.BENE_ID=b.BENE_ID AND a.Initial_ID=b.Initial_ID
			AND a.Initial_Admit=b.Initial_Admit AND a.Initial_Discharge=b.Initial_Discharge
		LEFT JOIN WORK.SSI AS c
			ON a.BENE_ID=c.BENE_ID AND a.Initial_ID=c.Initial_ID
			AND a.Initial_Admit=c.Initial_Admit AND a.Initial_Discharge=c.Initial_Discharge
		LEFT JOIN WORK.PrimarySSI AS d
			ON a.BENE_ID=d.BENE_ID AND a.Initial_ID=d.Initial_ID
			AND a.Initial_Admit=d.Initial_Admit AND a.Initial_Discharge=d.Initial_Discharge
		LEFT JOIN WORK.Sepsis AS e
			ON a.BENE_ID=e.BENE_ID AND a.Initial_ID=e.Initial_ID
			AND a.Initial_Admit=e.Initial_Admit AND a.Initial_Discharge=e.Initial_Discharge
		LEFT JOIN WORK.PrimarySepsis AS f
			ON a.BENE_ID=f.BENE_ID AND a.Initial_ID=f.Initial_ID
			AND a.Initial_Admit=f.Initial_Admit AND a.Initial_Discharge=f.Initial_Discharge;
	QUIT;

	%END;

%mend process_outcomes_data;

%process_outcomes_data;





/* For 2015 Only */
	%LET year_data=2015;

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
		SELECT a.BENE_ID, CLM_ID, CLM_PMT_AMT, CLM_TOT_CHRG_AMT, 
			  CLM_ADMSN_DT AS Admit, NCH_BENE_DSCHRG_DT AS Discharge,
			  CLM_PMT_AMT + NCH_PRMRY_PYR_CLM_PD_AMT + NCH_IP_TOT_DDCTN_AMT AS IP_Spend,
			  ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD,
			  ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
			  ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10,
			  b.Initial_Admit, b.Initial_Discharge, b.Initial_ID
		FROM WORK.InpatientStack AS a
		INNER JOIN WORK.IP_Patients AS b
			ON a.BENE_ID=b.BENE_ID
		WHERE CLM_ADMSN_DT>=Initial_Admit AND NCH_BENE_DSCHRG_DT<=Initial_Discharge+90;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.Readmit;
		CREATE TABLE WORK.Readmit AS
		SELECT BENE_ID, count(DISTINCT CLM_ID) AS Readmit_Claims, sum(CLM_PMT_AMT) AS Readmit_Mcare_Payment, 
			sum(CLM_TOT_CHRG_AMT) AS Readmit_Charge, sum(IP_Spend) AS Readmit_Spend,
			min(Admit) AS First_Readmit, min(Discharge) AS First_Discharge,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall WHERE CLM_ID NE Initial_ID AND Admit>Initial_Discharge)
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.SSI;
		CREATE TABLE WORK.SSI AS
		SELECT BENE_ID, min(Admit) AS First_SSI, count(DISTINCT CLM_ID) AS SSI_Claims, 1 as SSI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ICD_DGNS_CD1 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD2 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD3 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD4 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD5 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD6 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD7 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD8 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD9 IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR ICD_DGNS_CD10 IN ("99832", "99831", "56722", "9985", "99851", "99859")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.PrimarySSI;
		CREATE TABLE WORK.PrimarySSI AS
		SELECT BENE_ID, min(Admit) AS First_PrimarySSI, 
			count(DISTINCT CLM_ID) AS PrimarySSI_Claims, 1 as PrimarySSI,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ADMTG_DGNS_CD IN ("99832", "99831", "56722", "9985", "99851", "99859")
			  OR PRNCPAL_DGNS_CD IN ("99832", "99831", "56722", "9985", "99851", "99859")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE WORK.Sepsis;
		CREATE TABLE WORK.Sepsis AS
		SELECT BENE_ID, min(Admit) AS First_Sepsis, 
			count(DISTINCT CLM_ID) AS Sepsis_Claims, 1 as Sepsis,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ICD_DGNS_CD1 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD2 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD3 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD4 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD5 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD6 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD7 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD8 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD9 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR ICD_DGNS_CD10 IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;

	PROC SQL;
		DROP TABLE WORK.PrimarySepsis;
		CREATE TABLE WORK.PrimarySepsis AS
		SELECT BENE_ID, min(Admit) AS First_PrimarySepsis, 
			count(DISTINCT CLM_ID) AS PrimarySepsis_Claims, 1 as PrimarySepsis,
			Initial_ID, Initial_Admit, Initial_Discharge
		FROM (SELECT * FROM WORK.IPSmall)
		WHERE ADMTG_DGNS_CD IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
			OR PRNCPAL_DGNS_CD IN ("038","0380","0381","03810","03811","03812","03819","0382",
							   "0383","0384","03840","03841","03842","03843","03844","03849",
							   "0388","0389","78552","7907","99591","99592","9980")
		GROUP BY BENE_ID, Initial_ID, Initial_Admit, Initial_Discharge;
	QUIT;


	PROC SQL;
		DROP TABLE PL027710.Outcomes_&year_data;
		CREATE TABLE PL027710.Outcomes_&year_data AS
		SELECT a.*, b.*, c.*, d.*, e.*, f.*
			FROM WORK.IP_Patients AS a
		LEFT JOIN WORK.Readmit AS b
			ON a.BENE_ID=b.BENE_ID AND a.Initial_ID=b.Initial_ID
			AND a.Initial_Admit=b.Initial_Admit AND a.Initial_Discharge=b.Initial_Discharge
		LEFT JOIN WORK.SSI AS c
			ON a.BENE_ID=c.BENE_ID AND a.Initial_ID=c.Initial_ID
			AND a.Initial_Admit=c.Initial_Admit AND a.Initial_Discharge=c.Initial_Discharge
		LEFT JOIN WORK.PrimarySSI AS d
			ON a.BENE_ID=d.BENE_ID AND a.Initial_ID=d.Initial_ID
			AND a.Initial_Admit=d.Initial_Admit AND a.Initial_Discharge=d.Initial_Discharge
		LEFT JOIN WORK.Sepsis AS e
			ON a.BENE_ID=e.BENE_ID AND a.Initial_ID=e.Initial_ID
			AND a.Initial_Admit=e.Initial_Admit AND a.Initial_Discharge=e.Initial_Discharge
		LEFT JOIN WORK.PrimarySepsis AS f
			ON a.BENE_ID=f.BENE_ID AND a.Initial_ID=f.Initial_ID
			AND a.Initial_Admit=f.Initial_Admit AND a.Initial_Discharge=f.Initial_Discharge;
	QUIT;
