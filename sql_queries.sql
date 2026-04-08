--What were the order counts, sales, and AOV for MacBooks sold in North America for each quarter across all years?

SELECT date_trunc(purchase_ts, quarter) AS purchase_quarter,
  COUNT(DISTINCT orders.id) AS order_count,
  ROUND(SUM(orders.usd_price), 2) AS sales,
  ROUND(AVG(orders.usd_price), 2) AS aov
FROM core.orders
LEFT JOIN core.customers
  ON orders.customer_id = customers.id
LEFT JOIN core.geo_lookup
  ON geo_lookup.country_code = customers.country_code
WHERE region = 'NA'
AND LOWER(product_name) LIKE '%macbook%'
GROUP BY 1
ORDER BY 1 DESC;


--For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 

SELECT geo_lookup.region, 
  AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)) AS time_to_deliver
FROM core.order_status
LEFT JOIN core.orders
  ON order_status.order_id = orders.id
LEFT JOIN core.customers
  ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup
  ON geo_lookup.country_code = customers.country_code
WHERE (EXTRACT(year FROM orders.purchase_ts) = 2022 AND purchase_platform = 'website')
  or purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC;

--Within each region, what is the most popular product? 

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
	ROW_NUMBER() OVER (PARTITION by region ORDER BY total_orders DESC) AS order_ranking
FROM sales_by_product
QUALIFY ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_orders DESC) = 1;
