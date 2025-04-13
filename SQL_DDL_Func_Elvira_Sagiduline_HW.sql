--Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. 
--The view should only display categories with at least one sale in the current quarter. 
--Note: when the next quarter begins, it will be considered as the current quarter.


DO $$
DECLARE
    if_view_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = 'public'
          AND table_name = 'sales_revenue_by_category_qtr'
    ) INTO if_view_exists;
    IF if_view_exists THEN
        RAISE NOTICE 'View already exists. Dropping and recreating...';
        DROP VIEW public.sales_revenue_by_category_qtr;
    END IF;
        CREATE VIEW public.sales_revenue_by_category_qtr AS
        SELECT
            c.name AS category,
            ROUND(SUM(p.amount), 2) AS total_revenue,
            EXTRACT(YEAR FROM p.payment_date) AS years,
            EXTRACT(QUARTER FROM p.payment_date) AS quarters
        FROM
            payment p
            JOIN rental r ON p.rental_id = r.rental_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
        GROUP BY
            c.name,
            EXTRACT(YEAR FROM p.payment_date),
            EXTRACT(QUARTER FROM p.payment_date)
        HAVING SUM(p.amount) > 0;
END $$;

--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing the current 
--quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.


CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(IN accepted_date DATE)
RETURNS TABLE (
    category TEXT,
    total_revenue NUMERIC(10,2),
    years INT,
    quarters INT
)
LANGUAGE SQL
AS $$
    SELECT * from public.sales_revenue_by_category_qtr
    WHERE
        years = EXTRACT(YEAR FROM accepted_date)
        AND quarters = EXTRACT(QUARTER FROM accepted_date)
$$;

--Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
--The function should format the result set as follows:
--Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);


CREATE OR REPLACE FUNCTION most_popular_films_by_countries(IN interested_in_countries TEXT[])
RETURNS TABLE (
    country TEXT,
    film_title TEXT,
    rating TEXT,
    Languege TEXT,
    lenght INT,
    release_year INT,
    rental_count INT
)
LANGUAGE SQL
AS $$
WITH ranked_films_per_country AS (
        SELECT
            co.country,
            f.title,
            f.rating,
            l.name as Languege,
            f.length,
            f.release_year,
            COUNT(r.rental_id) AS rental_count
        FROM
            rental r
            JOIN customer cu ON r.customer_id = cu.customer_id
            JOIN address a ON cu.address_id = a.address_id
            JOIN city ci ON a.city_id = ci.city_id
            JOIN country co ON ci.country_id = co.country_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN language l ON l.language_id = f.language_id
        GROUP BY
            co.country, f.title, f.rating, l.name, f.length, f.release_year
    ),
    max_per_country_rented AS ( 
    	SELECT country,
            MAX(rental_count) AS max_rented
        FROM ranked_films_per_country
        GROUP BY country
    )
    SELECT
        r.country,
        title,
		rating,
		Languege,
		length,
		release_year,
        rental_count
    FROM
        ranked_films_per_country r
    JOIN max_per_country_rented m ON r.country = m.country
    WHERE rental_count = max_rented
		AND r.country = ANY(interested_in_countries)
	;
$$;

select * from most_popular_films_by_countries(array['Afghanistan','Brazil','United States']);


--Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
--The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.
--The function should produce the result set in the following format (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
--                    Query (example):select * from core.films_in_stock_by_title('%love%’);

CREATE OR REPLACE FUNCTION films_in_stock_by_title(IN partial_title TEXT)
RETURNS TABLE (
    row_num BIGINT,
    film_titles TEXT,
    film_language bpchar(20),
    customer_name TEXT,
    rental_dates TIMESTAMP,
    available_nr BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY f.title) AS row_num,
        f.title AS film_titles,
        l.name AS film_language,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        r.rental_date::timestamp AS rental_dates,
        COUNT(*) OVER (PARTITION BY f.title) AS available_nr
    FROM
        film f
        JOIN inventory i ON f.film_id = i.film_id
        JOIN language l ON l.language_id = f.language_id 
        LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
        JOIN customer c ON r.customer_id = c.customer_id 
    WHERE
        f.title ILIKE '%' || partial_title || '%';

       IF NOT FOUND THEN
        RAISE NOTICE 'No matching films found for input: %', partial_title;
    END IF;
END;
$$;


select * from films_in_stock_by_title('%love%');


--Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new 
--movie with the given title in the film table. The function should generate a new unique film ID, set the rental rate 
--to 4.99, the rental duration to three days, the replacement cost to 19.99. The release year and language are optional 
--and by default should be current year and Klingon respectively. The function should also verify that the language exists
-- in the 'language' table. Then, ensure that no such function has been created before; if so, replace it.

CREATE OR REPLACE FUNCTION new_movie(
    new_movie_title TEXT,
    new_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    Klingon_language_name TEXT DEFAULT 'Klingon'
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    new_language_id INTEGER;
BEGIN
    -- Check if the language exists
    SELECT language_id INTO new_language_id
    FROM language
    WHERE name ILIKE Klingon_language_name
    LIMIT 1;

    -- If the language does not exist, raise exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" not found in the language table.', Klingon_language_name;
    END IF;

    -- Insert the new movie
    INSERT INTO film (
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    )
    VALUES (
        new_movie_title,
        new_release_year,
        new_language_id,
        3,
        4.99,
        19.99,
        NOW()
    );
END;
$$;

