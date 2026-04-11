--1 What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 

select date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
  count(distinct orders.id) as order_count,
  round(sum(orders.usd_price),2) as total_sales,
  round(avg(orders.usd_price),2) as aov
from core.orders
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup 
  on customers.country_code = geo_lookup.country_code
where lower(orders.product_name) like '%macbook%'
	and region = 'NA'
group by 1
order by 1 desc;


--1b What is the average quarterly order count and total sales for Macbooks sold in North America? (i.e. “For North America Macbooks, average of X units sold per quarter and Y in dollar sales per quarter”)

with quarterly_metrics as (
  select date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
    count(distinct orders.id) as order_count,
    round(sum(orders.usd_price),2) as total_sales
  from core.orders
  left join core.customers
    on orders.customer_id = customers.id
  left join core.geo_lookup 
    on customers.country_code = geo_lookup.country_code
  where lower(orders.product_name) like '%macbook%'
    and region = 'NA'
  group by 1
  order by 1 desc)
  
  
  --2 For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 

select geo_lookup.region, 
  round(avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, day)), 2) as time_to_deliver
from core.order_status
left join core.orders
  on order_status.order_id = orders.id
left join core.customers
  on customers.id = orders.customer_id
left join core.geo_lookup
  on geo_lookup.country_code = customers.country_code
where (extract(year from orders.purchase_ts) = 2022 and purchase_platform = 'website')
  or purchase_platform = 'mobile app'
group by 1
order by 2 desc;


--3 What was the refund rate and refund count for each product overall? 

select case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as product_clean,
    sum(case when refund_ts is not null then 1 else 0 end) as refunds,
    Round(avg(case when refund_ts is not null then 1 else 0 end), 2) as refund_rate
from core.orders 
left join core.order_status 
    on orders.id = order_status.order_id
group by 1
order by 3 desc;



--4 Within each region, what is the most popular product? 

with sales_by_product as (
  select region,
  product_name,
  count(distinct orders.id) as total_orders
from core.orders
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup
  on geo_lookup.country_code= customers.country_code
group by 1,2)

select *, 
	row_number() over (partition by region order by total_orders desc) as order_ranking
from sales_by_product
qualify row_number() over (partition by region order by total_orders desc) = 1;


--5 How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 

select customers.loyalty_program, 
  round(avg(date_diff(orders.purchase_ts, customers.created_on, day)),1) as days_to_purchase,
  round(avg(date_diff(orders.purchase_ts, customers.created_on, month)),1) as months_to_purchase
from core.customers
left join core.orders
  on customers.id = orders.customer_id
group by 1
