SELECT
    origination_year,
    loan_age,
    eligible_loans,
    delinquent_30plus_loans,
    eligible_balance,
    balance_30plus,
    loan_count_30plus_pct,
    balance_weighted_30plus_pct
FROM `mortgage-credit-risk-analytics.mortgage_risk.vintage_summary`
WHERE loan_age BETWEEN 12 AND 36
ORDER BY origination_year, loan_age;