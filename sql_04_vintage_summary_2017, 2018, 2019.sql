#how does delinquency change as loans get older
select
loan_age,
modification_flag,
count (*) as monthly_counts
from `mortgage_risk.loan_monthly_analysis_2017`
group by loan_age, modification_flag
order by loan_age DESC;

#a specific loan id should have only one entry at a particular age
select
loan_id,
loan_age,
count (*) as counts
from `mortgage_risk.loan_monthly_analysis_2017`
where modification_flag
group by loan_id, loan_age
having counts > 1;

#since we got multiple entries where a loan id has jad the same age multiple times we need to check what is going on

SELECT
    loan_id,
    reporting_month,
    loan_age,
    modification_flag,
    delinquency_status,
    zero_balance_code
FROM `mortgage_risk.loan_monthly_analysis_2017`
WHERE loan_id = 'F17Q10186104'
ORDER BY reporting_month;


#10 monthly counts mean that 10 entries have loan age 110 and m.flag as null
select
loan_id,
loan_age,
count (*) as counts
from `mortgage_risk.loan_monthly_analysis_2017`
where modification_flag is null
group by loan_id, loan_age
having counts > 1;

#this means that reasons other than modification status (renewal of loan or modifications of terms) can alos attrribute to same loan having same loan ages

SELECT
    loan_id,
    reporting_month,
    loan_age,
    modification_flag,
    delinquency_status,
    zero_balance_code,
    zero_balance_month,
    delinquency_status
FROM `mortgage_risk.loan_monthly_analysis_2017`
WHERE loan_id = 'F17Q10290571'
ORDER BY reporting_month;

#reporting month is the month we observe, zero-balance-month is the month where the loan has been repaid-
#scenarios where loan id can not have multiple same loan ages OR Active,pre-modification loans:
/*there should be no modiifications,
the zero balance month must be more than the reporting month,
current balance is greater than 0,
zero month shouldnt be null*/

SELECT
    loan_id,
    loan_age,
    COUNT(*) AS records_at_age
FROM `mortgage_risk.loan_monthly_analysis_2017`
WHERE modification_flag IS NULL
  AND current_balance > 0
  AND (
      zero_balance_month IS NULL
      OR zero_balance_month > reporting_month
  )
GROUP BY loan_id, loan_age
HAVING COUNT(*) > 1;

SELECT
    loan_age,
    delinquency_status,
    COUNT(*) AS loan_count
FROM `mortgage_risk.loan_monthly_analysis_2017`
WHERE reporting_month IS NOT NULL
  AND loan_age IS NOT NULL
  AND modification_flag IS NULL
  AND current_balance > 0
  AND (
      zero_balance_month IS NULL
      OR zero_balance_month > reporting_month
  )
GROUP BY loan_age, delinquency_status
ORDER BY loan_age, delinquency_status;

/*Code	Meaning for Deliquency Status
00	Current or less than 30 days late
01	30–59 days late
02	60–89 days late
03	90–119 days late
04	120–149 days late
05	150–179 days late
06 onward	Further 30-day bands, capped at 99
RA	REO acquisition—property acquired as real estate owned
XX / NULL	Unavailable or missing status*/

#calculate the loan-count 30+ days delinquency rate at each loan age-we cant have ra, xx or null values because want to count the records that exist for sure.

select
countif(safe_cast(delinquency_status as int64) BETWEEN 01 AND 99) as delinquent_above30,
loan_age,
countif(safe_cast(delinquency_status as int64) between 00 and 99) as total_eligible,
round(countif(safe_cast(delinquency_status as int64) BETWEEN 01 AND 99)/countif(safe_cast(delinquency_status as int64) between 00 and 99) *100,2) as rate_above_30
from `mortgage_risk.loan_monthly_analysis_2017`
WHERE reporting_month IS NOT NULL
  AND loan_age IS NOT NULL
  AND modification_flag IS NULL
  AND current_balance > 0
  AND (
      zero_balance_month IS NULL
      OR zero_balance_month > reporting_month
  )
group by loan_age 
order by rate_above_30 DESC

/*Among eligible active records before modification, 30+ delinquency rose from 0.85% at loan age 12 to 4.66% at age 36. The eligible loan count declined from 47,041 to 33,695, so the comparison reflects a changing population as well as different calendar periods.*/
#dont claim correlations or trends before taking %ages into account

#calculate balance-weighted rates for each loan age [basically loans within 01-99/loans within 00-99]
/*wrong but helpful 
select
loan_age,
sum(if(safe_cast(delinquency_status) is between 1-99)) as bw_above30,
sum(if(safe_cast(delinquency_status) is between 0-99)) as total_balance,
round(sum(if(safe_cast(delinquency_status) is between 01-99))/sum(if(safe_cast(delinquency_status) is between 00-99)) *100,2) as balance_weighted
from `mortgage_risk.loan_monthly_analysis_2017`
WHERE reporting_month IS NOT NULL
  AND loan_age IS NOT NULL
  AND modification_flag IS NULL
  AND delinquency_status > 0
  AND (
      zero_balance_month IS NULL
      OR zero_balance_month > reporting_month
  )
group by loan_age 
order by rate_above_30 DESC*/

WITH balance_totals AS (
    SELECT
        loan_age,

        SUM(
            IF(
                SAFE_CAST(delinquency_status AS INT64)
                    BETWEEN 1 AND 99,
                current_balance,
                0
            )
        ) AS balance_30plus,

        SUM(
            IF(
                SAFE_CAST(delinquency_status AS INT64)
                    BETWEEN 0 AND 99,
                current_balance,
                0
            )
        ) AS eligible_balance

    FROM `mortgage_risk.loan_monthly_analysis_2017`
    WHERE reporting_month IS NOT NULL
      AND loan_age IS NOT NULL
      AND modification_flag IS NULL
      AND current_balance > 0
      AND (
          zero_balance_month IS NULL
          OR zero_balance_month > reporting_month
      )
    GROUP BY loan_age
)

SELECT
    loan_age,
    balance_30plus,
    eligible_balance,
    ROUND(
        SAFE_DIVIDE(balance_30plus, eligible_balance) * 100,
        2
    ) AS balance_weighted_pct
FROM balance_totals
ORDER BY loan_age;

SELECT
    loan_age,

    COUNTIF(
        SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99
    ) AS delinquent_above30,

    COUNTIF(
        SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99
    ) AS total_eligible,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99
            ),
            COUNTIF(
                SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99
            )
        ) * 100,
        2
    ) AS rate_above_30

FROM `mortgage_risk.loan_monthly_analysis_2017`

WHERE reporting_month IS NOT NULL
  AND loan_age IS NOT NULL
  AND modification_flag IS NULL
  AND current_balance > 0
  AND (
      zero_balance_month IS NULL
      OR zero_balance_month > reporting_month
  )

GROUP BY loan_age
ORDER BY loan_age;
/*Among eligible active records before modification, the 2017 vintage’s loan-count 30+ delinquency rate rose from 0.84% at age 12 to 5.00% at age 36. At age 36, the balance-weighted rate was higher at 6.12%, indicating that delinquent loans had larger average outstanding balances than eligible loans overall. Changing eligible populations and calendar conditions limit interpretation; the increase does not establish that loan age caused delinquency.*/

#2018
#How does delinquency differ between origination years when loans are compared at the same age?

#How many monthly records and distinct loans belong to each origination year?

select
loan_id,
reporting_month,
count (distinct loan_id) as count_distinct,
count (reporting_month) as count_month
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
group by loan_id, reporting_month;

#Does each year’s record count match its cleaned yearly table?

#At each loan age, how many records remain after applying our active and pre-modification filters?

/*
Active means:
1.zero_balance_month isnt null
2.zero_balance isnt null
3.reporting month is not null
4. loan_age in not null
5. current_balance > 0

Premodification-calculating things before the terms of an original loan were modified:
1. modification_flag is NULL
2. zero_balance_month > reporting_month OR zero_baklance_month is null */

select
loan_age,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where reporting_month is not null and
zero_balance_month > reporting_month 
or zero_balance_month is null
and 
modification_flag is null
and current_balance > 0
group by loan_age
order by loan_age;

#Do any loans appear more than once at the same age after filtering?

#before filtering
select
loan_id,
loan_age,
count (*) as counts
from `mortgage_risk.2018_loan_monthly_analysis`
group by loan_id, loan_age
having counts > 1;

#after filtering
select
loan_id,
loan_age,
count (*) as counts
from `mortgage_risk.2018_loan_monthly_analysis`
where modification_flag is null and
(zero_balance_month>reporting_month or 
zero_balance_month is null) and
reporting_month is not null and
loan_age is not null and
current_balance > 0
group by loan_id, loan_age
having counts > 1;

#How many otherwise eligible records have unknown or nonnumeric delinquency status? What balance do they represent?

select
sum(current_balance) as total,
delinquency_status,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null and 
(safe_cast(delinquency_status as int64)not between 0 and 99 or 
safe_cast(delinquency_status as int64) is null)
group by delinquency_status

#How many records are excluded because of modification?

    select
    modification_flag,
    count(*) as counts
    from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
    where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is not null AND
loan_age is not null AND
reporting_month is not null 
group by modification_flag

# Which loan-age window has sufficient observations in all three vintages? Start by assessing ages 12–36.

select
loan_age,
count (*) as loan_age_counts
from `mortgage_risk.2018_loan_monthly_analysis`
 where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null 
group by loan_age
order by loan_age 

#How many eligible loans have known numeric status 00–99?

select
safe_cast(loan_age as int64) as loan_age,
count (*) as numeric_counts
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null AND
safe_cast(delinquency_status as int64) between 0 and 99
group by loan_age
order by loan_age

#How many are 30+ days delinquent, with numeric status 01–99?

select
loan_age,
count (*) as numeric_counts
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null AND
safe_cast(delinquency_status as int64) between 1 and 99
group by loan_age
order by loan_age

#What is the loan-count 30+ delinquency rate?

select
countif (safe_cast(delinquency_status as int64) between 1 and 99) as delinquent_beyond30,
countif(safe_cast(delinquency_status as int64) between 0 and 99) as total_eligible,
round(countif (safe_cast(delinquency_status as int64) between 1 and 99)/countif(safe_cast(delinquency_status as int64) between 0 and 99)*100,2) as delinquency_30plusrate
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null
group by loan_age

#What is the total current balance of ___eligible known-status loans___?

select
loan_age,
sum(current_balance) as total_current_balance
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null
 AND SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99
GROUP BY loan_age
ORDER BY loan_age;


#What balance belongs to the 30+ delinquent loans?
select
loan_age,
sum(current_balance) as total_current_balance30plus
from `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null
 AND SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99
GROUP BY loan_age
ORDER BY loan_age;

#What is the balance-weighted 30+ delinquency rate?

[30+/all]

SELECT
    loan_age,

    SUM(
        IF(
            SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99,
            current_balance,
            0
        )
    ) AS balance_30plus,

    SUM(
        IF(
            SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99,
            current_balance,
            0
        )
    ) AS eligible_balance,

    ROUND(
        SAFE_DIVIDE(
            SUM(
                IF(
                    SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99,
                    current_balance,
                    0
                )
            ),
            SUM(
                IF(
                    SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99,
                    current_balance,
                    0
                )
            )
        ) * 100,
        2
    ) AS balance_weighted_30plus_pct

FROM `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`

WHERE current_balance > 0
  AND (
      zero_balance_month > reporting_month
      OR zero_balance_month IS NULL
  )
  AND modification_flag IS NULL
  AND loan_age IS NOT NULL
  AND reporting_month IS NOT NULL

GROUP BY loan_age
ORDER BY loan_age;

#2019
#How does delinquency differ between origination years when loans are compared at the same age?

#How many monthly records and distinct loans belong to each origination year?

select
loan_id,
reporting_month,
count (distinct loan_id) as count_distinct,
count (reporting_month) as count_month
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
group by loan_id, reporting_month;

#Does each year’s record count match its cleaned yearly table?

#At each loan age, how many records remain after applying our active and pre-modification filters?

/*
Active means:
1.zero_balance_month isnt null
2.zero_balance isnt null
3.reporting month is not null
4. loan_age in not null
5. current_balance > 0

Premodification-calculating things before the terms of an original loan were modified:
1. modification_flag is NULL
2. zero_balance_month > reporting_month OR zero_baklance_month is null */

select
loan_age,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where reporting_month is not null and
zero_balance_month > reporting_month 
or zero_balance_month is null
and 
modification_flag is null
and current_balance > 0
group by loan_age
order by loan_age;

#Do any loans appear more than once at the same age after filtering?

#before filtering
select
loan_id,
loan_age,
count (*) as counts
from `mortgage_risk.2019_loan_monthly_analysis`
group by loan_id, loan_age
having counts > 1;

#after filtering
select
loan_id,
loan_age,
count (*) as counts
from `mortgage_risk.2019_loan_monthly_analysis`
where modification_flag is null and
(zero_balance_month>reporting_month or 
zero_balance_month is null) and
reporting_month is not null and
loan_age is not null and
current_balance > 0
group by loan_id, loan_age
having counts > 1;

#How many otherwise eligible records have unknown or nonnumeric delinquency status? What balance do they represent?

select
sum(current_balance) as total,
delinquency_status,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null and 
(safe_cast(delinquency_status as int64)not between 0 and 99 or 
safe_cast(delinquency_status as int64) is null)
group by delinquency_status

#How many records are excluded because of modification?

    select
    modification_flag,
    count(*) as counts
    from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
    where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is not null AND
loan_age is not null AND
reporting_month is not null 
group by modification_flag

# Which loan-age window has sufficient observations in all three vintages? Start by assessing ages 12–36.

select
loan_age,
count (*) as loan_age_counts
from `mortgage_risk.2019_loan_monthly_analysis`
 where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null 
group by loan_age
order by loan_age 

#How many eligible loans have known numeric status 00–99?

select
safe_cast(loan_age as int64) as loan_age,
count (*) as numeric_counts
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null AND
safe_cast(delinquency_status as int64) between 0 and 99
group by loan_age
order by loan_age

#How many are 30+ days delinquent, with numeric status 01–99?

select
loan_age,
count (*) as numeric_counts
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null AND
safe_cast(delinquency_status as int64) between 1 and 99
group by loan_age
order by loan_age

#What is the loan-count 30+ delinquency rate?

select
countif (safe_cast(delinquency_status as int64) between 1 and 99) as delinquent_beyond30,
countif(safe_cast(delinquency_status as int64) between 0 and 99) as total_eligible,
round(countif (safe_cast(delinquency_status as int64) between 1 and 99)/countif(safe_cast(delinquency_status as int64) between 0 and 99)*100,2) as delinquency_30plusrate
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null
group by loan_age

#What is the total current balance of ___eligible known-status loans___?

select
loan_age,
sum(current_balance) as total_current_balance
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null
 AND SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99
GROUP BY loan_age
ORDER BY loan_age;


#What balance belongs to the 30+ delinquent loans?
select
loan_age,
sum(current_balance) as total_current_balance30plus
from `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
where current_balance > 0 AND
(zero_balance_month > reporting_month or
zero_balance_month is null) AND
modification_flag is null AND
loan_age is not null AND
reporting_month is not null
 AND SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99
GROUP BY loan_age
ORDER BY loan_age;

#What is the balance-weighted 30+ delinquency rate?

[30+/all]

SELECT
    loan_age,

    SUM(
        IF(
            SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99,
            current_balance,
            0
        )
    ) AS balance_30plus,

    SUM(
        IF(
            SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99,
            current_balance,
            0
        )
    ) AS eligible_balance,

    ROUND(
        SAFE_DIVIDE(
            SUM(
                IF(
                    SAFE_CAST(delinquency_status AS INT64) BETWEEN 1 AND 99,
                    current_balance,
                    0
                )
            ),
            SUM(
                IF(
                    SAFE_CAST(delinquency_status AS INT64) BETWEEN 0 AND 99,
                    current_balance,
                    0
                )
            )
        ) * 100,
        2
    ) AS balance_weighted_30plus_pct

FROM `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`

WHERE current_balance > 0
  AND (
      zero_balance_month > reporting_month
      OR zero_balance_month IS NULL
  )
  AND modification_flag IS NULL
  AND loan_age IS NOT NULL
  AND reporting_month IS NOT NULL

GROUP BY loan_age
ORDER BY loan_age;


#Vintage summary
CREATE OR REPLACE TABLE
    `mortgage-credit-risk-analytics.mortgage_risk.vintage_summary` AS

WITH combined_loans AS (
    SELECT
        origination_year,
        loan_id,
        loan_age,
        reporting_month,
        current_balance,
        delinquency_status,
        modification_flag,
        zero_balance_month
    FROM `mortgage-credit-risk-analytics.mortgage_risk.loan_monthly_analysis_2017`

    UNION ALL BY NAME

    SELECT
        origination_year,
        loan_id,
        loan_age,
        reporting_month,
        current_balance,
        delinquency_status,
        modification_flag,
        zero_balance_month
    FROM `mortgage-credit-risk-analytics.mortgage_risk.2018_loan_monthly_analysis`

    UNION ALL BY NAME

    SELECT
        origination_year,
        loan_id,
        loan_age,
        reporting_month,
        current_balance,
        delinquency_status,
        modification_flag,
        zero_balance_month
    FROM `mortgage-credit-risk-analytics.mortgage_risk.2019_loan_monthly_analysis`
),

eligible_records AS (
    SELECT
        origination_year,
        loan_age,
        current_balance,
        SAFE_CAST(delinquency_status AS INT64) AS status_numeric
    FROM combined_loans
    WHERE current_balance > 0
      AND (
          zero_balance_month > reporting_month
          OR zero_balance_month IS NULL
      )
      AND modification_flag IS NULL
      AND loan_age IS NOT NULL
      AND reporting_month IS NOT NULL
),

age_totals AS (
    SELECT
        origination_year,
        loan_age,

        COUNT(*) AS active_pre_modification_records,

        COUNTIF(status_numeric BETWEEN 0 AND 99)
            AS eligible_loans,

        COUNTIF(status_numeric BETWEEN 1 AND 99)
            AS delinquent_30plus_loans,

        SUM(
            IF(status_numeric BETWEEN 0 AND 99, current_balance, 0)
        ) AS eligible_balance,

        SUM(
            IF(status_numeric BETWEEN 1 AND 99, current_balance, 0)
        ) AS balance_30plus,

        COUNTIF(
            status_numeric IS NULL
            OR status_numeric NOT BETWEEN 0 AND 99
        ) AS excluded_status_records,

        SUM(
            IF(
                status_numeric IS NULL
                OR status_numeric NOT BETWEEN 0 AND 99,
                current_balance,
                0
            )
        ) AS excluded_status_balance

    FROM eligible_records
    GROUP BY origination_year, loan_age
)

SELECT
    *,
    ROUND(
        SAFE_DIVIDE(delinquent_30plus_loans, eligible_loans) * 100,
        2
    ) AS loan_count_30plus_pct,

    ROUND(
        SAFE_DIVIDE(balance_30plus, eligible_balance) * 100,
        2
    ) AS balance_weighted_30plus_pct

FROM age_totals;

#Vintage Ananlysis at 12,24,36
SELECT
    loan_age,
    origination_year,
    eligible_loans,
    delinquent_30plus_loans,
    loan_count_30plus_pct,
    balance_weighted_30plus_pct
FROM `mortgage-credit-risk-analytics.mortgage_risk.vintage_summary`
WHERE loan_age IN (12, 24, 36)
ORDER BY loan_age, origination_year;
