/* ------------------------------------------------------------ */
/* TITLE:		 Physician Choice Set							*/
/* AUTHOR:		 Ian McCarthy									*/
/* 				 Emory University								*/
/* DATE CREATED: 9/18/2017										*/
/* DATE EDITED:  11/29/2017										*/
/* CODE FILE ORDER: 5 of XX										*/
/* NOTES:														*/
/*   BENE_CC  Master beneficiary summary file 					*/
/*   MCBSxxxx Medicare Current Beneficiary Survey (Year xxxx) 	*/
/*   MCBSXWLK MCBS Crosswalk 									*/
/*   RIFSxxxx Out/Inpatient and Carrier claims (Year xxxx)  	*/
/*   Medpar   Inpatient claims  								*/
/*   -- File outputs the following tables to IMC969SL:			*/
/*		Physician_Choice_2007-2015			   					*/
/* ------------------------------------------------------------ */
%LET year_data=2015;

PROC SQL;
	DROP TABLE WORK.Physicians_Hospitals;
	CREATE TABLE WORK.Physicians_Hospitals AS
	SELECT ORG_NPI_NUM, OP_PHYSN_NPI, count(distinct CLM_ID) AS Claims, count(distinct BENE_ID) AS Patients
		FROM IMC969SL.INPATIENTSTAYS_&year_data 
		WHERE ORG_NPI_NUM IS NOT NULL AND OP_PHYSN_NPI IS NOT NULL
		GROUP BY OP_PHYSN_NPI, ORG_NPI_NUM;
QUIT;

PROC SQL;
	DROP TABLE IMC969SL.Physician_Choice_&year_data;
	CREATE TABLE IMC969SL.Physician_Choice_&year_data AS
	SELECT a.OP_PHYSN_NPI AS Physician_NPI, a.ORG_NPI_NUM AS Hospital_NPI, a.Claims AS PhyOP_Claims, a.Patients AS PhyOP_Patients,
		b.Carrier_Claims AS Phy_Carrier_Claims, b.Carrier_Patients AS Phy_Carrier_Patients, b.OP_Claims AS Total_PhyOP_Claims,
		b.OP_Patients AS Total_PhyOP_Patients, 
		CASE
			WHEN b.Carrier_Zip_Primary IS NULL OR
				 b.Carrier_Zip_Primary=b.NPPES_Zip OR b.Carrier_Zip_Secondary=b.NPPES_Zip THEN b.NPPES_Zip
			ELSE b.Carrier_Zip_Primary
		END AS Phy_Zip,
		CASE
			WHEN b.Carrier_Zip_Primary IS NULL OR
				 b.Carrier_Zip_Primary=b.NPPES_Zip OR b.Carrier_Zip_Secondary=b.NPPES_Zip THEN b.NPPES_State
			ELSE ''
		END AS Phy_State,
		CASE
			WHEN b.Carrier_Zip_Primary IS NULL OR
				 b.Carrier_Zip_Primary=b.NPPES_Zip OR b.Carrier_Zip_Secondary=b.NPPES_Zip THEN b.NPPES_City
			ELSE ''
		END AS Phy_City,
		b.NPPES_Update, b.Primary_Specialty AS Phy_Specialty, b.Primary_TaxID AS Phy_TaxID,
		c.Total_Admits AS Total_Hosp_Admits, c.Total_Patients AS Total_Hosp_Patients, 
		c.Total_McarePymt AS Total_Hosp_Pymt, c.Total_Charges AS Total_Hosp_Charges, c.Total_DRG AS Total_Hosp_DRG,
		c.Zip AS Hosp_Zip, c.State AS Hosp_State, c.Name AS Hosp_Name, c.City AS Hosp_City
		FROM WORK.Physicians_Hospitals AS a
		LEFT JOIN IMC969SL.Physician_Data_&year_data AS b
		ON a.OP_PHYSN_NPI=b.Physician_NPI
		LEFT JOIN IMC969SL.Hospital_Data_&year_data AS c
		ON a.ORG_NPI_NUM=c.ORG_NPI_NUM
		ORDER BY a.OP_PHYSN_NPI, a.ORG_NPI_NUM;
QUIT;


DATA IMC969SL.Physician_Choice_&year_data;
	SET IMC969SL.Physician_Choice_&year_data;
	distance=zipcitydistance(Phy_Zip, Hosp_Zip);
RUN;



