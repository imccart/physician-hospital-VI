# Replication files for "Owning the Agent: Hospital Influence on Physician Behaviors"

This repo organizes the necessary data and code files to replicate results for our paper, "Owning the Agent: Hospital Influence on Physician Behaviors". This project was supported in-part by grant number R000HS022431 from the Agency for Healthcare Research and Quality.

## Data
The data for our paper comes from several sources, the first three of which are proprietary:

1. **Medicare claims data.** These data are proprietary but available to researchers through the proper channels and fees. For this project, we have access to all inpatient, outpatient, and professional services claims for a 20% random sample of Medicare beneficiaries. We access the data through the CMS "Virtual Research Data Center". Info on gaining access to the VRDC can be found [here](https://www.resdac.org/cms-virtual-research-data-center-vrdc).

2. **SK&A data.** These data are propriety and available directly from SK&A for a fee. The data include information on physician practices. Particularly relevant for our purposes is information on which (if any) hospital system owns a given physician practice.

3. **American Hospital Association survey data.** These data are proprietary and available from the AHA for a fee. The data include information on hospital characteristics such number of employees and system membership.

4. **Provider of Services files.** These are publicly available data that provide additional information on hospitals. Overall, the POS files contain much less hospital information than the AHA data, but there is some information here that is not available from the AHA surveys (either the variable isn't collected at all or just missing in some years). Adam Sacarny maintains a GitHub repo to help get started with these data, which can be accessed [here](https://github.com/asacarny/provider-of-services).

5. **Healthcare Cost Report Information System.** We use HCRIS data to collect information on hospitals, such as number of total discharges and measures of the counts of different employees. We maintain a separate GitHub repository for those interested in working with the HCRIS data, which can be accessed [here](https://github.com/imccart/HCRIS).

6. **American Community Survey.** These are publicly available data that we use to capture county-level demographic information. 


## Initial Claims Data
Our central dataset is the Medicare claims data. We access these data through the VRDC and are subsequently limited to the software programs available in that environment (namely, SAS and Stata). Below is a list and brief description of the SAS code files used to create our final claims dataset. Note that a few of the files are no longer relevant for our analysis but were used at some point in earlier versions of the paper. We provide all code files for completeness, just in case someone is accessing this repo with a previous iteration of the paper in mind.

1. [Inpatient Stays](data-code/1_InpatientStays.SAS). This code file creates a table of all inpatient stays in a given year, excluding hospital transfers and admissions initiated in the ED. The goal is to focus only on "planned" admissions or elective surgeries.

2. [Physician Data](data-code/2_PhysicianData.SAS). This code file creates a table of unique physicians each year. Since our analysis focuses on episodes initiated by a planned and elective inpatient stay, we restrict this set of physicians to those observed as the operating physician in the inpatient stay files. In earlier years, we do not always observe physician NPIs. We find that information in three steps:
  1. look within inpatient claims (for the same year) to find physician NPI and UPIN
	matches; 
	2. match NPIs from UPIN_NPI NBER crosswalk files; and 
	3. match to first observed NPI in the NPPES files (for which historical versions are not available
	until 2010). Physician zip codes, tax ids, and specialties are taken from the carrier claims files when available, and otherwise from the NPPES files. Although the analysis relies more on the SK&A data for physician practice characteristics.

3. [Hospital Data](data-code/3_HospitalData.SAS). This code file creates a table of unique hospitals each year. In earlier years, we again do not always observe hospital NPIs. We find that information in three steps:
  1. look within the inpatient claims (for the same year) to find NPI and Provider Number
	matches; 
	2. match NPIs from the PRVDR_NPI NBER crosswalk files; and 
	3. match to observed NPI in the NPPES files. Hospital zip codes are taken from the POS files in earlier years where NPPES historical data are not available.

4. [Beneficiary Data](data-code/4_BeneData.SAS). Creates table of basic beneficiary demographics.

5. [Physician Admitting Priviledges](data-code/5_PhysicianChoiceSet.SAS). This code file creates a table of unique physicians and the set of hospitals to  which the physician is observed to have operated in that year, along with other variables describing the physician's practice, specialty, and location, and similarly the hospital's location and aggregate utilization. We ultimately combine this across all years to form the set of all hospitals in which a physician is observed to operate over our panel. The resulting data are used to construct our instrument.

6. [Patient Choice Set for Hospitals](data-code/6_PatientChoiceSet.SAS). In prior versions of the paper, we constructed an instrument based on the differential distance of the patient to physician practices and hospitals, and we used that information as part of a patient-level discrete choice model. The most recent version of the paper does not use this information, but we provide the code for completeness nonetheless.

7. [Total Beneficiary Spending](data-code/7_TotalInpatient.SAS). This code file began as an accumulation of all inpatient stays for each patient. It then expanded to include all inpatient and outpatient stays. The data are used to construct quantiles of patient utilization, which we employ in the empirical analysis as patient-level control variables.

8. [Other Inpatient Stays](data-code/8_OtherIPCare.SAS). This file collects all inpatient claims and spending for a patient incurred after the initial inpatient stay that started a given episode. We don't explicitly measure "episodes" at this point in the code...this is simply the inpatient stays that will ultimately go into the episode calculations.

9. [Outpatient Visits](data-code/9_OutpatientStays.SAS). This file collects all the outpatient stays. Similar to the code for other inpatient stays, these data will eventually be used to calculate the outpatient claims relevant for each episode.

10. [Matched Outpatient Visits](data-code/10_OutpatientMatched.SAS). This code file began as a specific calculation of outpatient claims assigned to the same physician-hospital pair as the initial inpatient stay. We no longer use these data in the paper.

11. [MedPar Data](data-code/11_MedparData.SAS). This code file was originally used to identify charges for specific revenue centers. We no longer use these data in the paper.

12. [Patient Choice Sets for Physicians](data-code/12_PatientChoiceSet_Physician.SAS). We experimented with estimating a patient choice model for specialist, and this code file constructs a dataset to do that analysis. This is incomplete and was never used in the paper.

13. [Carrier Claims](data-code/13_Carrier.SAS). This code file pulls all of the professional services claims from the carrier files for the patients identified in the original inpatient stays data. These data are used to construct the "professional services" component of the episodes.

14. [Outcome Data](data-code/14_OutcomeData.SAS). This code file identifies readmissions, mortality, and complications during or after the initial inpatient stays. We use these data for our quality measures in the supplemental analysis of the paper.

15. [Physician Referrals](data-code/15_ReferralAssignment.SAS). This code file identifies the primary care physician associated with each inpatient stay (where available). We used these data as an exploratory analysis of whether vertical integration changes the way in which operating physicians refer patients back to the PCP. This analysis was not ultimately in the final paper.


## Data clean up
