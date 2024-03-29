# Data

The data for our paper comes from several sources, the first three of which are proprietary:

1. **Medicare claims data.** These data are proprietary but available to researchers through the proper channels and fees. For this project, we have access to all inpatient, outpatient, and professional services claims for a 20% random sample of Medicare beneficiaries. We access the data through the CMS "Virtual Research Data Center". Info on gaining access to the VRDC can be found [here](https://www.resdac.org/cms-virtual-research-data-center-vrdc).

2. **SK&A data.** These data are propriety and available directly from SK&A (now OneKey) for a fee. The data include information on physician practices. Particularly relevant for our purposes is information on which (if any) hospital or hospital system owns a given physician practice.

3. **American Hospital Association survey data.** These data are proprietary and available from the AHA for a fee. The data include information on hospital characteristics such number of employees and system membership.

4. **Provider of Services files.** These are publicly available data that provide additional information on hospitals. Overall, the POS files contain much less hospital information than the AHA data, but there is some information here that is not available from the AHA surveys (either the variable isn't collected at all or just missing in some years). Adam Sacarny maintains a GitHub repo to help get started with these data, which can be accessed [here](https://github.com/asacarny/provider-of-services).

5. **Healthcare Cost Report Information System.** We use HCRIS data to collect information on hospitals, such as number of total discharges and measures of the counts of different employees. We maintain a separate GitHub repository for those interested in working with the HCRIS data, which can be accessed [here](https://github.com/imccart/HCRIS).

6. **American Community Survey.** These are publicly available data that we use to capture county-level demographic information. 


<br>

## Initial Claims Data
Our central dataset is the Medicare claims data. We access these data through the VRDC and are subsequently limited to the software programs available in that environment (namely, SAS and Stata at the time we started this project). Below is a list and brief description of the SAS code files used to create our final claims dataset.

1. [Inpatient Stays](data-code/1_InpatientStays.sas). This code file creates a table of all inpatient stays in a given year, excluding hospital transfers and admissions initiated in the ED. The goal is to focus only on "planned" admissions or elective surgeries.

2. [Physician Data](data-code/2_PhysicianData.sas). This code file creates a table of unique physicians each year. Since our analysis focuses on episodes initiated by a planned and elective inpatient stay, we restrict this set of physicians to those observed as the operating physician in the inpatient stay files. In earlier years, we do not always observe physician NPIs. We find that information in three steps:
    
    a. look within inpatient claims (for the same year) to find physician NPI and UPIN matches; 
    b. match NPIs from UPIN_NPI NBER crosswalk files; and 
    c. match to first observed NPI in the NPPES files (for which historical versions are not available until 2010). Physician zip codes, tax ids, and specialties are taken from the carrier claims files when available, and otherwise from the NPPES files. Although the analysis relies more on the SK&A data for physician practice characteristics.

3. [Hospital Data](data-code/3_HospitalData.sas). This code file creates a table of unique hospitals each year. In earlier years, we again do not always observe hospital NPIs. We find that information in three steps:

    a. look within the inpatient claims (for the same year) to find NPI and Provider Number matches; 
    b. match NPIs from the PRVDR_NPI NBER crosswalk files; and 
    c. match to observed NPI in the NPPES files. Hospital zip codes are taken from the POS files in earlier years where NPPES historical data are not available.

4. [Beneficiary Data](data-code/4_BeneData.sas). Creates dataset of basic beneficiary demographics.

5. [Physician Admitting Priviledges](data-code/5_PhysicianChoiceSet.sas). This code file creates a table of unique physicians and the set of hospitals to  which the physician is observed to have operated in that year, along with other variables describing the physician's practice, specialty, and location, and similarly the hospital's location and aggregate utilization. We ultimately combine this across all years to form the set of all hospitals in which a physician is observed to operate over our panel. In prior versions of the paper, we used this information to construct an instrument based on the predicted probability of practice acquisition. This instrument has since been supplanted with the more direct instrument in the paper -- the predicted revenue increase due to the change in facility fees for an integrated versus non-integrated practice.

6. [Patient Choice Set for Hospitals](data-code/6_PatientChoiceSet.sas). In prior versions of the paper, we constructed an instrument based on the differential distance of the patient to physician practices and hospitals, and we used that information as part of a patient-level discrete choice model. The most recent version of the paper does not use this information, but we provide the code for completeness nonetheless.

7. [Total Beneficiary Spending](data-code/7_TotalInpatient.sas). This code file began as an accumulation of all inpatient stays for each patient. It then expanded to include all inpatient and outpatient stays. The data are used to construct quantiles of patient utilization, which we employ in the empirical analysis as patient-level covariates.

8. [Other Inpatient Stays](data-code/8_OtherIPCare.sas). This file collects all inpatient claims and spending for a patient incurred after the initial inpatient stay that started a given episode. We don't explicitly measure "episodes" at this point in the code...this is simply the inpatient stays that will ultimately go into the episode calculations.

9. [Outpatient Visits](data-code/9_OutpatientStays.sas). This file collects all the outpatient stays. Similar to the code for other inpatient stays, these data will eventually be used to calculate the outpatient claims relevant for each episode.

10. [Matched Outpatient Visits](data-code/10_OutpatientMatched.sas). This code file began as a specific calculation of outpatient claims assigned to the same physician-hospital pair as the initial inpatient stay. We no longer use these data in the paper.

11. [MedPar Data](data-code/11_MedparData.sas). This code file was originally used to identify charges for specific revenue centers. We no longer use these data in the paper.

12. [Patient Choice Sets for Physicians](data-code/12_PatientChoiceSet_Physician.sas). We experimented with estimating a patient choice model for specialist, and this code file constructs a dataset to do that analysis. This is incomplete and was never used in the paper.

13. [Carrier Claims](data-code/13_Carrier.sas). This code file pulls all of the professional services claims from the carrier files for the patients identified in the original inpatient stays data. These data are used to construct the "professional services" component of the episodes.

14. [Outcome Data](data-code/14_OutcomeData.sas). This code file identifies readmissions, mortality, and complications during or after the initial inpatient stays. We use these data for our quality measures in the supplemental analysis of the paper.

15. [Physician Referrals](data-code/15_ReferralAssignment.sas). This code file identifies the primary care physician associated with each inpatient stay (where available). We used these data as an exploratory analysis of whether vertical integration changes the way in which operating physicians refer patients back to the PCP. This analysis was not ultimately in the final paper.


<br>

## Data clean up

We export all of the SAS data as csv files and perform all additional data wrangling in Stata as follows:

1. [Physician Hospital Pairs](data-code/PhysicianHospital_Data.do). This file identifies all physician/hospital pairs and incorporates additional information about the physician practices and hospitals. The resulting dataset is at the physician/hospital/year level and includes our main independent variable of interest (i.e., an indicator for whether the physician practice is owned by a given hospital). This file calls the following code files in constructing the physician/hospital pairs: 

    a. [Integration Data](data-code/PH1_PhysicianHospitalIntegration.do). Match physicians to hospitals based on observed claims data and information on ownership status from SK&A.
  
    b. [HCRIS Data](data-code/PH2_HCRIS_Data.do). Construct hospital-level variables from cost reports. These data were created locally and then exported into the VRDC for use in this project. Please see the HCRIS GitHub repository [here](https://github.com/imccart/HCRIS) for more details on the creation of the hospital-level HCRIS data.
  
    c. [Inpatient PPS Final Rule](data-code/PH3_Inpatient_PPS_Data.do). Collect data on hospital case mix and other variables from the inpatient prospective payment system final rule files. These data were downloaded locally directly from CMS (publicly available) and then uploaded into the VRDC for use in this project.
  
    d. [AHA Data](data-code/PH4-AHA_Data.do). Collect data on hospital characteristics from the AHA annual surveys. These data are private but available for purchase from the AHA. The data were uploaded directly into the VRDC for use in this project.
  
    e. [ACS Data](data-code/PH5_ACS_Data.do). Collect county-level information (education, income, employment) from the American Community Survey. These data were created locally and uploaded into the VRDC for use in this project. 
  
    f. [VRDC Hospital Data](data-code/PH6_SAS_Hospitals.do). Collect hospital information based on observed claims data. The main purpose of this file is to identify a set of unique hospital NPIs based on inpatient stays from the VRDC claims data.
  
    g. [Pay for Performance Data](data-code/PH7_PFP_Data.do). Collect indicators for whether hospitals participated in certain pay for performance programs. The underlying data for this information come from the MEDPAR files.
  

2. [Episode Spending](data-code/_Spending_Data.do). Form total spending and indicators for discharge status for each episode.

3. [Episode Quality](data-code/_Quality_Data.do). Construct indicators for readmission, mortality, and complications for each episode.

4. [Referral Data](data-code/_Referral_Data.do). Decomposition of claims within an episode based on whether the billing physician is part of the same practice, some other integrated practice with the same hospital, or some other non-integrated practice. This information is used to measure whether newly acquired physicians are more likely to send patients to other practices owned by the same hospital.

5. [Instrumental Variables](data-code/_Instruments_Data.do). Construct our instrument following Dranove and Ody (2019). This file includes data that was created locally and imported for analysis within the VRDC. See the GitHub repository [here](https://github.com/imccart/PFS_Update_2010) for more details on the creation of these data and replication of Dranove and Ody (2019). 

6. [Total Billable Activity](data-code/_Efford_Data.do). Construct aggregate measures of annual physician billable activity. These data are used to quantify "physician effort" in the paper.