#checking for total rows, distinct loan_ids
select
loan_id,
count (*) as count,
count (distinct loan_id) as distinct_loan,
from `mortgage_risk.raw_origination_v2`
group by loan_id;

#checking for missing loan_id
select
loan_id,
count (distinct loan_id) as counts
from `mortgage_risk.raw_origination_v2`
WHERE loan_id IS NULL
   OR TRIM(loan_id) = ''
group by loan_id;

#checking for duplicates in loan_id
select
trim(loan_id) as trim_loan_id,
count (loan_id) as counts,
from `mortgage_risk.raw_origination_v2`
where loan_id is not null
and trim(loan_id) != ''
group by trim(loan_id)
having counts > 1;

#missing rates for credit score [9999- means unavailable value]

select
trim(credit_score) as credit_score,
count (*) as counts
from `mortgage_risk.raw_origination_v2`
where credit_score is null or
trim(credit_score) in ('', '9999')
group by credit_score;

#missing values for ltv [compares the loan amount with property value-loan amount/property value], dti [debt to income-monthly debt/monthly income] [999]
select
original_dti,
count (*) as counts
from `mortgage_risk.raw_origination_v2`
where original_dti is null OR original_dti in ('','999') 
group by original_dti;

select
count(*) as total,
countif (original_ltv IS NULL OR
trim(original_ltv) in ('','999') ) as missing,
round(countif(original_ltv IS NULL OR
trim(original_ltv) in ('','999'))/count(*) * 100,2) as missing_pct
from `mortgage_risk.raw_origination_v2`

#from string to numerics, and then calculating the minimum and maximum value
WITH numeric_values AS (
    SELECT
        SAFE_CAST(
            NULLIF(TRIM(credit_score), '9999') AS INT64
        ) AS credit_score,

        SAFE_CAST(
            NULLIF(TRIM(original_ltv), '999') AS INT64
        ) AS original_ltv,

        SAFE_CAST(
            NULLIF(TRIM(original_dti), '999') AS INT64
        ) AS original_dti,

        SAFE_CAST(
            TRIM(original_balance) AS NUMERIC
        ) AS original_balance

    FROM `mortgage_risk.raw_origination_v2`
);

SELECT
    MIN(credit_score) AS min_credit_score,
    MAX(credit_score) AS max_credit_score,
    MIN(original_ltv) AS min_ltv,
    MAX(original_ltv) AS max_ltv,
    MIN(original_dti) AS min_dti,
    MAX(original_dti) AS max_dti,
    MIN(original_balance) AS min_original_balance,
    MAX(original_balance) AS max_original_balance
FROM numeric_values;

#2018
#checking for total rows, distinct loan_ids
select
loan_id,
count (*) as count,
count (distinct loan_id) as distinct_loan,
from `mortgage_risk.raw_origination_2018`
group by loan_id;

#checking for missing loan_id
select
loan_id,
count (distinct loan_id) as counts
from `mortgage_risk.raw_origination_2018`
WHERE loan_id IS NULL
   OR TRIM(loan_id) = ''
group by loan_id;

#checking for duplicates in loan_id
select
trim(loan_id) as trim_loan_id,
count (loan_id) as counts,
from `mortgage_risk.raw_origination_2018`
where loan_id is not null
and trim(loan_id) != ''
group by trim(loan_id)
having counts > 1;

#missing rates for credit score [9999- means unavailable value]

select
trim(credit_score) as credit_score,
count (*) as counts
from `mortgage_risk.raw_origination_2018`
where credit_score is null or
trim(credit_score) in ('', '9999')
group by credit_score;

#missing values for ltv [compares the loan amount with property value-loan amount/property value], dti [debt to income-monthly debt/monthly income] [999]
select
original_dti,
count (*) as counts
from `mortgage_risk.raw_origination_2018`
where original_dti is null OR original_dti in ('','999') 
group by original_dti;

select
count(*) as total,
countif (original_ltv IS NULL OR
trim(original_ltv) in ('','999') ) as missing,
round(countif(original_ltv IS NULL OR
trim(original_ltv) in ('','999'))/count(*) * 100,2) as missing_pct
from `mortgage_risk.raw_origination_2018`;

#from string to numerics, and then calculating the minimum and maximum value
WITH numeric_values AS (
    SELECT
        SAFE_CAST(
            NULLIF(TRIM(credit_score), '9999') AS INT64
        ) AS credit_score,

        SAFE_CAST(
            NULLIF(TRIM(original_ltv), '999') AS INT64
        ) AS original_ltv,

        SAFE_CAST(
            NULLIF(TRIM(original_dti), '999') AS INT64
        ) AS original_dti,

        SAFE_CAST(
            TRIM(original_balance) AS NUMERIC
        ) AS original_balance

    FROM `mortgage_risk.raw_origination_2018`
)

SELECT
    MIN(credit_score) AS min_credit_score,
    MAX(credit_score) AS max_credit_score,
    MIN(original_ltv) AS min_ltv,
    MAX(original_ltv) AS max_ltv,
    MIN(original_dti) AS min_dti,
    MAX(original_dti) AS max_dti,
    MIN(original_balance) AS min_original_balance,
    MAX(original_balance) AS max_original_balance
FROM numeric_values;




