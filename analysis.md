# Analysis

Our primary analysis is contained in the [_main](analysis/_m.do) Stata do file.

The script sets up the environment, constructs the analytic dataset from multiple raw data sources, performs extensive data cleaning (including outlier winsorization and imputation of missing values), and creates log-transformed variables for use in downstream analysis. It then saves the final cleaned dataset and sequentially runs several analysis scripts related to summary statistics, episode-level outcomes, physician effort, and supplemental analyses. The final analytic dataset (`FinalEpisodesData.dta`) is a patient-episode-level panel covering 2010–2015, with each observation linked to a physician, hospital, and geographic area. It includes:

* **Outcome variables**: Raw and log-transformed spending, utilization, and quality metrics (e.g., episode charge, RVUs, readmissions, mortality).
* **Provider characteristics**: Physician and hospital variables including size, experience, integration status, and staffing.
* **Geographic context**: County-level demographics and market structure (e.g., monopoly/duopoly).
* **Instrumental variables**: Physician revenue measures from external datasets.
* **Identifiers**: Physician-hospital pairs, geographic codes (FIPS), and derived grouping variables.

The dataset has been cleaned of extreme outliers and missing covariates via winsorization, forward/backward filling, and mean/max imputation. The script then calls the following do files in order:

1. [Summary Statistics](analysis/1_summary_stats.do): Generates descriptive statistics and summary tables (Tables 1–3) for episodes, physicians, and hospitals from the episode level data, disaggregated by year and integration status. It also produces a histogram of high-frequency DRG codes (Figure 1) and explores the timing and prevalence of vertical integration among physician-hospital pairs.

2. [Episode Analysis](analysis/2_episodes.do): This script runs a series of episode-level regressions to estimate the relationship between vertical integration and outcomes such as spending, utilization, and quality. It includes progressively saturated specifications with patient-level controls, market characteristics, and fixed effects for DRG, year, physician, hospital, and geography. The code outputs the majority of the tables and figures reported in the main text and appendix, including key results on the effects of vertical integration.

3. [Physician Effort](analysis/3_physician_effort.do): This script analyzes physician effort by examining RVUs, total physician spending and operations, and their relationships to vertical integration. It includes regressions on physician-level data, exploring how integration affects productivity and work patterns.

4. [Supplemental Analyses](analysis/4_supplemental.do): This script runs additional analyses to test robustness and explore alternative specifications, including specification charts and a "plausibly exogenous" extension to examine the extent of selection bias necessary to explain the observed effects of integration.