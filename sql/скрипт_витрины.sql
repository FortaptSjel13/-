-- public.data_mart исходный текст


CREATE MATERIALIZED VIEW public.data_mart
TABLESPACE pg_default
AS WITH grouped AS (
         SELECT d.hour_of_day,
            d.day_of_week,
            d.week_of_month,
            tt.type_name,
            count(ft.transaction_id) AS total_transactions,
            sum(ft.amount) AS total_amount,
            sum(
                CASE
                    WHEN ft.is_fraud THEN 1
                    ELSE 0
                END) AS fraud_count,
            sum(
                CASE
                    WHEN ft.is_flagged_fraud THEN 1
                    ELSE 0
                END) AS flagged_count
           FROM fact_transactions ft
             LEFT JOIN dates d ON ft.step_id = d.step_id
             LEFT JOIN clients c1 ON ft.orig_client_id = c1.client_id
             LEFT JOIN clients c2 ON ft.dest_client_id = c2.client_id
             LEFT JOIN transaction_types tt ON ft.type_id = tt.type_id
          GROUP BY d.hour_of_day, d.day_of_week, d.week_of_month, tt.type_name
        )
 SELECT hour_of_day,
    day_of_week,
    week_of_month,
    type_name,
    total_transactions,
    total_amount,
    fraud_count,
    flagged_count,
    round(fraud_count::numeric / NULLIF(total_transactions, 0)::numeric, 4) AS fraud_rate_group,
    round(fraud_count::numeric / NULLIF(sum(fraud_count) OVER (), 0::numeric), 4) AS fraud_share_all
   FROM grouped
  ORDER BY week_of_month, day_of_week, hour_of_day, type_name
WITH DATA;
