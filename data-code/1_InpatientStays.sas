/* ------------------------------------------------------------ */
/* TITLE:		 Find Inpatient Stays initiated by physician    */
/* 				 referral, clinic referral, or HMO referral  	*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 2/20/2017										*/
/* DATE EDITED:  3/2/2018										*/
/* CODE FILE ORDER: 1 of XX  									*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		InpatientStays_2007-2015  								*/
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

PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2007;
	CREATE TABLE IMC969SL.InpatientStays_2007 AS
	SELECT a.BENE_ID, a.CLM_ID, a.NCH_BENE_DSCHRG_DT, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, 
		CASE
			WHEN a.ORG_NPI_NUM NE '' AND a.ORG_NPI_NUM NE '0000000000' THEN a.ORG_NPI_NUM
			WHEN a.ORG_NPI_NUM='' OR a.ORG_NPI_NUM='0000000000' THEN b.NPI
		ELSE ''
		END AS ORG_NPI_NUM,
		a.OP_PHYSN_UPIN,
		CASE 
			WHEN a.OP_PHYSN_NPI NE '' AND a.OP_PHYSN_NPI NE '0000000000' THEN a.OP_PHYSN_NPI
			WHEN a.OP_PHYSN_NPI='' OR a.OP_PHYSN_NPI='0000000000' THEN c.NPI
		ELSE ''
		END AS OP_PHYSN_NPI,
		a.CLM_DRG_CD, a.ADMTG_DGNS_CD, a.ICD_DGNS_CD1, a.PRNCPAL_DGNS_CD, a.ICD_PRCDR_CD1, 
		a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT,
		a.ICD_DGNS_CD2, a.ICD_DGNS_CD3, a.ICD_DGNS_CD4, a.ICD_DGNS_CD5, a.ICD_DGNS_CD6, a.ICD_DGNS_CD7,
		a.ICD_DGNS_CD8, a.ICD_DGNS_CD9, a.ICD_DGNS_CD10, d.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2007 AS a
	LEFT JOIN IMC969SL.PRVN_NPI_Merge_2007 AS b
		ON a.PRVDR_NUM=b.PRVDR_NUM
	LEFT JOIN IMC969SL.UPIN_NPI_Merge_2007 AS c
		ON a.OP_PHYSN_UPIN=c.OP_PHYSN_UPIN
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2007) AS d
		ON input(a.CLM_DRG_CD,18.)=d.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(a.PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(a.PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(a.PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2008;
	CREATE TABLE IMC969SL.InpatientStays_2008 AS
	SELECT a.BENE_ID, a.CLM_ID, a.NCH_BENE_DSCHRG_DT, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, 
		CASE
			WHEN a.ORG_NPI_NUM NE '' AND a.ORG_NPI_NUM NE '0000000000' THEN a.ORG_NPI_NUM
			WHEN a.ORG_NPI_NUM='' OR a.ORG_NPI_NUM='0000000000' THEN b.NPI
		ELSE ''
		END AS ORG_NPI_NUM,
		a.OP_PHYSN_UPIN,
		CASE 
			WHEN a.OP_PHYSN_NPI NE '' AND a.OP_PHYSN_NPI NE '0000000000' THEN a.OP_PHYSN_NPI
			WHEN a.OP_PHYSN_NPI='' OR a.OP_PHYSN_NPI='0000000000' THEN c.NPI
		ELSE ''
		END AS OP_PHYSN_NPI,
		a.CLM_DRG_CD, a.ADMTG_DGNS_CD, a.ICD_DGNS_CD1, a.PRNCPAL_DGNS_CD, a.ICD_PRCDR_CD1,
		a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT,
		a.ICD_DGNS_CD2, a.ICD_DGNS_CD3, a.ICD_DGNS_CD4, a.ICD_DGNS_CD5, a.ICD_DGNS_CD6, a.ICD_DGNS_CD7,
		a.ICD_DGNS_CD8, a.ICD_DGNS_CD9, a.ICD_DGNS_CD10, d.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2008 AS a
	LEFT JOIN IMC969SL.PRVN_NPI_Merge_2008 AS b
		ON a.PRVDR_NUM=b.PRVDR_NUM
	LEFT JOIN IMC969SL.UPIN_NPI_Merge_2008 AS c
		ON a.OP_PHYSN_UPIN=c.OP_PHYSN_UPIN
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2008) AS d
		ON input(a.CLM_DRG_CD,18.)=d.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(a.PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(a.PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(a.PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2009;
	CREATE TABLE IMC969SL.InpatientStays_2009 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2009 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2009) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2010;
	CREATE TABLE IMC969SL.InpatientStays_2010 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2010 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2010) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2011;
	CREATE TABLE IMC969SL.InpatientStays_2011 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2011 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2011) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2012;
	CREATE TABLE IMC969SL.InpatientStays_2012 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2012 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2012) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2013;
	CREATE TABLE IMC969SL.InpatientStays_2013 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2013 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2013) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2014;
	CREATE TABLE IMC969SL.InpatientStays_2014 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2014 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2014) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
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


PROC SQL;
	DROP TABLE IMC969SL.InpatientStays_2015;
	CREATE TABLE IMC969SL.InpatientStays_2015 AS
	SELECT BENE_ID, CLM_ID, NCH_BENE_DSCHRG_DT, CLM_FROM_DT, CLM_THRU_DT, PRVDR_NUM, ORG_NPI_NUM, OP_PHYSN_UPIN,
		OP_PHYSN_NPI, CLM_DRG_CD, ADMTG_DGNS_CD, ICD_DGNS_CD1, PRNCPAL_DGNS_CD, ICD_PRCDR_CD1,
		CLM_PMT_AMT, CLM_TOT_CHRG_AMT,
		ICD_DGNS_CD2, ICD_DGNS_CD3, ICD_DGNS_CD4, ICD_DGNS_CD5, ICD_DGNS_CD6, ICD_DGNS_CD7,
		ICD_DGNS_CD8, ICD_DGNS_CD9, ICD_DGNS_CD10, b.drgweight,
		a.ICD_PRCDR_CD2, a.ICD_PRCDR_CD3, a.ICD_PRCDR_CD4, a.ICD_PRCDR_CD5,
		a.ICD_PRCDR_CD6, a.ICD_PRCDR_CD7, a.ICD_PRCDR_CD8, a.ICD_PRCDR_CD9, a.ICD_PRCDR_CD10,
		a.PTNT_DSCHRG_STUS_CD AS DCHRG_STS
	FROM WORK.InpatientStays_2015 as a
	LEFT JOIN (SELECT * FROM IMC969SL.DRG_Weights WHERE fyear=2015) AS b
		ON input(a.CLM_DRG_CD,18.)=b.drg
	WHERE CLM_SRC_IP_ADMSN_CD IN ("1","2","3")
		  AND (NCH_CLM_TYPE_CD IN ("60", "61"))
		  AND (CLM_IP_ADMSN_TYPE_CD="3")
		  AND (SUBSTR(PRVDR_NUM,3,2) NOT IN ("40", "41", "42", "43", "44", "20", "21", "22"))
		  AND (SUBSTR(PRVDR_NUM,3,1) NOT IN ("M", "S", "R", "T"))
		  AND (SUBSTR(PRVDR_NUM,1,4) NOT IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099"));
QUIT;