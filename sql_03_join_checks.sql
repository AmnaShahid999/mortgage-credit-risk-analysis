#Table 1: raw_origination_v2
#Table 2: raw_performance_2017_v2

CREATE OR REPLACE TABLE   `mortgage_risk.2017_loan_monthly_analysis` AS

SELECT
    TRIM(perf.loan_id) AS loan_id,
    2017 AS origination_year,

    -- Reporting month and monthly performance
    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.reporting_month), '')
    ) AS reporting_month,

    SAFE_CAST(TRIM(perf.current_balance) AS NUMERIC)
        AS current_balance,

    NULLIF(TRIM(perf.delinquency_status), '')
        AS delinquency_status,

    SAFE_CAST(TRIM(perf.loan_age) AS INT64)
        AS loan_age,

    NULLIF(TRIM(perf.zero_balance_code), '')
        AS zero_balance_code,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.zero_balance_month), '')
    ) AS zero_balance_month,

    SAFE_CAST(TRIM(perf.current_interest_rate) AS NUMERIC)
        AS current_interest_rate,

    NULLIF(TRIM(perf.modification_flag), '')
        AS modification_flag,

    NULLIF(TRIM(perf.borrower_assistance_plan), '')
        AS borrower_assistance_plan,

    NULLIF(TRIM(perf.delinquency_due_to_disaster), '')
        AS delinquency_due_to_disaster,

    NULLIF(TRIM(perf.payment_deferral_flag), '')
        AS payment_deferral_flag,

    SAFE_CAST(TRIM(perf.remaining_months_to_maturity) AS INT64)
        AS remaining_months_to_maturity,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.defect_settlement_month), '')
    ) AS defect_settlement_month,

    SAFE_CAST(
        TRIM(perf.current_non_interest_bearing_balance) AS NUMERIC
    ) AS current_non_interest_bearing_balance,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.last_paid_installment_month), '')
    ) AS last_paid_installment_month,

    -- Loss information
    SAFE_CAST(TRIM(perf.mi_recoveries) AS NUMERIC)
        AS mi_recoveries,

    -- Preserve special text codes alongside the numeric conversion
    NULLIF(TRIM(perf.net_sales_proceeds), '')
        AS net_sales_proceeds_raw,

    SAFE_CAST(TRIM(perf.net_sales_proceeds) AS NUMERIC)
        AS net_sales_proceeds,

    SAFE_CAST(TRIM(perf.non_mi_recoveries) AS NUMERIC)
        AS non_mi_recoveries,

    SAFE_CAST(TRIM(perf.total_expenses) AS NUMERIC)
        AS total_expenses,

    SAFE_CAST(TRIM(perf.legal_costs) AS NUMERIC)
        AS legal_costs,

    SAFE_CAST(TRIM(perf.maintenance_preservation_costs) AS NUMERIC)
        AS maintenance_preservation_costs,

    SAFE_CAST(TRIM(perf.taxes_insurance) AS NUMERIC)
        AS taxes_insurance,

    SAFE_CAST(TRIM(perf.miscellaneous_expenses) AS NUMERIC)
        AS miscellaneous_expenses,

    SAFE_CAST(TRIM(perf.actual_loss) AS NUMERIC)
        AS actual_loss,

    SAFE_CAST(TRIM(perf.cumulative_modification_costs) AS NUMERIC)
        AS cumulative_modification_costs,

    SAFE_CAST(TRIM(perf.zero_balance_removal_balance) AS NUMERIC)
        AS zero_balance_removal_balance,

    SAFE_CAST(TRIM(perf.delinquent_accrued_interest) AS NUMERIC)
        AS delinquent_accrued_interest,

    SAFE_CAST(
        TRIM(perf.current_period_modification_costs) AS NUMERIC
    ) AS current_period_modification_costs,

    SAFE_CAST(
        TRIM(perf.current_interest_bearing_balance) AS NUMERIC
    ) AS current_interest_bearing_balance,

    SAFE_CAST(TRIM(perf.bankruptcy_cramdown_costs) AS NUMERIC)
        AS bankruptcy_cramdown_costs,

    -- Initial loan characteristics
    SAFE_CAST(
        NULLIF(TRIM(orig.credit_score), '9999') AS INT64
    ) AS credit_score,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(orig.first_payment_month), '')
    ) AS first_payment_month,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_dti), '999') AS INT64
    ) AS original_dti,

    SAFE_CAST(TRIM(orig.original_balance) AS NUMERIC)
        AS original_balance,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_ltv), '999') AS INT64
    ) AS original_ltv,

    NULLIF(TRIM(orig.loan_purpose), '')
        AS loan_purpose,

    SAFE_CAST(TRIM(orig.original_interest_rate) AS NUMERIC)
        AS original_interest_rate,

    SAFE_CAST(TRIM(orig.original_loan_term) AS INT64)
        AS original_loan_term,

    NULLIF(TRIM(orig.occupancy_status), '')
        AS occupancy_status,

    NULLIF(TRIM(orig.property_state), '')
        AS property_state,

    NULLIF(TRIM(orig.channel), '')
        AS channel,

    NULLIF(TRIM(orig.first_time_homebuyer), '')
        AS first_time_homebuyer,

    SAFE_CAST(
        NULLIF(TRIM(orig.number_of_borrowers), '99') AS INT64
    ) AS number_of_borrowers,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_cltv), '999') AS INT64
    ) AS original_cltv,

    SAFE_CAST(
        NULLIF(TRIM(orig.mortgage_insurance_pct), '999') AS INT64
    ) AS mortgage_insurance_pct,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(orig.maturity_month), '')
    ) AS maturity_month,

    orig.loan_id IS NOT NULL AS has_origination_match

    from  `mortgage_risk.raw_performance_2017_v2` as perf

left join  `mortgage_risk.raw_origination_v2` as orig
on
trim(perf.loan_id)=trim(orig.loan_id);


#how to decide what to keep on the left during a left join-the values that must stay even if the other values are absent

#Check whether any origination duplicate multiplied the performance records-this means whether origination showed records where there were none

#this means we are keeping performance on the left and joining origination from the right

SELECT
    COUNT(*) AS unmatched_performance_rows,
    COUNT(DISTINCT perf.loan_id) AS unmatched_loans
FROM `mortgage_risk.monthly_raw_performance_2017_v2` as perf
left join `mortgage_risk.raw_origination_v2` as original
on
perf.loan_id = original.loan_id
where original.loan_id is null;

#making sure each of the entries in the table is numeric and properly formatted

/*SAFE_CAST converts text into numbers.
NULLIF replaces blank strings or specified unavailable codes with NULL.
SAFE.PARSE_DATE converts year-month text into dates.
Delinquency and zero-balance codes remain text, preserving codes such as 00 and RA.
has_origination_match records TRUE or FALSE for whether origination matched.
2017 identifies the source origination cohort.*/

SELECT
    COUNT(*) AS total_rows,
    COUNTIF(NOT has_origination_match) AS unmatched_rows,
    COUNTIF(reporting_month IS NULL) AS missing_reporting_months
FROM `mortgage_risk.loan_monthly_analysis_2017`;


SELECT
    loan_id,
    reporting_month,
    COUNT(*) AS occurrences
FROM `mortgage_risk.loan_monthly_analysis_2017`
GROUP BY loan_id, reporting_month
HAVING COUNT(*) > 1;

#2018
CREATE OR REPLACE TABLE `mortgage_risk.2018_loan_monthly_analysis` AS
SELECT
    perf.*,
    orig.* EXCEPT (loan_id),
    2018 AS origination_year,
    orig.loan_id IS NOT NULL AS has_origination_match
FROM `mortgage_risk.raw_performance_2018` AS perf
LEFT JOIN `mortgage_risk.raw_origination_2018` AS orig
    ON NULLIF(TRIM(perf.loan_id), '')
     = NULLIF(TRIM(orig.loan_id), '');

CREATE OR REPLACE TABLE `mortgage_risk.2018_loan_monthly_analysis` AS

SELECT
    TRIM(perf.loan_id) AS loan_id,
    2018 AS origination_year,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.reporting_month), '')
    ) AS reporting_month,

    SAFE_CAST(TRIM(perf.current_balance) AS NUMERIC)
        AS current_balance,

    NULLIF(TRIM(perf.delinquency_status), '')
        AS delinquency_status,

    SAFE_CAST(TRIM(perf.loan_age) AS INT64)
        AS loan_age,

    NULLIF(TRIM(perf.zero_balance_code), '')
        AS zero_balance_code,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.zero_balance_month), '')
    ) AS zero_balance_month,

    SAFE_CAST(TRIM(perf.current_interest_rate) AS NUMERIC)
        AS current_interest_rate,

    NULLIF(TRIM(perf.modification_flag), '')
        AS modification_flag,

    NULLIF(TRIM(perf.borrower_assistance_plan), '')
        AS borrower_assistance_plan,

    NULLIF(TRIM(perf.delinquency_due_to_disaster), '')
        AS delinquency_due_to_disaster,

    NULLIF(TRIM(perf.payment_deferral_flag), '')
        AS payment_deferral_flag,

    SAFE_CAST(TRIM(perf.remaining_months_to_maturity) AS INT64)
        AS remaining_months_to_maturity,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.defect_settlement_month), '')
    ) AS defect_settlement_month,

    SAFE_CAST(
        TRIM(perf.current_non_interest_bearing_balance) AS NUMERIC
    ) AS current_non_interest_bearing_balance,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.last_paid_installment_month), '')
    ) AS last_paid_installment_month,

    SAFE_CAST(TRIM(perf.mi_recoveries) AS NUMERIC)
        AS mi_recoveries,

    NULLIF(TRIM(perf.net_sales_proceeds), '')
        AS net_sales_proceeds_raw,

    SAFE_CAST(TRIM(perf.net_sales_proceeds) AS NUMERIC)
        AS net_sales_proceeds,

    SAFE_CAST(TRIM(perf.non_mi_recoveries) AS NUMERIC)
        AS non_mi_recoveries,

    SAFE_CAST(TRIM(perf.total_expenses) AS NUMERIC)
        AS total_expenses,

    SAFE_CAST(TRIM(perf.legal_costs) AS NUMERIC)
        AS legal_costs,

    SAFE_CAST(TRIM(perf.maintenance_preservation_costs) AS NUMERIC)
        AS maintenance_preservation_costs,

    SAFE_CAST(TRIM(perf.taxes_insurance) AS NUMERIC)
        AS taxes_insurance,

    SAFE_CAST(TRIM(perf.miscellaneous_expenses) AS NUMERIC)
        AS miscellaneous_expenses,

    SAFE_CAST(TRIM(perf.actual_loss) AS NUMERIC)
        AS actual_loss,

    SAFE_CAST(TRIM(perf.cumulative_modification_costs) AS NUMERIC)
        AS cumulative_modification_costs,

    SAFE_CAST(TRIM(perf.zero_balance_removal_balance) AS NUMERIC)
        AS zero_balance_removal_balance,

    SAFE_CAST(TRIM(perf.delinquent_accrued_interest) AS NUMERIC)
        AS delinquent_accrued_interest,

    SAFE_CAST(
        TRIM(perf.current_period_modification_costs) AS NUMERIC
    ) AS current_period_modification_costs,

    SAFE_CAST(
        TRIM(perf.current_interest_bearing_balance) AS NUMERIC
    ) AS current_interest_bearing_balance,

    SAFE_CAST(TRIM(perf.bankruptcy_cramdown_costs) AS NUMERIC)
        AS bankruptcy_cramdown_costs,

    SAFE_CAST(
        NULLIF(TRIM(orig.credit_score), '9999') AS INT64
    ) AS credit_score,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(orig.first_payment_month), '')
    ) AS first_payment_month,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_dti), '999') AS INT64
    ) AS original_dti,

    SAFE_CAST(TRIM(orig.original_balance) AS NUMERIC)
        AS original_balance,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_ltv), '999') AS INT64
    ) AS original_ltv,

    NULLIF(TRIM(orig.loan_purpose), '')
        AS loan_purpose,

    SAFE_CAST(TRIM(orig.original_interest_rate) AS NUMERIC)
        AS original_interest_rate,

    SAFE_CAST(TRIM(orig.original_loan_term) AS INT64)
        AS original_loan_term,

    NULLIF(TRIM(orig.occupancy_status), '')
        AS occupancy_status,

    NULLIF(TRIM(orig.property_state), '')
        AS property_state,

    NULLIF(TRIM(orig.channel), '')
        AS channel,

    NULLIF(TRIM(orig.first_time_homebuyer), '')
        AS first_time_homebuyer,

    SAFE_CAST(
        NULLIF(TRIM(orig.number_of_borrowers), '99') AS INT64
    ) AS number_of_borrowers,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_cltv), '999') AS INT64
    ) AS original_cltv,

    SAFE_CAST(
        NULLIF(TRIM(orig.mortgage_insurance_pct), '999') AS INT64
    ) AS mortgage_insurance_pct,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(orig.maturity_month), '')
    ) AS maturity_month,

    orig.loan_id IS NOT NULL AS has_origination_match

FROM `mortgage_risk.raw_performance_2018` AS perf

LEFT JOIN `mortgage_risk.raw_origination_2018` AS orig
    ON NULLIF(TRIM(perf.loan_id), '')
     = NULLIF(TRIM(orig.loan_id), '');

#2019
CREATE OR REPLACE TABLE `mortgage_risk.2019_loan_monthly_analysis` AS

SELECT
    TRIM(perf.loan_id) AS loan_id,
    2019 AS origination_year,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.reporting_month), '')
    ) AS reporting_month,

    SAFE_CAST(TRIM(perf.current_balance) AS NUMERIC)
        AS current_balance,

    NULLIF(TRIM(perf.delinquency_status), '')
        AS delinquency_status,

    SAFE_CAST(TRIM(perf.loan_age) AS INT64)
        AS loan_age,

    NULLIF(TRIM(perf.zero_balance_code), '')
        AS zero_balance_code,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.zero_balance_month), '')
    ) AS zero_balance_month,

    SAFE_CAST(TRIM(perf.current_interest_rate) AS NUMERIC)
        AS current_interest_rate,

    NULLIF(TRIM(perf.modification_flag), '')
        AS modification_flag,

    NULLIF(TRIM(perf.borrower_assistance_plan), '')
        AS borrower_assistance_plan,

    NULLIF(TRIM(perf.delinquency_due_to_disaster), '')
        AS delinquency_due_to_disaster,

    NULLIF(TRIM(perf.payment_deferral_flag), '')
        AS payment_deferral_flag,

    SAFE_CAST(TRIM(perf.remaining_months_to_maturity) AS INT64)
        AS remaining_months_to_maturity,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.defect_settlement_month), '')
    ) AS defect_settlement_month,

    SAFE_CAST(
        TRIM(perf.current_non_interest_bearing_balance) AS NUMERIC
    ) AS current_non_interest_bearing_balance,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(perf.last_paid_installment_month), '')
    ) AS last_paid_installment_month,

    SAFE_CAST(TRIM(perf.mi_recoveries) AS NUMERIC)
        AS mi_recoveries,

    NULLIF(TRIM(perf.net_sales_proceeds), '')
        AS net_sales_proceeds_raw,

    SAFE_CAST(TRIM(perf.net_sales_proceeds) AS NUMERIC)
        AS net_sales_proceeds,

    SAFE_CAST(TRIM(perf.non_mi_recoveries) AS NUMERIC)
        AS non_mi_recoveries,

    SAFE_CAST(TRIM(perf.total_expenses) AS NUMERIC)
        AS total_expenses,

    SAFE_CAST(TRIM(perf.legal_costs) AS NUMERIC)
        AS legal_costs,

    SAFE_CAST(TRIM(perf.maintenance_preservation_costs) AS NUMERIC)
        AS maintenance_preservation_costs,

    SAFE_CAST(TRIM(perf.taxes_insurance) AS NUMERIC)
        AS taxes_insurance,

    SAFE_CAST(TRIM(perf.miscellaneous_expenses) AS NUMERIC)
        AS miscellaneous_expenses,

    SAFE_CAST(TRIM(perf.actual_loss) AS NUMERIC)
        AS actual_loss,

    SAFE_CAST(TRIM(perf.cumulative_modification_costs) AS NUMERIC)
        AS cumulative_modification_costs,

    SAFE_CAST(TRIM(perf.zero_balance_removal_balance) AS NUMERIC)
        AS zero_balance_removal_balance,

    SAFE_CAST(TRIM(perf.delinquent_accrued_interest) AS NUMERIC)
        AS delinquent_accrued_interest,

    SAFE_CAST(
        TRIM(perf.current_period_modification_costs) AS NUMERIC
    ) AS current_period_modification_costs,

    SAFE_CAST(
        TRIM(perf.current_interest_bearing_balance) AS NUMERIC
    ) AS current_interest_bearing_balance,

    SAFE_CAST(TRIM(perf.bankruptcy_cramdown_costs) AS NUMERIC)
        AS bankruptcy_cramdown_costs,

    SAFE_CAST(
        NULLIF(TRIM(orig.credit_score), '9999') AS INT64
    ) AS credit_score,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(orig.first_payment_month), '')
    ) AS first_payment_month,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_dti), '999') AS INT64
    ) AS original_dti,

    SAFE_CAST(TRIM(orig.original_balance) AS NUMERIC)
        AS original_balance,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_ltv), '999') AS INT64
    ) AS original_ltv,

    NULLIF(TRIM(orig.loan_purpose), '')
        AS loan_purpose,

    SAFE_CAST(TRIM(orig.original_interest_rate) AS NUMERIC)
        AS original_interest_rate,

    SAFE_CAST(TRIM(orig.original_loan_term) AS INT64)
        AS original_loan_term,

    NULLIF(TRIM(orig.occupancy_status), '')
        AS occupancy_status,

    NULLIF(TRIM(orig.property_state), '')
        AS property_state,

    NULLIF(TRIM(orig.channel), '')
        AS channel,

    NULLIF(TRIM(orig.first_time_homebuyer), '')
        AS first_time_homebuyer,

    SAFE_CAST(
        NULLIF(TRIM(orig.number_of_borrowers), '99') AS INT64
    ) AS number_of_borrowers,

    SAFE_CAST(
        NULLIF(TRIM(orig.original_cltv), '999') AS INT64
    ) AS original_cltv,

    SAFE_CAST(
        NULLIF(TRIM(orig.mortgage_insurance_pct), '999') AS INT64
    ) AS mortgage_insurance_pct,

    SAFE.PARSE_DATE(
        '%Y%m', NULLIF(TRIM(orig.maturity_month), '')
    ) AS maturity_month,

    orig.loan_id IS NOT NULL AS has_origination_match

FROM `mortgage_risk.raw_performance_2019` AS perf

LEFT JOIN `mortgage_risk.raw_origination_2019` AS orig
    ON NULLIF(TRIM(perf.loan_id), '')
     = NULLIF(TRIM(orig.loan_id), '');