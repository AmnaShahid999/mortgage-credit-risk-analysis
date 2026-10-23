# Mortgage Risk Metric Definitions

## Project question

Which mortgage loans are more likely to fall behind on
payments, how does that risk change over time, and what
could it mean for the portfolio's future financial exposure?

We will analyze loan groups, predict serious delinquency,
and forecast outstanding and delinquent balances.

## 1. What each row represents

Each row represents one loan in one reporting month.

The combination of loan_id and reporting_month should
be unique. The same loan can appear in many different months.

## 2. Active loans

An active loan has a positive current outstanding balance
and no recorded termination effective on or before that month.

Outstanding balance means the principal still owed.

Loans with missing balances or inconsistent termination
information will be checked separately.

## 3. Delinquency categories

Delinquency means being behind on scheduled payments.

- 00: Current or less than 30 days late.
- 01: 30–59 days late.
- 02: 60–89 days late.
- Numeric codes 03–99: 90 or more days late.
- RA: Property acquired as real estate owned; tracked separately.
- XX or missing: Payment status unknown.

For older reporting periods, 00 can also represent a period
before the first payment is due.

Unknown statuses are not treated as current.

## 4. Loan-count 30+ delinquency rate

Question:
What percentage of eligible active loans are at least
30 days behind on payments that month?

Numerator:
Number of active loans with numeric delinquency codes 01–99.

Denominator:
Number of active loans with known numeric codes 00–99.

Calculation:
Numerator / denominator × 100.

Example:
If 3 of 10 eligible loans are 30+ days late, the rate is 30%.

Each loan counts equally, regardless of its balance.

Unknown and separately classified statuses are excluded
from this rate and reported alongside it.

## 5. Balance-weighted 30+ delinquency rate

Question:
What percentage of eligible outstanding money is associated
with loans that are at least 30 days behind?

Numerator:
Sum of current_balance for active loans with numeric
delinquency codes 01–99.

Denominator:
Sum of current_balance for active loans with known numeric
codes 00–99.

Calculation:
Numerator / denominator × 100.

Example:
If eligible loans have $1,000,000 outstanding and delinquent
loans account for $500,000, the rate is 50%.

Use current balance, not original balance.

This measures delinquent exposure. It does not mean that
the money has been lost.

## 6. Loan exits

A loan exit means the loan leaves the tracked portfolio.

Use zero_balance_code to identify the reason and
zero_balance_month to identify when termination takes effect.

Exclude terminated loans from active-loan rates once their
termination takes effect. Keep their records for exit analysis.

A voluntary payoff is not treated as default.
Other exit reasons will be classified using the source guide.

## 7. Missing monthly records

A missing record does not mean the loan is current or paid off.
Its status for that month is unknown.

For one-month payment-status changes, compare only records
exactly one calendar month apart.

Example:
April to June is a two-month gap, not a one-month transition.

## 8. Serious-delinquency prediction

Predict whether an eligible active loan will first reach
90+ days delinquent within the following 12 calendar months.

Numeric delinquency codes 03–99 identify 90+ delinquency.
REO and termination events are tracked separately.

Use only information available by the prediction date.

Early payoff or missing future records do not automatically
mean the loan had no serious-delinquency event.

Detailed eligibility and follow-up rules will be finalized
before building the model.

## 9. Comparing loan groups: vintages

A vintage groups loans by the year they originated.

We will compare loans originated in 2017, 2018, and 2019
at the same reported loan age.

Question:
Which group has more delinquency at a comparable loan age?

Initial proposed comparison window:
Reported loan ages 12–36 months, subject to data coverage checks.

Show how many eligible loans support each rate.
Flag groups with fewer than 100 observations as small samples.

Loan modifications can reset reported loan age, so we will
check these histories before making comparisons.

The window and minimum-count threshold are project choices.
Document any changes and why they were made.

## 10. Financial forecasting

Forecast the next three months of outstanding portfolio
balance and delinquent balance.

Evaluate forecasts using historical data:
choose a past month, use only information known through
that month, and compare predictions with the next three months.

Stress-period cutoff:
February 2020, forecasting March–May 2020, if coverage permits.

Calmer-period cutoff:
Choose a month with sufficient earlier history and three
subsequent observed months. Record the choice before
calculating forecast errors.

Use the same eligible population when connecting balances
and delinquency rates.

## 11. Interpretation limits

Delinquency does not automatically mean default or loss.

Differences between loan groups show associations,
not proof of what caused those differences.

Report missing information, excluded records, and sample
counts alongside results.

If a rate's denominator is zero, report the rate as unavailable,
rather than as zero.