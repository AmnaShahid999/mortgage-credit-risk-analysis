# Data Dictionary: Expanded v2 Mortgage Data

## Scope and representation

Source: Freddie Mac annual loan-level samples for **2017, 2018, and 2019**. Source positions below follow the July 2026 layout used by the uploaded preparation script. Positions are **one-based positions in the original text files**, not positions in the prepared CSVs. Table rows follow the prepared CSV header order.

| Stage | Format and types |
|---|---|
| Original text | Pipe-delimited, no header; 31 origination fields and 35 performance fields. |
| Prepared v2 CSV | Comma-delimited, one header row; 17 origination and 31 performance columns. Raw values and codes are preserved as strings. |
| Compressed upload | `.csv.gz` contains the same CSV data; compression does not change columns or values. |
| Cleaned BigQuery join | Dates and numeric fields converted in SQL; categorical codes remain STRING. Types below describe the cleaned join, not the raw upload schema. |

The script intentionally selects a subset of source fields. Origination has one record per loan; performance has one record per loan per reporting month. Joining repeats the initial loan characteristics on each monthly observation.

## Origination: 17 selected fields

| CSV column | Source position | Cleaned BigQuery type | Meaning and units |
|---|---:|---|---|
| `loan_id` | 20 | `STRING` | Loan identifier; join key, preserved as text. |
| `credit_score` | 1 | `INT64` | Original credit score; 9999 is unavailable. |
| `first_payment_month` | 2 | `DATE` | Month of the first scheduled payment. |
| `original_dti` | 10 | `INT64` | Original debt-to-income ratio, percentage points; 999 is unavailable. |
| `original_balance` | 11 | `NUMERIC` | Original unpaid principal balance, USD. |
| `original_ltv` | 12 | `INT64` | Original loan-to-value ratio, percentage points; 999 is unavailable. |
| `loan_purpose` | 21 | `STRING` | Coded purpose of the loan, such as purchase or refinance. |
| `original_interest_rate` | 13 | `NUMERIC` | Original interest rate, percentage points. |
| `original_loan_term` | 22 | `INT64` | Original scheduled loan term, months. |
| `occupancy_status` | 8 | `STRING` | Coded occupancy classification. |
| `property_state` | 17 | `STRING` | State or territory code for the property. |
| `channel` | 14 | `STRING` | Coded origination channel. |
| `first_time_homebuyer` | 3 | `STRING` | First-time homebuyer indicator; preserve source codes. |
| `number_of_borrowers` | 23 | `INT64` | Number of borrowers; 99 is unavailable. |
| `original_cltv` | 9 | `INT64` | Original combined loan-to-value ratio, including relevant subordinate financing, percentage points; 999 is unavailable. |
| `mortgage_insurance_pct` | 6 | `INT64` | Mortgage insurance coverage percentage; 999 is unavailable. Zero is distinct from missing. |
| `maturity_month` | 4 | `DATE` | Original scheduled maturity month. |

## Monthly performance: 31 selected fields

| CSV column | Source position | Cleaned BigQuery type | Meaning and units |
|---|---:|---|---|
| `loan_id` | 1 | `STRING` | Loan identifier; links to origination. |
| `reporting_month` | 2 | `DATE` | Month of the reported loan observation. |
| `current_balance` | 3 | `NUMERIC` | Current actual unpaid principal balance, USD; rate weight in this project. |
| `delinquency_status` | 4 | `STRING` | Payment delinquency code; retain leading zeros and special text codes. |
| `loan_age` | 5 | `INT64` | Source-reported loan age in months; can reset following modification and repeat on terminal records. |
| `zero_balance_code` | 9 | `STRING` | Coded reason for removal or zero balance; does not by itself mean a credit loss. |
| `zero_balance_month` | 10 | `DATE` | Effective month of the zero-balance event; blank means no date recorded in that row. |
| `current_interest_rate` | 11 | `NUMERIC` | Reported current interest rate, percentage points. |
| `modification_flag` | 8 | `STRING` | Source modification indicator; retained as a code. The vintage filter requires a cleaned null. |
| `borrower_assistance_plan` | 30 | `STRING` | Coded borrower assistance plan. |
| `delinquency_due_to_disaster` | 29 | `STRING` | Source indicator for delinquency associated with a disaster. |
| `payment_deferral_flag` | 25 | `STRING` | Source payment-deferral indicator. |
| `remaining_months_to_maturity` | 6 | `INT64` | Reported remaining months to maturity. |
| `defect_settlement_month` | 7 | `DATE` | Month associated with a defect settlement, when reported. |
| `current_non_interest_bearing_balance` | 12 | `NUMERIC` | Current non-interest-bearing unpaid principal balance, USD. |
| `last_paid_installment_month` | 13 | `DATE` | Month of the last paid installment. |
| `mi_recoveries` | 14 | `NUMERIC` | Mortgage insurance recoveries, USD. |
| `net_sales_proceeds` | 15 | `NUMERIC` | Net sale proceeds, USD, when numeric; special source text is preserved separately in SQL. |
| `non_mi_recoveries` | 16 | `NUMERIC` | Recoveries other than mortgage insurance, USD. |
| `total_expenses` | 17 | `NUMERIC` | Source-reported total expenses, USD; do not add component expense fields again. |
| `legal_costs` | 18 | `NUMERIC` | Reported legal costs, USD. |
| `maintenance_preservation_costs` | 19 | `NUMERIC` | Property maintenance and preservation costs, USD. |
| `taxes_insurance` | 20 | `NUMERIC` | Reported taxes and insurance expenses, USD. |
| `miscellaneous_expenses` | 21 | `NUMERIC` | Other reported expenses, USD. |
| `actual_loss` | 22 | `NUMERIC` | Source-reported actual loss, USD; interpret using source methodology, timing, and sign conventions. |
| `cumulative_modification_costs` | 23 | `NUMERIC` | Cumulative modification costs, USD; not a monthly incremental amount. |
| `zero_balance_removal_balance` | 27 | `NUMERIC` | UPB at removal under the source definition, USD. |
| `delinquent_accrued_interest` | 28 | `NUMERIC` | Reported delinquent accrued interest, USD. |
| `current_period_modification_costs` | 31 | `NUMERIC` | Modification costs attributed to the current reporting period, USD. |
| `current_interest_bearing_balance` | 32 | `NUMERIC` | Current interest-bearing unpaid principal balance, USD. |
| `bankruptcy_cramdown_costs` | 35 | `NUMERIC` | Reported bankruptcy cramdown costs, USD. |

## Cleaning and missing values

- `TRIM` removes surrounding whitespace. `NULLIF(TRIM(value), '')` converts blank text to SQL NULL where used.
- `SAFE_CAST` converts numeric text; unparseable values become NULL. A numeric special code remains numeric unless explicitly converted to NULL first.
- Month fields use `SAFE.PARSE_DATE('%Y%m', ...)`; the cleaned date represents the first day of that month, not the exact payment or event day.
- The join script explicitly replaces unavailable codes: credit score `9999`; DTI, LTV, CLTV, and mortgage insurance percentage `999`; borrower count `99`.
- A blank is not zero. In particular, missing balances, expenses, and recoveries should not automatically be treated as zero.
- Preserve categorical codes as text. Use the matching source guide for complete category definitions and special-code handling before extending the analysis.
- Loss-related fields are prepared for future work; including them does not mean a loss model or loss reconciliation has been completed. Do not sum cumulative and period-specific measures together.

## Important status and date distinctions

| Field or concept | Interpretation for this project |
|---|---|
| Reporting month | The month in which the loan's condition is observed. |
| First payment month | The initial scheduled payment month; distinct from the reporting month. |
| Loan age | Source-reported months of age; not guaranteed to be a continuously increasing calendar counter after modifications. |
| Zero-balance month | Month of a recorded removal/zero-balance event. It can reflect different exit reasons, not only normal repayment. |
| Modification flag | A source code, not a Boolean. Observed modified examples include `Y` and subsequent `P` records. The current analysis retains only cleaned null flags. |
| Delinquency `00` | Current or less than 30 days delinquent. |
| Delinquency `01` | 30–59 days delinquent. |
| Delinquency `02` | 60–89 days delinquent. |
| Numeric delinquency `03`–`99` | Increasing monthly delinquency categories, treated as 90+ for this project's grouping. |
| Delinquency `RA` | Special REO-acquisition status, outside the numeric denominator. |
| Nonnumeric or missing status | Outside the numeric 00–99 denominator; tracked separately. |

`SAFE_CAST(delinquency_status AS INT64)` is used for rate classification while retaining the original code. A status of 01–99 identifies 30+ delinquency, not an observed realized loss.

## Added fields in the cleaned join

| Field | Type | Meaning |
|---|---|---|
| `origination_year` | INT64 | Annual sample label assigned by SQL: 2017, 2018, or 2019. |
| `has_origination_match` | BOOL | Whether the left-joined monthly record found an origination record. |
| `net_sales_proceeds_raw` | STRING | Trimmed source proceeds value, preserving special text lost by numeric conversion. |

The two source `loan_id` fields become a single cleaned identifier. These derived fields are not additional Python CSV columns.

## Derived vintage-summary fields

Grain: **one row per annual vintage and loan age**. The Tableau curve export selects ages 12–36.

| Field | Type | Definition |
|---|---|---|
| `origination_year` | INT64 | Annual vintage label. |
| `loan_age` | INT64 | Source-reported age, months. |
| `active_pre_modification_records` | INT64 | Records meeting the population filters before status eligibility is applied. |
| `eligible_loans` | INT64 | Eligible records with numeric delinquency status 00–99. Represents loans at a given age only after loan-age uniqueness checks. |
| `delinquent_30plus_loans` | INT64 | Eligible records with numeric delinquency status 01–99. |
| `eligible_balance` | NUMERIC | Sum of current balances for eligible status 00–99 records, USD. |
| `balance_30plus` | NUMERIC | Sum of current balances for eligible status 01–99 records, USD. |
| `excluded_status_records` | INT64 | Otherwise eligible records with missing, nonnumeric, or out-of-range status. |
| `excluded_status_balance` | NUMERIC | Current balances attached to those excluded-status records, USD. |
| `loan_count_30plus_pct` | Numeric percentage | 100 × delinquent_30plus_loans / eligible_loans, rounded to two decimals using SAFE_DIVIDE. |
| `balance_weighted_30plus_pct` | Numeric percentage | 100 × balance_30plus / eligible_balance, rounded to two decimals using SAFE_DIVIDE. |

`status_numeric` is an intermediate INT64 conversion used in the summary CTE; it is not retained in the final summary table. A zero denominator gives NULL rather than a division error.

## Population used by the vintage rates

```sql
WHERE reporting_month IS NOT NULL
  AND loan_age IS NOT NULL
  AND modification_flag IS NULL
  AND current_balance > 0
  AND (
      zero_balance_month IS NULL
      OR zero_balance_month > reporting_month
  )
```

Numeric status 00–99 then defines the common denominator for both rates. Keeping records with no zero-balance date allows ongoing loans to remain eligible. Using `delinquency_status > 0` in place of `current_balance > 0` would incorrectly remove current loans from the denominator.

Rates are percentage-point values: `6.12` means 6.12%. Balance-weighted delinquency measures outstanding principal exposure associated with delinquent loans, not money lost or installments overdue. When it exceeds the loan-count rate, delinquent loans have larger average balances than the eligible population overall. Counts across multiple ages are repeated observations and must not be presented as unique loans.
