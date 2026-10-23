/*counting rows*/

select
count (*) as performance_rows,
count (distinct loan_id) as distinct_id
from `mortgage_risk.raw_performance_2017_v2`;

select
count (*) as origination_rows,
count (distinct loan_id) as distinct_id
from `mortgage_risk.raw_origination_v2`;

#checking if all loan id within a month are unique-how many counts for each group of loan id and month#

select loan_id,
reporting_month,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.raw_performance_2017_v2`
group by loan_id,reporting_month
having counts = 1;

#counts of delinquency status [how late the payments are THAT month#

select
delinquency_status,
count (*) as counts
from `mortgage_risk.raw_performance_2017_v2`
group by delinquency_status;

#counts of zero balance code [why the loan ended]
select
zero_balance_code,
count (*) as counts
from `mortgage_risk.raw_performance_2017_v2`
group by zero_balance_code;

#2018
/*counting rows*/

select
count (*) as performance_rows,
count (distinct loan_id) as distinct_id
from `mortgage_risk.raw_performance_2018`;

select
count (*) as origination_rows,
count (distinct loan_id) as distinct_id
from `mortgage_risk.raw_origination_2018`;

#checking if all loan id within a month are unique-how many counts for each group of loan id and month#

select loan_id,
reporting_month,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.raw_performance_2018`
group by loan_id,reporting_month
having counts = 1;

#counts of delinquency status [how late the payments are THAT month#

select
delinquency_status,
count (*) as counts
from `mortgage_risk.raw_performance_2018`
group by delinquency_status;

#counts of zero balance code [why the loan ended]
select
zero_balance_code,
count (*) as counts
from `mortgage_risk.raw_performance_2018`
group by zero_balance_code;

#2019
/*counting rows*/

select
count (*) as performance_rows,
count (distinct loan_id) as distinct_id
from `mortgage_risk.raw_performance_2019`;

select
count (*) as origination_rows,
count (distinct loan_id) as distinct_id
from `mortgage_risk.raw_origination_2019`;

#checking if all loan id within a month are unique-how many counts for each group of loan id and month#

select loan_id,
reporting_month,
count (*) as counts
from `mortgage-credit-risk-analytics.mortgage_risk.raw_performance_2019`
group by loan_id,reporting_month
having counts = 1;

#counts of delinquency status [how late the payments are THAT month#

select
delinquency_status,
count (*) as counts
from `mortgage_risk.raw_performance_2019`
group by delinquency_status;

#counts of zero balance code [why the loan ended]
select
zero_balance_code,
count (*) as counts
from `mortgage_risk.raw_performance_2019`
group by zero_balance_code













