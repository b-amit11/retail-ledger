-- SQLite 3. Window functions identify exact duplicate rows without losing raw evidence.
DROP VIEW IF EXISTS classified;
CREATE VIEW classified AS
WITH ranked AS (
 SELECT *, ROW_NUMBER() OVER (PARTITION BY invoice,stock_code,description,quantity,invoice_date,unit_price,customer_id,country ORDER BY source_row) AS copy_number
 FROM raw_transactions
)
SELECT *, substr(invoice_date,1,7) AS month,
 CAST(ROUND(unit_price*1000) AS INTEGER)*quantity AS value_mills,
 CASE
 WHEN copy_number>1 THEN 'duplicate'
 WHEN unit_price<=0 THEN 'nonpositive_price'
 WHEN quantity>0 AND upper(substr(invoice,1,1))<>'C' THEN 'sale'
 WHEN quantity<0 AND upper(substr(invoice,1,1))='C' THEN 'cancellation'
 ELSE 'other_adjustment' END AS record_class
FROM ranked;

DROP VIEW IF EXISTS monthly;
CREATE VIEW monthly AS
SELECT month,
 SUM(CASE WHEN record_class='sale' THEN value_mills ELSE 0 END)/1000.0 AS gross_gbp,
 -SUM(CASE WHEN record_class='cancellation' THEN value_mills ELSE 0 END)/1000.0 AS cancellations_gbp,
 SUM(value_mills)/1000.0 AS net_gbp,
 COUNT(DISTINCT CASE WHEN record_class='sale' THEN invoice END) AS sales_invoices,
 COUNT(DISTINCT CASE WHEN record_class='sale' THEN customer_id END) AS identified_buyers,
 SUM(CASE WHEN customer_id IS NULL THEN value_mills ELSE 0 END)/1000.0 AS unidentified_net_gbp,
 CASE WHEN month='2011-12' THEN 0 ELSE 1 END AS complete_month
FROM classified WHERE record_class IN ('sale','cancellation') GROUP BY month;

DROP VIEW IF EXISTS country_summary;
CREATE VIEW country_summary AS
SELECT country,
 SUM(CASE WHEN record_class='sale' THEN value_mills ELSE 0 END)/1000.0 AS gross_gbp,
 -SUM(CASE WHEN record_class='cancellation' THEN value_mills ELSE 0 END)/1000.0 AS cancellations_gbp,
 SUM(value_mills)/1000.0 AS net_gbp,
 COUNT(DISTINCT CASE WHEN record_class='sale' THEN invoice END) AS sales_invoices
FROM classified WHERE record_class IN ('sale','cancellation') GROUP BY country;

DROP VIEW IF EXISTS cohorts;
CREATE VIEW cohorts AS
WITH activity AS (
 SELECT DISTINCT customer_id,month FROM classified
 WHERE record_class='sale' AND customer_id IS NOT NULL AND month<'2011-12'
), firsts AS (
 SELECT customer_id,MIN(month) AS cohort FROM activity GROUP BY customer_id
), counts AS (
 SELECT f.cohort,a.month,
 (CAST(substr(a.month,1,4) AS INTEGER)-CAST(substr(f.cohort,1,4) AS INTEGER))*12+
 CAST(substr(a.month,6,2) AS INTEGER)-CAST(substr(f.cohort,6,2) AS INTEGER) AS month_index,
 COUNT(*) AS active_customers
 FROM activity a JOIN firsts f USING(customer_id) GROUP BY f.cohort,a.month
), sizes AS (SELECT cohort,COUNT(*) AS cohort_size FROM firsts GROUP BY cohort)
SELECT c.*,s.cohort_size,1.0*c.active_customers/s.cohort_size AS retention
FROM counts c JOIN sizes s USING(cohort);
