use ecommerce_analytics;
-- Total Revenue & Average Order Value
select count(distinct order_id) as Total_orders,
	sum(payment_value) as total_revenue,
    avg(payment_value) as avg_order_value,
    max(payment_value) as hightest_order,
    min(payment_value) as lowest_order
from payments; 

-- Revenue by Product Category (Top 10)
select 
	p.product_category_name_english as category,
    count(distinct oi.order_id) as total_orders,
    round(sum(oi.price),2) as total_revenue,
    round(avg(oi.price),2) as avg_price
from order_items as oi
join products as p on p.product_id = oi.product_id
group by p.product_category_name_english
order by total_revenue desc
limit 10;

-- Average Delivery Time by State
select 
	c.customer_state as State,
    count(o.order_id) as total_orders,
    round(avg(o.delivery_time_days),2) as avg_delivery_days,
    round(min(o.delivery_time_days),2) as min_delivery_days,
    round(max(o.delivery_time_days),2) as max_delivery_days
from orders as o
join customers as c on o.customer_id = c.customer_id
where o.delivery_time_days is not null
group by c.customer_state
order by avg_delivery_days  asc
limit 10;


-- Payment Method Breakdown
select 
	payment_type,
    count(*) as transation_count,
    round(sum(payment_value),2) as total_revenue,
    round(avg(payment_value),2) as avg_transaction_value,
    round(count(*)*100.0/ (select count(*)from payments),2) as percentage
from payments
group by payment_type
order by total_revenue desc;


-- Revenue by Review Score
select 
	r.review_score,
    count(distinct r.order_id) as total_orders,
    round(sum(p.payment_value),2) as total_revenue,
    round(avg(p.payment_value),2) as avg_order_value
from reviews as r
join payments as p on r.order_id = p.order_id
group by r.review_score
order by r.review_score desc;

-- Top 10 Customers by Total Spending

select 
	c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    count(distinct o.order_id) as total_orders,
    round(sum(p.payment_type),2) as total_spent,
    round(avg(p.payment_type),2) as avg_order_value
from customers as c
join orders as o on c.customer_id = o.customer_id
join payments as p on o.order_id = p.order_id
group by c.customer_unique_id,c.customer_city,c.customer_state
order by total_spent desc
limit 10;

-- Order Status Distribution

SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- Monthly Revenue Trend (2017-2018)

select 
	date_format(o.order_purchase_timestamp,"%y-%m") as months,
    count(distinct o.order_id )as total_orders,
    round(sum(p.payment_type),2) as total_revenue,
    round(avg(p.payment_type),2) as avg_order_value
from orders as o
join payments as p on o.order_id = p.order_id
where o.order_purchase_timestamp is not null
group by date_format(o.order_purchase_timestamp,"%y-%m")
order by months;

-- Top 10 Sellers by Revenue

SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_product_price
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;

-- 1. Order Items → Products JOIN
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- 2. Order Items → Sellers JOIN  
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);

-- 3. Orders → Customers JOIN
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- 4. Payments → Orders JOIN
CREATE INDEX idx_payments_order_id ON payments(order_id);

-- 5. Reviews → Orders JOIN
CREATE INDEX idx_reviews_order_id ON reviews(order_id);

SHOW INDEX FROM reviews;


-- 6. Filter by order status
CREATE INDEX idx_orders_status ON orders(order_status);

-- 7. Date range queries
CREATE INDEX idx_orders_purchase_date ON orders(order_purchase_timestamp);

-- 8. Payment type analysis
CREATE INDEX idx_payments_type ON payments(payment_type);


WITH revenue_data AS (
    SELECT 
        o.order_id,
        p.payment_value,
        o.order_purchase_timestamp
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
)

SELECT 
    DATE_FORMAT(order_purchase_timestamp,"%Y-%m") AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value),2) AS total_revenue
FROM revenue_data
GROUP BY month
ORDER BY month;


SELECT 
    c.customer_unique_id,
    SUM(p.payment_value) AS total_spent,
    rank()OVER (ORDER BY SUM(p.payment_value) DESC) AS rank_position
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id;

select 
	date_format(o.order_purchase_timestamp,"%y-%m") as months,
    sum(p.payment_value) as monthly_revenue,
    sum(sum(p.payment_value)) over(order by date_format(o.order_purchase_timestamp,"%y-%m")) as running_total
from orders as o
join payments as p on o.order_id = p.order_id
group by months;


CREATE VIEW monthly_revenue AS
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp,"%Y-%m") AS month,
    SUM(p.payment_value) AS revenue
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY month;


SELECT * FROM monthly_revenue;