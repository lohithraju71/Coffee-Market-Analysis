select * from city;
select * from sales;
select * from customers;
select * from products;

--    Easy - Medium Questions 

-- 1) Coffee Consumers Count 
--    How many people in each city are estimated to consume coffee, given that 25% of the population does? 

 

select 
	city_name,
	round((population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
	city_rank
from city
order by 2 desc;


-- 2) Total Revenue from Coffee Sales
--    What is the total revenue generated from coffee sales across all cities in last quarter of 2023?

select
    sum(total) as total_revenue
from sales
where
	extract (year from sale_date) = 2023
	and
	extract (quarter from sale_date) = 4
    


select
	ci.city_name,
    sum(s.total) as total_revenue
from sales as s 
	join customers as c 
	on s.customer_id = c.customer_id
	join city as ci
	on ci.city_id = c.city_id
where
	extract (year from s.sale_date) = 2023
	and
	extract (quarter from s.sale_date) = 4
group by city_name
order by 2 desc;



SELECT SUM(city_data.total_revenue) AS grand_total_revenue
from (
select
	ci.city_name,
    sum(s.total) as total_revenue
from sales as s 
	join customers as c 
	on s.customer_id = c.customer_id
	join city as ci
	on ci.city_id = c.city_id
where
	extract (year from s.sale_date) = 2023
	and
	extract (quarter from s.sale_date) = 4
group by city_name
order by 2 desc
) as city_data;



-- 3) Sales count for each product
--    How many units of each coffee product have been sold?



select 
	p.product_name,
	count(s.sale_id) as total_orders
 from products as p
 left join sales as s
 on p.product_id = s.product_id
group by 1
order by 2 desc;


-- 4) Average sales amount per city
--    What is the average sales amount per customer in each city?


SELECT 
  ci.city_name,
  ROUND(SUM(s.total)::numeric / COUNT(DISTINCT c.customer_id)::numeric, 2) AS avg_sales_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY 2 desc;



SELECT
  customer_totals.city_name,
  ROUND(AVG(customer_totals.customer_total)::numeric, 2) AS avg_sales_per_customer
FROM (
  SELECT
    ci.city_name,
    c.customer_id,
    SUM(s.total) AS customer_total
  FROM sales s
  JOIN customers c ON s.customer_id = c.customer_id
  JOIN city ci ON c.city_id = ci.city_id
  GROUP BY ci.city_name, c.customer_id
) AS customer_totals
GROUP BY customer_totals.city_name
ORDER BY 2 desc;




-- 5) City population and Coffee consumers
--    Provide a list of cities along with their populations and estimated coffee consumers.


SELECT 
  ci.city_name,
  ROUND(ci.population / 1000000.0, 2) AS population_in_millions,
  ROUND((ci.population * 0.25) / 1000000.0, 2) AS estimated_coffee_consumers_in_millions,
  COALESCE(COUNT(DISTINCT c.customer_id), 0) AS actual_customer_count
FROM city ci
LEFT JOIN customers c ON c.city_id = ci.city_id
LEFT JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name, ci.population
ORDER BY ci.city_name;



-- 6) Top selling products by city
--    What are the top 3 selling products in each city based on sales volume?


SELECT * 
FROM -- table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
	-- ORDER BY 1, 3 DESC
) as t1
WHERE rank <= 3


-- 7) Customer segmentation by city
--    How many unique customers are there in each city who have purchased coffee products?


SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customers
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id <=14
GROUP BY 1


-- 8) Impact of estimated rent on sales
--    Find each city and their average sale per customer and average rent per customer.


SELECT 
  ci.city_name,
  ROUND(SUM(s.total)::NUMERIC / COUNT(DISTINCT c.customer_id)::NUMERIC, 2) AS avg_sale_per_customer,
  ROUND(ci.estimated_rent::NUMERIC / COUNT(DISTINCT c.customer_id)::NUMERIC, 2) AS avg_rent_per_customer
FROM city ci
JOIN customers c ON c.city_id = ci.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY 3 desc;



-- 9) Monthly Sales Growth
--    Calculate the percentage growth (or decline) in sales over different time periods (monthly)

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	


-- 10) Market Potential Analysis
--     Identify top 3 city based on total sale, total rent, total customers, estimated coffee consumers.


WITH city_sales AS (
  SELECT 
    ci.city_id,
    ci.city_name,
    SUM(s.total) AS total_sale,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ci.population,
    ci.estimated_rent
  FROM city ci
  LEFT JOIN customers c ON c.city_id = ci.city_id
  LEFT JOIN sales s ON s.customer_id = c.customer_id
  GROUP BY ci.city_id, ci.city_name, ci.population, ci.estimated_rent
)
SELECT 
  city_name,
  total_sale,
  estimated_rent * total_customers AS total_rent,
  total_customers,
  ROUND((population * 0.25)/1000000::NUMERIC, 2) AS estimated_coffee_consumers_in_millions
FROM city_sales
ORDER BY total_sale DESC;


