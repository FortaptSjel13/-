--Проверяю, что витрина создалась и данные в ней есть:
SELECT
	COUNT(*)
FROM data_mart dm ; 


--Делаю выборки из таблицы fact_transactions и сравниваю с данными, которые в витрине:

--Сравнение количества транзакций в витрине и в фактах:
SELECT SUM(total_transactions) AS total_from_mart FROM data_mart; --6362620

SELECT COUNT(*) AS total_from_facts FROM fact_transactions; --6362620

--Сравнение суммы транзакций
SELECT SUM(total_amount) AS sum_from_mart FROM data_mart; --1 144 392 944 795, 77

SELECT SUM(amount) AS sum_from_facts FROM fact_transactions; --1 144 392 944 795, 77

--Проверка количества фродов
SELECT SUM(fraud_count) AS fraud_from_mart FROM data_mart; -- 8213

SELECT SUM(is_fraud::int) AS fraud_from_facts FROM fact_transactions; --8213

--Проверяю, что в ключевых полях (hour_of_day, day_of_week, week_of_month, type_name) нет NULL. 
SELECT *
FROM data_mart
WHERE hour_of_day IS NULL 
	OR day_of_week IS NULL 
	OR week_of_month IS NULL 
	OR type_name IS NULL;

-- Скрипты для сравнения данных
SELECT COUNT(*)
FROM fact_transactions ft
JOIN dates d ON ft.step_id = d.step_id
JOIN transaction_types tt ON ft.type_id = tt.type_id
WHERE d.hour_of_day = 8
  AND d.day_of_week = 1
  AND d.week_of_month = 1
  AND tt.type_name = 'CASH_IN'; -- 3 953

SELECT 
	total_transactions 
FROM data_mart dm 
WHERE hour_of_day = 8
  AND day_of_week = 1
  and week_of_month = 1
  AND type_name = 'CASH_IN'; -- 3 953

SELECT SUM(amount)
FROM fact_transactions ft
JOIN dates d ON ft.step_id = d.step_id
JOIN transaction_types tt ON ft.type_id = tt.type_id
WHERE d.hour_of_day = 8
  AND d.day_of_week = 1
  AND d.week_of_month = 1
  AND tt.type_name = 'CASH_IN'; --651968262.85

SELECT dm.total_amount 
FROM data_mart dm 
WHERE hour_of_day = 8
  AND day_of_week = 1
  AND week_of_month = 1
  AND type_name = 'CASH_IN'; ---651968262.85


-- Выборочные запры

 -- В какое время суток больше всего фродовых операций?
SELECT hour_of_day,
       SUM(fraud_count) AS total_frauds,
       SUM(total_transactions) AS total_trx,
       ROUND(SUM(fraud_count)::numeric / NULLIF(SUM(total_transactions), 0), 4) AS fraud_rate
FROM data_mart
GROUP BY hour_of_day
ORDER BY fraud_rate DESC;

--В каких типах операций самый высокий риск?
SELECT type_name,
       SUM(fraud_count) AS total_frauds,
       SUM(total_transactions) AS total_trx,
       ROUND(SUM(fraud_count)::numeric / NULLIF(SUM(total_transactions), 0), 4) AS fraud_rate
FROM data_mart
GROUP BY type_name
ORDER BY fraud_rate DESC;

--Сравнение помеченных и подтверждённых фродов. Показывает эффективность антифрод-системы.
SELECT type_name,
       SUM(fraud_count) AS real_frauds,
       SUM(flagged_count) AS flagged_as_fraud
FROM data_mart
GROUP BY type_name
ORDER BY real_frauds DESC;


-- Где по деньгам риск выше всего?
SELECT day_of_week,
       type_name,
       SUM(fraud_count) AS total_frauds,
       SUM(total_amount) AS fraud_amount
FROM data_mart
WHERE fraud_count > 0
GROUP BY day_of_week, type_name
ORDER BY fraud_amount DESC
LIMIT 5;

