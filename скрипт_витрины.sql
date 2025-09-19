-- public.data_mart исходный текст

CREATE MATERIALIZED VIEW public.data_mart
TABLESPACE pg_default
AS SELECT d.hour_of_day,
    d.day_of_week,
    d.week_of_month,
    tt.type_name,
    count(ft.transaction_id) AS total_transactions,
    sum(ft.amount) AS total_amount,
    sum(
        CASE
            WHEN ft.is_fraud = true THEN 1
            ELSE 0
        END) AS fraud_count,
    sum(
        CASE
            WHEN ft.is_flagged_fraud = true THEN 1
            ELSE 0
        END) AS flagged_count,
    round((sum(
        CASE
            WHEN ft.is_fraud = true THEN 1
            ELSE 0
        END)::integer / NULLIF(count(ft.transaction_id), 0))::numeric, 4) AS fraud_rate_group,
    round(sum(
        CASE
            WHEN ft.is_fraud = true THEN 1
            ELSE 0
        END)::integer::numeric / NULLIF(sum(count(*)) OVER (), 0::numeric), 4) AS fraud_rate_all
   FROM fact_transactions ft
     LEFT JOIN dates d ON ft.step_id = d.step_id
     LEFT JOIN clients c1 ON ft.orig_client_id = c1.client_id
     LEFT JOIN clients c2 ON ft.dest_client_id = c2.client_id
     LEFT JOIN transaction_types tt ON ft.type_id = tt.type_id
  GROUP BY d.hour_of_day, d.day_of_week, d.week_of_month, tt.type_name
  ORDER BY d.week_of_month, d.day_of_week, d.hour_of_day, tt.type_name
WITH DATA;