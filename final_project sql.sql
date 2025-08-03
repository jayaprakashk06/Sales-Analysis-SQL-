create database sales;
use sales;
drop table customers;
create table customers(
customer_id	int,
first_name	varchar(100),
last_name varchar(100),
address_email varchar(100),
phone_number int
);
select * from customers;
select * from order_items;
select * from orders;
select * from payment;
select * from products;
describe customers;
select count(*) from customers;

-- joining the table for analysis
-- orders and customers
select
o.order_id,
o.order_date,
o.total_price,
c.customer_id,
c.email
from orders o
join customers c on o.customer_id=c.customer_id
limit 10;
 
 -- order_item and product
alter table customers add full_name varchar(100);
update customers
set full_name=concat(first_name," ",last_name);

 select
 o.order_id,
 c.full_name as customer_name,
 p.product_id,
 p.product_name,
 oi.quantity,
 oi.price_at_purchase
 from orders o
 join customers c on o.customer_id=c.customer_id
 join order_items oi on o.order_id=oi.order_id
 join products p on oi.product_id=p.product_id
 limit 10;
 
 -- payments
SELECT 
    o.order_id,
    c.full_name AS customer_name,
    pr.product_name,
    oi.quantity,
    oi.price_at_purchase,
    pay.payment_method,
    pay.transaction_status,
    pay.amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products pr ON oi.product_id = pr.product_id
JOIN payment pay ON o.order_id = pay.order_id
LIMIT 10;
-- checking duplicates 
SELECT order_id, COUNT(*) FROM orders GROUP BY order_id HAVING COUNT(*) > 1;
-- checking for nulls
SELECT COUNT(*) FROM customers WHERE email IS NULL;

-- 1 insights from various aspects

select distinct transaction_status from payment;

select * from customers;
select * from order_items;
select * from orders;
select * from payment;
select * from products;

-- 2 total revenue by products
select
 p.product_name,
round(sum(oi.quantity * oi.price_at_purchase))	as total_revenue
from order_items as oi
join products p on oi.product_id=p.product_id
group by p.product_name
order by total_revenue desc
limit 10;

-- 3 category vs sales
select 
p.category,
sum(oi.quantity) as total_units_sold,
round(sum(oi.quantity*oi.price_at_purchase),2)as total_revenue
from order_items as oi
join products as p on oi.product_id=p.product_id
group by p.category
order by total_revenue desc;

-- 4 count of transaction_status as categories

select transaction_status,
count(*) as total_transaction
from payment
group by transaction_status
order by total_transaction;

-- 5 TOP 10 BUYERS
select 
c.customer_id,
c.full_name,
round(sum(p.amount)) as Total_spent
from customers as c
join orders o on c.customer_id=o.customer_id
join payment p on o.order_id=p.order_id
where p.transaction_status="completed"
group by c.customer_id,c.full_name
order by Total_spent desc
limit 10;

-- 6 transaction income
select transaction_status,
count(*) as t_status,
CONCAT('₹', FORMAT(SUM(amount), 0)) AS total_amount
from payment
group by transaction_status
order by total_amount asc ;

-- 7 month vs trend
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
	round((SUM(p.amount)))AS total_revenue
FROM orders o
JOIN payment p ON o.order_id = p.order_id
WHERE p.transaction_status = 'Completed'  
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY total_revenue desc;

-- 8 diffrencing categories as high spender,medium spender,low spender
SELECT 
    customer_id,
    full_name,
    total_spent,
    CASE 
        WHEN total_spent >= 1500 THEN 'High Spender'
        WHEN total_spent >= 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS customer_segment
FROM (
    SELECT 
        c.customer_id,
        c.full_name,
        SUM(p.amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payment p ON o.order_id = p.order_id
    WHERE p.transaction_status = 'completed'
    GROUP BY c.customer_id, c.full_name
) AS customer_summary
ORDER BY total_spent DESC;

-- 9 count of high spender low pender medium spender

SELECT 
  customer_segment,
  COUNT(*) AS customer_count_on_category
FROM (
    SELECT 
        c.customer_id,
        c.full_name,
        SUM(p.amount) AS total_spent,
        CASE 
            WHEN SUM(p.amount) >= 1500 THEN 'High Spender'
            WHEN SUM(p.amount) >= 1000 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END AS customer_segment
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payment p ON o.order_id = p.order_id
    WHERE p.transaction_status = 'completed'
    GROUP BY c.customer_id, c.full_name
) AS customer_summary
GROUP BY customer_segment
ORDER BY customer_count_on_category DESC;

-- 10 customer lifetime value
SELECT 
    c.customer_id,
    c.full_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(p.amount) AS total_spent,
    ROUND(AVG(p.amount), 0) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payment p ON o.order_id = p.order_id
WHERE p.transaction_status = 'completed'
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC
limit 10;

-- 11 Order Success Rate by Product Category
SELECT 
    p.category,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN pay.transaction_status = 'Completed' THEN 1 ELSE 0 END) AS successful_orders,
    SUM(CASE WHEN pay.transaction_status = 'Pending' THEN 1 ELSE 0 END) AS pending_orders,
    ROUND(
        SUM(CASE WHEN pay.transaction_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS success_rate_percent
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN payment pay ON o.order_id = pay.order_id
GROUP BY p.category
ORDER BY success_rate_percent desc;


