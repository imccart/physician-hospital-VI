/* ------------------------------------------------------------ */
/* TITLE:		 Follow-up care from inpatient Stays initiated by physician    */
/* 				 referral, clinic referral, or HMO referral  	*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 2/20/2017										*/
/* DATE EDITED:  10/19/2018										*/
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

/* Create Table of Follow-up Care for 2007 */
DATA WORK.InpatientClaims_2007;
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
	DROP TABLE IMC969SL.OtherIPClaims_2007;
	CREATE TABLE IMC969SL.OtherIPClaims_2007 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		CASE
			WHEN a.ORG_NPI_NUM NE '' AND a.ORG_NPI_NUM NE '0000000000' THEN a.ORG_NPI_NUM
			WHEN a.ORG_NPI_NUM='' OR a.ORG_NPI_NUM='0000000000' THEN b.NPI
		ELSE ''
		END AS ORG_NPI_NUM,
		a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2007 AS a
	LEFT JOIN IMC969SL.PRVN_NPI_Merge_2007 AS b
		ON a.PRVDR_NUM=b.PRVDR_NUM
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;


/* Create Table of Follow-up Care for 2008 */
DATA WORK.InpatientClaims_2008;
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
	DROP TABLE IMC969SL.OtherIPClaims_2008;
	CREATE TABLE IMC969SL.OtherIPClaims_2008 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		CASE
			WHEN a.ORG_NPI_NUM NE '' AND a.ORG_NPI_NUM NE '0000000000' THEN a.ORG_NPI_NUM
			WHEN a.ORG_NPI_NUM='' OR a.ORG_NPI_NUM='0000000000' THEN b.NPI
		ELSE ''
		END AS ORG_NPI_NUM,
		a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2008 AS a
	LEFT JOIN IMC969SL.PRVN_NPI_Merge_2008 AS b
		ON a.PRVDR_NUM=b.PRVDR_NUM
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;



/* Create Table of Follow-up Care for 2009 */
DATA WORK.InpatientClaims_2009;
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
	DROP TABLE IMC969SL.OtherIPClaims_2009;
	CREATE TABLE IMC969SL.OtherIPClaims_2009 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2009 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;


/* Create Table of Follow-up Care for 2010 */
DATA WORK.InpatientClaims_2010;
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
	DROP TABLE IMC969SL.OtherIPClaims_2010;
	CREATE TABLE IMC969SL.OtherIPClaims_2010 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2010 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;


/* Create Table of Follow-up Care for 2011 */
DATA WORK.InpatientClaims_2011;
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
	DROP TABLE IMC969SL.OtherIPClaims_2011;
	CREATE TABLE IMC969SL.OtherIPClaims_2011 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2011 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;


/* Create Table of Follow-up Care for 2012 */
DATA WORK.InpatientClaims_2012;
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
	DROP TABLE IMC969SL.OtherIPClaims_2012;
	CREATE TABLE IMC969SL.OtherIPClaims_2012 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2012 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;


/* Create Table of Follow-up Care for 2013 */
DATA WORK.InpatientClaims_2013;
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
	DROP TABLE IMC969SL.OtherIPClaims_2013;
	CREATE TABLE IMC969SL.OtherIPClaims_2013 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2013 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;

/* Create Table of Follow-up Care for 2014 */
DATA WORK.InpatientClaims_2014;
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
	DROP TABLE IMC969SL.OtherIPClaims_2014;
	CREATE TABLE IMC969SL.OtherIPClaims_2014 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2014 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;


/* Create Table of Follow-up Care for 2014 */
DATA WORK.InpatientClaims_2015;
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
	DROP TABLE IMC969SL.OtherIPClaims_2015;
	CREATE TABLE IMC969SL.OtherIPClaims_2015 AS
	SELECT a.BENE_ID, a.CLM_ID, a.CLM_FROM_DT, a.CLM_THRU_DT, a.PRVDR_NUM, a.NCH_CLM_TYPE_CD,
		a.ORG_NPI_NUM, a.CLM_PMT_AMT, a.CLM_TOT_CHRG_AMT
	FROM WORK.InpatientClaims_2015 AS a
	WHERE (NCH_CLM_TYPE_CD IN ("20", "30", "10"))
		OR (NCH_CLM_TYPE_CD IN ("60", "61") 
			AND (SUBSTR(a.PRVDR_NUM,3,2) IN ("20", "21", "22") OR SUBSTR(a.PRVDR_NUM,3,1) IN ("R", "T")
			OR  SUBSTR(a.PRVDR_NUM,1,4) IN ("3025", "3026", "3027", "3028", "3029", "3030", "3031", "3032", "3033", "3034", "3035",
		  		"3036", "3037", "3038", "3039", "3040", "3041", "3042", "3043", "3044", "3045",
				"3046", "3047", "3048", "3049", "3050", "3051", "3052", "3053", "3054", "3055",
				"3056", "3057", "3058", "3059", "3060", "3061", "3062", "3063", "3064", "3065",
				"3066", "3067", "3068", "3069", "3070", "3071", "3072", "3073", "3074", "3075",
				"3076", "3077", "3078", "3079", "3080", "3081", "3082", "3083", "3084", "3085",
				"3086", "3087", "3088", "3089", "3090", "3091", "3092", "3093", "3094", "3095",
				"3096", "3097", "3098", "3099") ) );
QUIT;