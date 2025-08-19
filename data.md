# Data

The data for our paper comes from several sources, the first three of which are proprietary:

1. **Medicare claims data.** These data are proprietary but available to researchers through the proper channels and fees. For this project, we have access to all inpatient, outpatient, and professional services claims for a 20% random sample of Medicare beneficiaries. We access the data through the CMS "Virtual Research Data Center". Info on gaining access to the VRDC can be found [here](https://www.resdac.org/cms-virtual-research-data-center-vrdc).

2. **SK&A data.** These data are propriety and available directly from SK&A (now OneKey) for a fee. The data include information on physician practices. Particularly relevant for our purposes is information on which (if any) hospital or hospital system owns a given physician practice.

3. **American Hospital Association survey data.** These data are proprietary and available from the AHA for a fee. The data include information on hospital characteristics such number of employees and system membership.

4. **Provider of Services files.** These are publicly available data that provide additional information on hospitals. Overall, the POS files contain much less hospital information than the AHA data, but there is some information here that is not available from the AHA surveys (either the variable isn't collected at all or just missing in some years). Adam Sacarny maintains a GitHub repo to help get started with these data, which can be accessed [here](https://github.com/asacarny/provider-of-services).

5. **Healthcare Cost Report Information System.** We use HCRIS data to collect information on hospitals, such as number of total discharges and measures of the counts of different employees. We maintain a separate GitHub repository for those interested in working with the HCRIS data, which can be accessed [here](https://github.com/imccart/HCRIS).

6. **American Community Survey.** These are publicly available data that we use to capture county-level demographic information. 


# Data Construction Overview

This document outlines the step-by-step process used to construct the analytic dataset for the project. The pipeline is organized in two stages: (1) initial processing of raw Medicare and provider-level data using SAS, and (2) integration, cleaning, and final dataset assembly using Stata. The files are organized in order of use to serve as a user manual for replication.

## Stage 1: Raw Data Processing (SAS)

The SAS scripts process raw CMS claims data and related administrative files to extract core components of the analytic dataset:

* **[1\_InpatientStays.sas](data-code/1_InpatientStays.sas)**: Processes raw inpatient claims to identify index admissions for episode construction. Applies filters to identify qualifying inpatient stays within a defined window and applies logic to identify the initial hospitalization per episode.
* **[2\_AllIPStays.sas](data-code/2_AllIPStays.sas)**: Constructs a comprehensive inpatient file for each beneficiary by merging inpatient claims over time. This dataset is used to evaluate total inpatient use (e.g., for spending and utilization outcomes).
* **[3\_OutpatientStays.sas](data-code/3_OutpatientStays.sas)**: Extracts and cleans outpatient claims from the outpatient SAF. Aggregates line-level data to the claim level, flags relevant claim types, and formats for later episode linkage.
* **[4\_PhysicianData.sas](data-code/4_PhysicianData.sas)**: Prepares physician identifiers using both NPPES and historical UPIN mappings ([NPPES\_Data.sas](data-code/NPPES_Data.sas), [UPIN2NPI\_Data.sas](data-code/UPIN2NPI_Data.sas)). Outputs a cleaned file linking physicians across years using consistent NPIs.
* **[5\_HospitalData.sas](data-code/5_HospitalData.sas)**: Extracts hospital characteristics from CMS Provider of Services files. Includes information on ownership, teaching status, and bed size.
* **[6\_BeneData.sas](data-code/6_BeneData.sas)**: Compiles patient demographics and enrollment status by year, including age, sex, race, and Medicaid dual-eligibility. Used to define patient covariates and sampling.
* **[7\_MedparData.sas](data-code/7_MedparData.sas)**: Processes MedPAR claims for completeness but is not used in the construction of the final analytic files. Included here to document the full scope of claims processing.
* **[8\_Episodes.sas](data-code/8_Episodes.sas)**: Constructs care episodes from inpatient and outpatient claims using a logic-based window around index admissions. Each episode represents a defined period of care surrounding a hospitalization.
* **[9\_OutcomeData.sas](data-code/9_OutcomeData.sas)**: Attaches quality outcomes to each episode, including 30-day mortality, 30-day readmission, and indicators of inpatient complications.

## Stage 2: Integration and Final Dataset Construction (Stata)

### Intermediate External Data Integration

These scripts incorporate data from external (non-claims) sources:

* **[PH1\_PhysicianHospitalIntegration.do](data-code/PH1_PhysicianHospitalIntegration.do)**: Constructs a binary indicator for whether a physician is vertically integrated with a hospital in each year. Uses hospital billing patterns and claim affiliations to define integration.
* **[PH2\_HCRIS\_Data.do](data-code/PH2_HCRIS_Data.do)**: Processes hospital cost report data from HCRIS. Merges staffing and ownership variables to hospitals using Medicare provider numbers.
* **[PH3\_Inpatient\_PPS\_Data.do](data-code/PH3_Inpatient_PPS_Data.do)**: Merges inpatient prospective payment system (IPPS) data to derive price-adjusted DRG weights. These are later used to adjust or stratify spending analyses.
* **[PH4\_AHA\_Data.do](data-code/PH4_AHA_Data.do)**: Processes AHA annual survey data to supplement hospital characteristics, including system affiliation and specialty services.
* **[PH5\_ACS\_Data.do](data-code/PH5_ACS_Data.do)**: Merges American Community Survey (ACS) county-level demographics. Constructs annual county-level controls (e.g., age, education, race, income).
* **[PH6\_SAS\_Hospitals.do](data-code/PH6_SAS_Hospitals.do)**: Integrates hospital data extracted in SAS into Stata for downstream merging.

### Construction of Analytic Components

* **[\_Spending\_Data.do](analysis/_Spending_Data.do)**: Merges claims data and constructs primary outcome variables: total spending, Medicare payments, and utilization. Applies top- and bottom-coding at 1st and 99th percentiles, and constructs log-transformed versions for regression analysis.
* **[\_Quality\_Data.do](analysis/_Quality_Data.do)**: Merges episode-level quality outcomes (mortality, readmission, complications) and creates flags for each. Ensures quality measures are consistently defined across DRGs.
* **[\_Effort\_Data.do](analysis/_Effort_Data.do)**: Calculates physician effort using claims-based counts of services. Effort is normalized by patient volume and specialty.
* **[\_Referral\_Data.do](analysis/_Referral_Data.do)**: Constructs referral-based measures of physician connectedness and market share, based on shared patient networks.
* **[\_Instruments\_Data.do](analysis/_Instruments_Data.do)**: Links PFS-derived revenue measures for constructing instruments related to integration incentives. Includes both individual physician and aggregate group-level metrics.
* **[\_PhysicianHospital\_Data.do](analysis/_PhysicianHospital_Data.do)**: Finalizes the physician-hospital analytic dataset by merging in spending, quality, physician, and hospital variables. Performs data integrity checks and creates flags for complete cases.

These components are merged and finalized in the analysis script `main.do`, which applies final clean-up, constructs analysis flags, and saves the dataset as `FinalEpisodesData.dta`.

## Notes

* The pipeline covers 2010–2015 Medicare data.
* Missing values are imputed using forward/backward fills or group-level means/maxima.
* Outliers are handled through winsorization at the 1st and 99th percentiles.




