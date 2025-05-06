----
    ----task1
WITH customer_sales AS ( --total sales per customer
    SELECT s.channel_id, s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sales s
    GROUP BY s.channel_id, s.cust_id
),
ranked_customers AS (
    SELECT cs.channel_id, cs.cust_id, cs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.channel_id ORDER BY cs.total_sales DESC) AS rank,
          --Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within their respective channel.
        ROUND((cs.total_sales * 100) / SUM(cs.total_sales) OVER (PARTITION BY cs.channel_id), 4) || '%' AS sales_percentage
    FROM customer_sales cs
)
SELECT
    channel_id, cust_id, ROUND(total_sales,2) AS total_sales, -- Display the total sales amount with two decimal places
    sales_percentage, rank
FROM ranked_customers
WHERE rank <= 5 --This report should list the top 5 customers for each channel.
ORDER BY channel_id, total_sales DESC; -- Display the result for each channel in descending order of sales

----
--task2

WITH product_sales AS (-- Aggregate the total sales for products in the Photo category in the Asian region for the year 2000
        SELECT p.prod_id, p.prod_name,
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
-- final result and display the sales and the YEAR_SUM
SELECT ps.prod_name,
    ROUND(ps.total_sales, 2) AS total_sales,
   yt.year_sum
FROM product_sales ps, year_total yt
ORDER BY  yt.year_sum DESC;
-------------
---------task 3
WITH customer_sales AS (-- Calculating total sales per customer in years 1998, 1999, and 2001
    SELECT s.cust_id, ch.channel_desc, 
    	   SUM(s.amount_sold) AS total_sales,
           t.calendar_year
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN channels ch ON ch.channel_id = s.channel_id
    WHERE t.calendar_year  IN (1998, 1999, 2001)  --  based on total sales in the years 1998, 1999, and 2001. 
    GROUP BY s.cust_id, s.channel_id, ch.channel_desc, t.calendar_year
),
customer_ranking AS (  -- Rank customers by their total sales per channel across the specified years
    SELECT cs.cust_id, cs.channel_desc,
       cs.total_sales,
       RANK() OVER (PARTITION BY cs.channel_desc ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT cr.cust_id, cr.channel_desc,
    ROUND(cr.total_sales, 2) AS total_sales  -- Format the column so that total sales are displayed with two decimal places
FROM customer_ranking cr
WHERE cr.sales_rank <= 300  -- Retrieve customers who ranked among the top 300 
ORDER BY cr.channel_desc, cr.sales_rank;  -- Ordering by sales channel and rank

----
--task4
SELECT
    t.calendar_month_number,
    t.calendar_month_desc,
    p.prod_category AS product_category,
    SUM(CASE WHEN cn.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) AS Europe_sales,
    SUM(CASE WHEN cn.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) AS Americas_sales
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
    t.calendar_month_number,
    t.calendar_month_desc,
    p.prod_category
ORDER BY
   t.calendar_month_number,
   t.calendar_month_desc,-- Order by month (January, February, March)
    p.prod_category;  -- Order product categories alphabetically
 
