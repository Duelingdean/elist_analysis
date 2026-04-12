--1 What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 

SELECT DATE_TRUNC(orders.purchase_ts, quarter) AS purchase_quarter,
  COUNT(distinct orders.id) AS order_count,
  ROUND(SUM(orders.usd_price),2) AS total_sales,
  ROUND(AVG(orders.usd_price),2) AS aov
FROM core.orders
LEFT JOIN core.customers
  ON orders.customer_id = customers.id
LEFT JOIN core.geo_lookup 
  ON customers.country_code = geo_lookup.country_code
WHERE LOWER(orders.product_name) LIKE '%macbook%'
	AND region = 'NA'
GROUP BY 1
ORDER BY 1 DESC;


--1b What is the average quarterly order count and total sales for Macbooks sold in North America? (i.e. “For North America Macbooks, average of X units sold per quarter and Y in dollar sales per quarter”)

WITH quarterly_metrics AS (
  SELECT DATE_TRUNC(orders.purchase_ts, quarter) AS purchase_quarter,
    COUNT(DISTINCT orders.id) AS order_count,
    ROUND(SUM(orders.usd_price), 2) AS total_sales
  FROM core.orders
  LEFT JOIN core.customers
    ON orders.customer_id = customers.id
  LEFT JOIN core.geo_lookup 
    ON customers.country_code = geo_lookup.country_code
  WHERE LOWER(orders.product_name) LIKE '%macbook%'
    AND region = 'NA'
 GROUP BY 1
 ORDER BY 1 DESC)
  
  
  --2 For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 

SELECT geo_lookup.region, 
  ROUND(AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)), 2) AS time_to_deliver
FROM core.order_status
LEFT JOIN core.orders
  ON order_status.order_id = orders.id
LEFT JOIN core.customers
  ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup
  ON geo_lookup.country_code = customers.country_code
WHERE (EXTRACT(year FROM orders.purchase_ts) = 2022 AND purchase_platform = 'website')
  OR purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC;


--3 What was the refund rate and refund count for each product overall? 

SELECT
	CASE WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE product_name END AS product_clean,
    SUM(CAST WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refunds,
    Round(AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END), 2) AS refund_rate
FROM core.orders 
LEFT JOIN core.order_status 
    ON orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC;


--4 Within each region, what is the most popular product? 

WITH sales_by_product AS (
  SELECT region,
  		product_name,
  		COUNT(DISTINCT orders.id) AS total_orders
FROM core.orders
LEFT JOIN core.customers
  ON orders.customer_id = customers.id
LEFT JOIN core.geo_lookup
  ON geo_lookup.country_code = customers.country_code
GROUP BY 1,2)

SELECT *, 
	ROW NUMBER() OVER (PARTITION BY region ORDER BY total_orders DESC) AS order_ranking
FROM sales_by_product
QUALIFY ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_orders DESC) = 1;


--5 How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 

SELECT customers.loyalty_program, 
 	   ROUND(AVG(DATE_DIFF(orders.purchase_ts, customers.created_on, day)),1) AS days_to_purchase,
  	   ROUND(AVG(DATE_DIFF(orders.purchase_ts, customers.created_on, month)),1) AS months_to_purchase
FROM core.customers
LEFT JOIN core.orders
  ON customers.id = orders.customer_id
GROUP BY 1
