/* ------------------------------------------------------------ */
/* TITLE:		 Find All Inpatient Stays 						*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 2/20/2017										*/
/* DATE EDITED:  10/8/2018										*/
/* CODE FILE ORDER: 7 of XX  									*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		TotalBENE_2007-2015  									*/
/* ------------------------------------------------------------ */

/* Create Table of Inpatient (Hospital Only) Stays for 2007 */
DATA WORK.InpatientStays_2007;
	SET	RIF2007.INPATIENT_CLAIMS_01
  		RIF2007.INPATIENT_CLAIMS_02
		RIF2007.INPATIENT_CLAIMS_03
		RIF2007.INPATIENT_CLAIMS_04
		RIF2007.INPATIENT_CLAIMS_05
		RIF2007.INPATIENT_CLAIMS_06
		RIF2007.INPATIENT_CLAIMS_07
		RIF2007.INPATIENT_CLAIMS_08
		RIF2007.INPATIENT_CLAIMS_09
		RIF2007.INPATIENT_CLAIMS_10
		RIF2007.INPATIENT_CLAIMS_11
		RIF2007.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2007;
	SET	RIF2007.OUTPATIENT_CLAIMS_01
  		RIF2007.OUTPATIENT_CLAIMS_02
		RIF2007.OUTPATIENT_CLAIMS_03
		RIF2007.OUTPATIENT_CLAIMS_04
		RIF2007.OUTPATIENT_CLAIMS_05
		RIF2007.OUTPATIENT_CLAIMS_06
		RIF2007.OUTPATIENT_CLAIMS_07
		RIF2007.OUTPATIENT_CLAIMS_08
		RIF2007.OUTPATIENT_CLAIMS_09
		RIF2007.OUTPATIENT_CLAIMS_10
		RIF2007.OUTPATIENT_CLAIMS_11
		RIF2007.OUTPATIENT_CLAIMS_12;
RUN;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2007;
	CREATE TABLE IMC969SL.TotalBENE_IP_2007 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2007
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2007;
	CREATE TABLE IMC969SL.TotalBENE_OP_2007 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2007
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2007;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2007 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2007 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2007 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2007;
	CREATE TABLE IMC969SL.TotalBENE_2007 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2007
	GROUP BY BENE_ID;
QUIT;

/* Create Table of Inpatient (Hospital Only) Stays for 2008 */
DATA WORK.InpatientStays_2008;
	SET	RIF2008.INPATIENT_CLAIMS_01
  		RIF2008.INPATIENT_CLAIMS_02
		RIF2008.INPATIENT_CLAIMS_03
		RIF2008.INPATIENT_CLAIMS_04
		RIF2008.INPATIENT_CLAIMS_05
		RIF2008.INPATIENT_CLAIMS_06
		RIF2008.INPATIENT_CLAIMS_07
		RIF2008.INPATIENT_CLAIMS_08
		RIF2008.INPATIENT_CLAIMS_09
		RIF2008.INPATIENT_CLAIMS_10
		RIF2008.INPATIENT_CLAIMS_11
		RIF2008.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2008;
	SET	RIF2008.OUTPATIENT_CLAIMS_01
  		RIF2008.OUTPATIENT_CLAIMS_02
		RIF2008.OUTPATIENT_CLAIMS_03
		RIF2008.OUTPATIENT_CLAIMS_04
		RIF2008.OUTPATIENT_CLAIMS_05
		RIF2008.OUTPATIENT_CLAIMS_06
		RIF2008.OUTPATIENT_CLAIMS_07
		RIF2008.OUTPATIENT_CLAIMS_08
		RIF2008.OUTPATIENT_CLAIMS_09
		RIF2008.OUTPATIENT_CLAIMS_10
		RIF2008.OUTPATIENT_CLAIMS_11
		RIF2008.OUTPATIENT_CLAIMS_12;
RUN;


PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2008;
	CREATE TABLE IMC969SL.TotalBENE_IP_2008 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2008
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2008;
	CREATE TABLE IMC969SL.TotalBENE_OP_2008 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2008
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2008;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2008 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2008 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2008 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2008;
	CREATE TABLE IMC969SL.TotalBENE_2008 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2008
	GROUP BY BENE_ID;
QUIT;

/* Create Table of Inpatient (Hospital Only) Stays for 2009 */
DATA WORK.InpatientStays_2009;
	SET	RIF2009.INPATIENT_CLAIMS_01
  		RIF2009.INPATIENT_CLAIMS_02
		RIF2009.INPATIENT_CLAIMS_03
		RIF2009.INPATIENT_CLAIMS_04
		RIF2009.INPATIENT_CLAIMS_05
		RIF2009.INPATIENT_CLAIMS_06
		RIF2009.INPATIENT_CLAIMS_07
		RIF2009.INPATIENT_CLAIMS_08
		RIF2009.INPATIENT_CLAIMS_09
		RIF2009.INPATIENT_CLAIMS_10
		RIF2009.INPATIENT_CLAIMS_11
		RIF2009.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2009;
	SET	RIF2009.OUTPATIENT_CLAIMS_01
  		RIF2009.OUTPATIENT_CLAIMS_02
		RIF2009.OUTPATIENT_CLAIMS_03
		RIF2009.OUTPATIENT_CLAIMS_04
		RIF2009.OUTPATIENT_CLAIMS_05
		RIF2009.OUTPATIENT_CLAIMS_06
		RIF2009.OUTPATIENT_CLAIMS_07
		RIF2009.OUTPATIENT_CLAIMS_08
		RIF2009.OUTPATIENT_CLAIMS_09
		RIF2009.OUTPATIENT_CLAIMS_10
		RIF2009.OUTPATIENT_CLAIMS_11
		RIF2009.OUTPATIENT_CLAIMS_12;
RUN;


PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2009;
	CREATE TABLE IMC969SL.TotalBENE_IP_2009 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2009
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2009;
	CREATE TABLE IMC969SL.TotalBENE_OP_2009 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2009
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2009;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2009 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2009 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2009 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2009;
	CREATE TABLE IMC969SL.TotalBENE_2009 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2009
	GROUP BY BENE_ID;
QUIT;

/* Create Table of Inpatient (Hospital Only) Stays for 2010 */
DATA WORK.InpatientStays_2010;
	SET	RIF2010.INPATIENT_CLAIMS_01
  		RIF2010.INPATIENT_CLAIMS_02
		RIF2010.INPATIENT_CLAIMS_03
		RIF2010.INPATIENT_CLAIMS_04
		RIF2010.INPATIENT_CLAIMS_05
		RIF2010.INPATIENT_CLAIMS_06
		RIF2010.INPATIENT_CLAIMS_07
		RIF2010.INPATIENT_CLAIMS_08
		RIF2010.INPATIENT_CLAIMS_09
		RIF2010.INPATIENT_CLAIMS_10
		RIF2010.INPATIENT_CLAIMS_11
		RIF2010.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2010;
	SET	RIF2010.OUTPATIENT_CLAIMS_01
  		RIF2010.OUTPATIENT_CLAIMS_02
		RIF2010.OUTPATIENT_CLAIMS_03
		RIF2010.OUTPATIENT_CLAIMS_04
		RIF2010.OUTPATIENT_CLAIMS_05
		RIF2010.OUTPATIENT_CLAIMS_06
		RIF2010.OUTPATIENT_CLAIMS_07
		RIF2010.OUTPATIENT_CLAIMS_08
		RIF2010.OUTPATIENT_CLAIMS_09
		RIF2010.OUTPATIENT_CLAIMS_10
		RIF2010.OUTPATIENT_CLAIMS_11
		RIF2010.OUTPATIENT_CLAIMS_12;
RUN;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2010;
	CREATE TABLE IMC969SL.TotalBENE_IP_2010 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2010
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2010;
	CREATE TABLE IMC969SL.TotalBENE_OP_2010 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2010
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2010;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2010 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2010 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2010 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2010;
	CREATE TABLE IMC969SL.TotalBENE_2010 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2010
	GROUP BY BENE_ID;
QUIT;


/* Create Table of Inpatient (Hospital Only) Stays for 2011 */
DATA WORK.InpatientStays_2011;
	SET	RIF2011.INPATIENT_CLAIMS_01
  		RIF2011.INPATIENT_CLAIMS_02
		RIF2011.INPATIENT_CLAIMS_03
		RIF2011.INPATIENT_CLAIMS_04
		RIF2011.INPATIENT_CLAIMS_05
		RIF2011.INPATIENT_CLAIMS_06
		RIF2011.INPATIENT_CLAIMS_07
		RIF2011.INPATIENT_CLAIMS_08
		RIF2011.INPATIENT_CLAIMS_09
		RIF2011.INPATIENT_CLAIMS_10
		RIF2011.INPATIENT_CLAIMS_11
		RIF2011.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2011;
	SET	RIF2011.OUTPATIENT_CLAIMS_01
  		RIF2011.OUTPATIENT_CLAIMS_02
		RIF2011.OUTPATIENT_CLAIMS_03
		RIF2011.OUTPATIENT_CLAIMS_04
		RIF2011.OUTPATIENT_CLAIMS_05
		RIF2011.OUTPATIENT_CLAIMS_06
		RIF2011.OUTPATIENT_CLAIMS_07
		RIF2011.OUTPATIENT_CLAIMS_08
		RIF2011.OUTPATIENT_CLAIMS_09
		RIF2011.OUTPATIENT_CLAIMS_10
		RIF2011.OUTPATIENT_CLAIMS_11
		RIF2011.OUTPATIENT_CLAIMS_12;
RUN;


PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2011;
	CREATE TABLE IMC969SL.TotalBENE_IP_2011 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2011
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2011;
	CREATE TABLE IMC969SL.TotalBENE_OP_2011 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2011
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2011;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2011 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2011 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2011 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2011;
	CREATE TABLE IMC969SL.TotalBENE_2011 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2011
	GROUP BY BENE_ID;
QUIT;


/* Create Table of Inpatient (Hospital Only) Stays for 2012 */
DATA WORK.InpatientStays_2012;
	SET	RIF2012.INPATIENT_CLAIMS_01
  		RIF2012.INPATIENT_CLAIMS_02
		RIF2012.INPATIENT_CLAIMS_03
		RIF2012.INPATIENT_CLAIMS_04
		RIF2012.INPATIENT_CLAIMS_05
		RIF2012.INPATIENT_CLAIMS_06
		RIF2012.INPATIENT_CLAIMS_07
		RIF2012.INPATIENT_CLAIMS_08
		RIF2012.INPATIENT_CLAIMS_09
		RIF2012.INPATIENT_CLAIMS_10
		RIF2012.INPATIENT_CLAIMS_11
		RIF2012.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2012;
	SET	RIF2012.OUTPATIENT_CLAIMS_01
  		RIF2012.OUTPATIENT_CLAIMS_02
		RIF2012.OUTPATIENT_CLAIMS_03
		RIF2012.OUTPATIENT_CLAIMS_04
		RIF2012.OUTPATIENT_CLAIMS_05
		RIF2012.OUTPATIENT_CLAIMS_06
		RIF2012.OUTPATIENT_CLAIMS_07
		RIF2012.OUTPATIENT_CLAIMS_08
		RIF2012.OUTPATIENT_CLAIMS_09
		RIF2012.OUTPATIENT_CLAIMS_10
		RIF2012.OUTPATIENT_CLAIMS_11
		RIF2012.OUTPATIENT_CLAIMS_12;
RUN;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2012;
	CREATE TABLE IMC969SL.TotalBENE_IP_2012 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2012
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2012;
	CREATE TABLE IMC969SL.TotalBENE_OP_2012 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2012
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2012;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2012 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2012 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2012 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2012;
	CREATE TABLE IMC969SL.TotalBENE_2012 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2012
	GROUP BY BENE_ID;
QUIT;


/* Create Table of Inpatient (Hospital Only) Stays for 2013 */
DATA WORK.InpatientStays_2013;
	SET	RIF2013.INPATIENT_CLAIMS_01
  		RIF2013.INPATIENT_CLAIMS_02
		RIF2013.INPATIENT_CLAIMS_03
		RIF2013.INPATIENT_CLAIMS_04
		RIF2013.INPATIENT_CLAIMS_05
		RIF2013.INPATIENT_CLAIMS_06
		RIF2013.INPATIENT_CLAIMS_07
		RIF2013.INPATIENT_CLAIMS_08
		RIF2013.INPATIENT_CLAIMS_09
		RIF2013.INPATIENT_CLAIMS_10
		RIF2013.INPATIENT_CLAIMS_11
		RIF2013.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2013;
	SET	RIF2013.OUTPATIENT_CLAIMS_01
  		RIF2013.OUTPATIENT_CLAIMS_02
		RIF2013.OUTPATIENT_CLAIMS_03
		RIF2013.OUTPATIENT_CLAIMS_04
		RIF2013.OUTPATIENT_CLAIMS_05
		RIF2013.OUTPATIENT_CLAIMS_06
		RIF2013.OUTPATIENT_CLAIMS_07
		RIF2013.OUTPATIENT_CLAIMS_08
		RIF2013.OUTPATIENT_CLAIMS_09
		RIF2013.OUTPATIENT_CLAIMS_10
		RIF2013.OUTPATIENT_CLAIMS_11
		RIF2013.OUTPATIENT_CLAIMS_12;
RUN;


PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2013;
	CREATE TABLE IMC969SL.TotalBENE_IP_2013 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2013
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2013;
	CREATE TABLE IMC969SL.TotalBENE_OP_2013 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2013
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2013;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2013 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2013 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2013 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2013;
	CREATE TABLE IMC969SL.TotalBENE_2013 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2013
	GROUP BY BENE_ID;
QUIT;


/* Create Table of Inpatient (Hospital Only) Stays for 2014 */
DATA WORK.InpatientStays_2014;
	SET	RIF2014.INPATIENT_CLAIMS_01
  		RIF2014.INPATIENT_CLAIMS_02
		RIF2014.INPATIENT_CLAIMS_03
		RIF2014.INPATIENT_CLAIMS_04
		RIF2014.INPATIENT_CLAIMS_05
		RIF2014.INPATIENT_CLAIMS_06
		RIF2014.INPATIENT_CLAIMS_07
		RIF2014.INPATIENT_CLAIMS_08
		RIF2014.INPATIENT_CLAIMS_09
		RIF2014.INPATIENT_CLAIMS_10
		RIF2014.INPATIENT_CLAIMS_11
		RIF2014.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2014;
	SET	RIF2014.OUTPATIENT_CLAIMS_01
  		RIF2014.OUTPATIENT_CLAIMS_02
		RIF2014.OUTPATIENT_CLAIMS_03
		RIF2014.OUTPATIENT_CLAIMS_04
		RIF2014.OUTPATIENT_CLAIMS_05
		RIF2014.OUTPATIENT_CLAIMS_06
		RIF2014.OUTPATIENT_CLAIMS_07
		RIF2014.OUTPATIENT_CLAIMS_08
		RIF2014.OUTPATIENT_CLAIMS_09
		RIF2014.OUTPATIENT_CLAIMS_10
		RIF2014.OUTPATIENT_CLAIMS_11
		RIF2014.OUTPATIENT_CLAIMS_12;
RUN;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2014;
	CREATE TABLE IMC969SL.TotalBENE_IP_2014 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2014
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2014;
	CREATE TABLE IMC969SL.TotalBENE_OP_2014 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2014
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2014;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2014 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2014 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2014 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2014;
	CREATE TABLE IMC969SL.TotalBENE_2014 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2014
	GROUP BY BENE_ID;
QUIT;

/* Create Table of Inpatient (Hospital Only) Stays for 2015 */
DATA WORK.InpatientStays_2015;
	SET	RIF2015.INPATIENT_CLAIMS_01
  		RIF2015.INPATIENT_CLAIMS_02
		RIF2015.INPATIENT_CLAIMS_03
		RIF2015.INPATIENT_CLAIMS_04
		RIF2015.INPATIENT_CLAIMS_05
		RIF2015.INPATIENT_CLAIMS_06
		RIF2015.INPATIENT_CLAIMS_07
		RIF2015.INPATIENT_CLAIMS_08
		RIF2015.INPATIENT_CLAIMS_09
		RIF2015.INPATIENT_CLAIMS_10
		RIF2015.INPATIENT_CLAIMS_11
		RIF2015.INPATIENT_CLAIMS_12;
RUN;

DATA WORK.OutpatientStays_2015;
	SET	RIF2015.OUTPATIENT_CLAIMS_01
  		RIF2015.OUTPATIENT_CLAIMS_02
		RIF2015.OUTPATIENT_CLAIMS_03
		RIF2015.OUTPATIENT_CLAIMS_04
		RIF2015.OUTPATIENT_CLAIMS_05
		RIF2015.OUTPATIENT_CLAIMS_06
		RIF2015.OUTPATIENT_CLAIMS_07
		RIF2015.OUTPATIENT_CLAIMS_08
		RIF2015.OUTPATIENT_CLAIMS_09
		RIF2015.OUTPATIENT_CLAIMS_10
		RIF2015.OUTPATIENT_CLAIMS_11
		RIF2015.OUTPATIENT_CLAIMS_12;
RUN;


PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IP_2015;
	CREATE TABLE IMC969SL.TotalBENE_IP_2015 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.InpatientStays_2015
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_OP_2015;
	CREATE TABLE IMC969SL.TotalBENE_OP_2015 AS
	SELECT BENE_ID, count(CLM_ID) AS Tot_Claims, sum(CLM_PMT_AMT) AS Tot_Payment, sum(CLM_TOT_CHRG_AMT) AS Tot_Charge 
	FROM WORK.OutpatientStays_2015
	GROUP BY BENE_ID;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_IPOP_2015;
	CREATE TABLE IMC969SL.TotalBENE_IPOP_2015 AS
	SELECT a.* FROM IMC969SL.TotalBENE_IP_2015 AS a
	UNION ALL
	SELECT b.* FROM IMC969SL.TotalBENE_OP_2015 AS b;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.TotalBENE_2015;
	CREATE TABLE IMC969SL.TotalBENE_2015 AS
	SELECT BENE_ID, sum(Tot_Claims) AS Tot_Claims, sum(Tot_Payment) AS Tot_Payment, sum(Tot_Charge) AS Tot_Charge 
	FROM IMC969SL.TotalBENE_IPOP_2015
	GROUP BY BENE_ID;
QUIT;