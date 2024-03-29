# Analysis

Our primary analysis is contained in the [Analysis_Individual](analysis/_Analysis_Individual.do) Stata do file.

The file is organized in several sections, discussed in more detail below:

1. **Build Final Analytic Data:** This section of the code simply merges all of the relevant data for our analysis and imposes some final sample restrictions. In particular, since our instrument only has identifying variation beginning in 2010, we drop all inpatient stays prior to January 2010. We also drop any episodes for which we are unable to estimate quality outcomes.

2. **Initial Summary Statistics:** Form tables for summary stats and frequency histogram of procedures observed in the final data.

3. **Integration and Episode Spending and Claims:** Estimate the effects of integration on measures of spending and utilization. We first estimate effects using standard TWFE, event studies, and more recent DD estimators including those from Sun and Abraham as well as Callaway and Sant'Anna. We then estimate results from our preferred FE-IV strategy. 

4. **Integration and Quality:** We estimate the effects of integration on quality (measured by mortality, readmissions, or complications) using standard TWFE and FE-IV. These results are not central to the paper but are presented in the appendix and mentioned throughout the text.

5. **Effects of Integration on Components of Episodes:** We split episodes into specific care settings, including inpatient, outpatient, carrier (physician services), skilled nursing facility, and home health agency. We estimate the effects of integration on spending in each setting separately, first with our preferred FE-IV estimate as well as the DD estimator of Callaway and Sant'Anna.

6. **Unconditional Quantile Regressions:** The goal of this analysis is to examine differential effects of integration across the distribution of episode spending. Our prior is that the reduction in spending should be isolated among high-utilization episodes, which is supported by these results. 

7. **Plausibly exogenous estimation:** This section of the code considers the sensitivity of our FE-IV results to violations of the exclusion restriction. We essentially re-estimate the effect of integration under a range of assumptions on the extent of violation of the exclusion restriction (e.g., allowing for our instrument to directly affect spending/utilization to varying degrees).

7. **Referral Patterns within an Episode:** Within each episode, we quantify claims billed for by the same physician, by other integrated physicians, or by other non-integrated physicians. We estimate the effects of integration on each category of claims, where we are particularly interested in whether claims to the same physician or to other integrated physicians increases after integration, or whether claims to other non-integrated physicians decrease. We estimate these relationships with our preferred FE-IV estimator as well as the DD estimator of Callaway and Sant'Anna.

8. **Total Physician Effort (Count of Claims and Spending) by Year:** Here, we incorporate supplemental data on total physician billable activity for the year, and we estimate the effect of integration on total spending/billable activity. For completeness, we again estimate this with FE-IV, TWFE event studies, and Callaway and Sant'Anna DD estimators.

9. **Specification Charts:** We present our primary results on episode spending and claims across dozens of alternative sample restrictions and regression specifications. The goal of this analysis is to illustrate the robustness of our results to these types of decisions that must be made as part of any empirical analysis.