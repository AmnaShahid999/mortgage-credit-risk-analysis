# Mortgage Portfolio Risk and Financial Forecasting

A mortgage portfolio analytics project using Freddie Mac sample loans from the **2017, 2018, and 2019 vintages**, with Python for preparation, BigQuery for analysis, and Tableau for visualization.

## Business question

How does 30+ day mortgage delinquency vary as loans age, and how do the three annual loan cohorts compare at the same loan age? Do delinquent loans account for a larger share of outstanding balances than of loan counts?

## Completed work

- Prepared expanded v2 CSVs for all three years, preserving raw codes and validating source field counts.
- Loaded origination and monthly performance data into BigQuery and investigated missing values, duplicate keys, and repeated loan ages.
- Joined monthly performance to origination characteristics and converted strings to analysis-ready dates and numeric fields.
- Compared loan-count and balance-weighted 30+ delinquency rates across vintages.
- Created a Tableau dashboard comparing the two measures at loan ages 12–36.
- Documented findings, population rules, and interpretation limits.

**Status:** Historical vintage analysis and the Tableau workbook are complete. Forecasting, transition analysis, and machine learning are planned extensions. SQL publication cleanup remains: the uploaded learning scripts include drafts and inconsistent table references. A public Tableau URL has not yet been added.

## Data and structure

Source: Freddie Mac Single-Family Loan-Level Dataset, annual samples for 2017–2019. The preparation script uses the July 2026 file layout.

| File | Grain | v2 columns |
|---|---|---:|
| Origination | One row per loan | 17 |
| Monthly performance | One row per loan per reporting month | 31 |

The source text files are pipe-delimited without headers. Python selects the v2 fields, writes comma-delimited files with headers, and produces gzip copies for upload. Values remain strings during preparation; cleaning occurs in SQL. Monthly performance is the left table in the join on trimmed loan IDs, preserving performance rows even when origination is unmatched.

The annual sample label is used as `origination_year`. An annual vintage includes loans observed in different calendar months; it is not a single calendar-month cohort. Joined data remain at loan-month grain. Repeated loan ages can arise following modifications or on terminal records and should not automatically be deleted as duplicates.

## Measures and eligibility

For this vintage analysis, a record must have:

- A nonmissing reporting month and loan age.
- A positive current balance.
- A null cleaned modification flag, identifying the analysis's pre-modification population.
- No recorded zero-balance month, or a zero-balance month later than the reporting month.

Within that population, numeric delinquency statuses **00–99** form the denominator; **01–99** identify 30+ delinquency. Unknown or nonnumeric statuses are excluded from both rate denominators and tracked separately.

- **Loan-count rate:** 30+ delinquent loan records ÷ eligible known-status loan records × 100.
- **Balance-weighted rate:** current balance of 30+ delinquent records ÷ current balance of eligible known-status records × 100.

At a single age, record counts represent loan counts only after checking that each loan has at most one eligible record at that age. Counts summed across ages are repeated observations, not unique borrowers or loans. Rate fields store percentage-point values: `5.00` means 5%, so Tableau must not multiply them by 100 again.

## Selected results

| Loan age (months) | Vintage | Eligible loans | 30+ delinquent loans | Loan-count rate | Balance-weighted rate |
|---:|---:|---:|---:|---:|---:|
| 12 | 2017 | 46,788 | 394 | 0.84% | 0.81% |
| 12 | 2018 | 44,169 | 421 | 0.95% | 0.92% |
| 12 | 2019 | 39,717 | 1,508 | 3.80% | 4.47% |
| 24 | 2017 | 42,801 | 554 | 1.29% | 1.32% |
| 24 | 2018 | 30,411 | 1,589 | 5.23% | 6.17% |
| 24 | 2019 | 24,092 | 922 | 3.83% | 4.57% |
| 36 | 2017 | 32,560 | 1,629 | 5.00% | 6.12% |
| 36 | 2018 | 18,147 | 955 | 5.26% | 6.67% |
| 36 | 2019 | 18,309 | 433 | 2.36% | 2.69% |

These are the final comparison results supplied for the dashboard, rather than the earlier exploratory figures. They have not been independently rerun in BigQuery as part of this documentation update.

The 2017 vintage's rates rise across these checkpoints. The 2018 loan-count rate rises sharply by age 24 and is nearly unchanged at age 36. The 2019 rate declines between ages 24 and 36, so increasing delinquency with age is not a universal pattern.

At age 36, all three balance-weighted rates exceed the corresponding loan-count rates. This means delinquent loans have larger average outstanding balances than eligible loans overall. Algebraically, the balance-weighted rate divided by the loan-count rate equals the average delinquent balance divided by the average eligible balance, using unrounded values. Outstanding delinquent balances do not equal losses or overdue payment amounts.

## Interpretation limits

Equal loan ages occur in different calendar periods across vintages. Exits, repayment, modification exclusions, and missing statuses change the observed population. These descriptive rates therefore combine loan aging, calendar conditions, and population selection; they do not establish causality, default probabilities, realized losses, or forecast performance. Results describe the selected samples and eligible population.

## Project files

| File | Purpose |
|---|---|
| `prepare_file_v2` | Uploaded Python preparation script; save as a `.py` file inside the project's `python` folder before running. |
| `inspect_files.py` | Initial source-file inspection. |
| `sql_01_origination_checks.sql` | Origination quality checks. |
| `sql_02_performance checks.sql` | Performance quality checks. |
| `sql_03_join_checks.sql` | Cleaning, joining, and join validation. |
| `sql_04_vintage_summary_2017, 2018, 2019.sql` | Exploratory queries and final combined vintage summary. |
| `sql_05_vintage_curves.sql` | Ages 12–36 summary export for Tableau. |
| `data_dictionary.md` | All selected v2 fields, types, and derived measures. |
| `metric_definitions.md` | Business metric definitions. |
| `Vintage_Analysis_Summary(1).md` | Detailed written analysis. |
| `Mortgage Vintage Analysis Dashboard.twbx` | Packaged Tableau workbook. |

## Reproducing the analysis

1. Obtain the annual sample files and matching guide from Freddie Mac. Place each extracted pair in `sample_2017`, `sample_2018`, and `sample_2019` under the project folder.
2. Save the preparation script inside `python`. Set `YEAR` for each annual run. Use `ROW_LIMIT = 5` to inspect previews, then `None` to generate full files in `prepared_data_v2`.
3. Upload the full CSV or gzip files to BigQuery as raw string fields, skipping the single CSV header row. Preserve the raw codes for SQL cleaning.
4. Resolve the documented SQL naming and draft-query issues before running the scripts in order. Use project `mortgage-credit-risk-analytics`, dataset `mortgage_risk`.
5. Validate missing and duplicate loan IDs, loan-month uniqueness, unmatched joins, and whether the join multiplies rows. Then validate loan-age uniqueness after the vintage filters.
6. Run the final combined-summary statement to build `vintage_summary`; export the ages 12–36 query for Tableau. Confirm the selected results above against the output.
7. Open the Tableau workbook and refresh its source using the exported summary. Compare both rates on consistent axes and verify the population note.

The final summary currently reads `loan_monthly_analysis_2017`, `2018_loan_monthly_analysis`, and `2019_loan_monthly_analysis`. The join script currently creates the 2017 table as `2017_loan_monthly_analysis`; reconcile that name before rerunning. Its 2017 unmatched-join check also has a raw performance-table naming discrepancy.

## Next steps

1. Finish SQL cleanup and add the Tableau Public dashboard link.
2. Build calendar-month portfolio actuals and a simple balance forecast, with a defined forecasting population, chronological holdout, and baseline comparison. This is separate from the pre-modification vintage population.
3. Add transition and segmentation analysis.
4. Develop a future serious-delinquency prediction model with an explicit target, observation window, and checks against information leakage.
5. Extend to scenario analysis and financial planning outputs.

Publish code, documentation, and suitable aggregate outputs in the portfolio repository. Keep source and prepared loan-level files out of the public repository; review the source data terms before distributing data or embedding downloadable workbook data. Add the public dashboard link once published.
