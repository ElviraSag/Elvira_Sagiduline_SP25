----
    ----task1
WITH customer_sales AS ( --total sales per customer
    SELECT c.channel_desc, s.channel_id, cu.cust_first_name, cu.cust_last_name,
        SUM(s.amount_sold) AS total_sales
    FROM sales s
    JOIN channels c ON s.channel_id = c.channel_id
    JOIN customers cu ON cu.cust_id = s.cust_id
    GROUP BY c.channel_desc , s.channel_id, cu.cust_first_name, cu.cust_last_name, s.cust_id
),
ranked_customers AS (
    SELECT cs.channel_desc, cs.channel_id, cs.cust_first_name, cs.cust_last_name , cs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.channel_id ORDER BY cs.total_sales DESC) AS rank,
          --Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within their respective channel.
        ROUND((cs.total_sales * 100) / SUM(cs.total_sales) OVER (PARTITION BY cs.channel_id), 4) || '%' AS sales_percentage
    FROM customer_sales cs
)
SELECT
    channel_desc , cust_last_name , cust_first_name, ROUND(total_sales,2) AS amount_sold, -- Display the total sales amount with two decimal places
    sales_percentage
FROM ranked_customers
WHERE rank <= 5 --This report should list the top 5 customers for each channel.
ORDER BY channel_desc , channel_id, total_sales DESC; -- Display the result for each channel in descending order of sales


SELECT * FROM times;
----
--task2

WITH product_sales AS (-- Aggregate the total sales for products in the Photo category in the Asian region for the year 2000
        SELECT p.prod_id, p.prod_name,
        SUM(CASE WHEN t.calendar_quarter_desc = '2000-01' THEN s.amount_sold ELSE 0 END) AS q1,
        SUM(CASE WHEN t.calendar_quarter_desc = '2000-02' THEN s.amount_sold ELSE 0 END) AS q2,
        SUM(CASE WHEN t.calendar_quarter_desc = '2000-03' THEN s.amount_sold ELSE 0 END) AS q3,
        SUM(CASE WHEN t.calendar_quarter_desc = '2000-04' THEN s.amount_sold ELSE 0 END) AS q4,
        SUM(s.amount_sold) AS total_sales
    FROM sales s
    JOIN products p ON s.prod_id = p.prod_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries cn ON c.country_id = cn.country_id 
    JOIN times t ON s.time_id = t.time_id
    WHERE p.prod_category  = 'Photo'  -- Filter for the Photo category
        AND cn.country_region = 'Asia'  -- Filter for the Asian region
        AND t.calendar_year = 2000  -- Filter for the year 2000
    GROUP BY p.prod_id, p.prod_name
),
year_total AS (-- Calculate the overall total sales for the year 2000 in the Photo category in the Asian region
    SELECT SUM(total_sales) AS year_sum
    from  product_sales
)
-- final result to display the sales and the YEAR_SUM
SELECT ps.prod_name, ROUND(q1,2), ROUND(q2,2), ROUND(q3,2), ROUND(q4,2),
   yt.year_sum
FROM product_sales ps, year_total yt
ORDER BY  yt.year_sum DESC;


-------task2 with crosstab
CREATE EXTENSION IF NOT EXISTS tablefunc;
SELECT  ct.prod_name, ct."Q1",ct."Q2",ct."Q3",ct."Q4",
  ROUND(COALESCE(ct."Q1", 0) + COALESCE(ct."Q2", 0) + COALESCE(ct."Q3", 0) + COALESCE(ct."Q4", 0),2) AS year_sum
FROM crosstab(
    $$
    SELECT p.prod_name, t.calendar_quarter_desc,SUM(s.amount_sold) as year_sum
    FROM sales s
    JOIN products p ON s.prod_id = p.prod_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries cn ON c.country_id = cn.country_id
    JOIN times t ON s.time_id = t.time_id
    WHERE p.prod_category = 'Photo'
        AND cn.country_region = 'Asia'
        AND t.calendar_year = 2000
    GROUP BY p.prod_name, t.calendar_quarter_desc, t.calendar_year
    ORDER BY p.prod_name, t.calendar_quarter_desc, t.calendar_year
    $$, $$ VALUES ('2000-01'), ('2000-02'), ('2000-03'), ('2000-04')$$
) AS ct ( prod_name TEXT, "Q1" NUMERIC,"Q2" NUMERIC,"Q3" NUMERIC,"Q4" NUMERIC
   );

-------------
---------task 3
WITH customer_sales AS (-- Calculating total sales per customer in years 1998, 1999, and 2001
    SELECT s.cust_id, ch.channel_desc, cu.cust_first_name, cu.cust_last_name,
    	   SUM(s.amount_sold) AS amount_sold,
           t.calendar_year
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN channels ch ON ch.channel_id = s.channel_id
    JOIN customers cu ON cu.cust_id = s.cust_id
    WHERE t.calendar_year  IN (1998, 1999, 2001)  --  based on total sales in the years 1998, 1999, and 2001. 
    GROUP BY s.cust_id, s.channel_id, ch.channel_desc, t.calendar_year, cust_first_name, cust_last_name
),
customer_ranking AS (  -- Rank customers by their total sales per channel across the specified years
    SELECT cs.cust_id, cs.channel_desc, cust_first_name, cust_last_name,
       cs.amount_sold,
       RANK() OVER (PARTITION BY cs.channel_desc ORDER BY cs.amount_sold DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT  cr.channel_desc, cr.cust_id, cust_first_name, cust_last_name,
    ROUND(cr.amount_sold, 2) AS amount_sold  -- Format the column so that total sales are displayed with two decimal places
FROM customer_ranking cr
WHERE cr.sales_rank <= 300  -- Retrieve customers who ranked among the top 300 
ORDER BY cr.channel_desc, cr.sales_rank;  -- Ordering by sales channel and rank

----
--task4
SELECT
    t.calendar_month_desc,
    p.prod_category AS product_category,
    SUM(CASE WHEN cn.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) AS "Europe SALES",
    SUM(CASE WHEN cn.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) AS "Americas SALES"
FROM
    sales s
JOIN
    products p ON s.prod_id = p.prod_id
JOIN times t ON s.time_id = t.time_id
JOIN customers c ON s.cust_id = c.cust_id
JOIN countries cn ON c.country_id = cn.country_id 
WHERE t.calendar_year = 2000  -- Filter for the year 2000
    AND t.calendar_month_number IN (1, 2, 3)  -- Filter for January, February, and March
    AND cn.country_region IN ('Europe', 'Americas')  -- Filter for Europe and Americas regions
GROUP BY
    t.calendar_month_desc,
    p.prod_category
ORDER BY
   t.calendar_month_desc,-- Order by month (January, February, March)
    p.prod_category;  -- Order product categories alphabetically
 
