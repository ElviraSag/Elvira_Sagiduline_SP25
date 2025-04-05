DELETE FROM film_actor 
WHERE film_id  = 1006
RETURNING *;

---------------------------------------
--Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
--Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

WITH guardians_of_the_galaxy AS (
	 SELECT
	'Guardians of the Galaxy' AS title,
	'After stealing a mysterious orb in the far reaches of outer space, Peter Quill from Earth is now the main target of a manhunt led by the villain known as Ronan the Accuser. To help fight Ronan and his team and save the galaxy from his power, Quill creates a team of space heroes known as the "Guardians of the Galaxy" to save the galaxy.' AS description,
	2014 AS release_year,
	1 AS language_id,
	1 AS rental_duration,
	4.99 AS rental_rate,
	121 AS length,
	19.99 AS replacement_cost,
	'PG-13'::mpaa_rating AS rating,
	NOW() AS last_update,
	'{Trailers, Deleted Scenes, Commentaries}'::text[] AS special_features,
	to_tsvector('english',
	'A group of intergalactic criminals must pull together to stop a fanatical warrior with plans to purge the universe.') AS fulltext
),
fantastic_mr_fox AS (
     SELECT
	'Fantastic Mr. Fox' AS title,
	'This is the story of Mr. Fox (George Clooney) and his wild ways of hen heckling, turkey taking, and cider sipping, nocturnal, instinctive adventures.' AS description,
	2009 AS release_year,
	1 AS language_id,
	2 AS rental_duration,
	9.99 AS rental_rate,
	87 AS length,
	15.99 AS replacement_cost,
	'PG'::mpaa_rating AS rating,
	NOW() AS last_update,
	'{Trailers, Deleted Scenes, Commentaries}'::text[] AS special_features,
	to_tsvector('english',
	'An urbane fox cannot resist returning to his farm raiding ways and then must help his community survive the farmers retaliation.') AS fulltext
),
revolver AS (
     SELECT
	'Revolver' AS title,
	'After seven years in solitary, Jake Green is released from prison. In the next two years, he amasses a lot of money by gambling. He is ready to seek his revenge on Dorothy (Mr. D) Macha, a violence-prone casino owner who sent Jake to prison.' AS description,
	2005 AS release_year,
	1 AS language_id,
	3 AS rental_duration,
	19.99 AS rental_rate,
	115 AS length,
	17.99 AS replacement_cost,
	'R'::mpaa_rating AS rating,
	NOW() AS last_update,
	'{Trailers, Deleted Scenes, Commentaries}'::text[] AS special_features,
	to_tsvector('english',
	'Gambler Jake Green enters into a game of one-upmanship against crime boss Dorothy Macha.') AS fulltext
)
-- Inserting all films at once while avoiding duplicates
INSERT
	INTO
	public.film (
    title,
	description,
	release_year,
	language_id,
	rental_duration,
	rental_rate,
	length,
	replacement_cost,
	rating,
	last_update,
	special_features,
	fulltext
)
SELECT	*
FROM	guardians_of_the_galaxy
WHERE NOT EXISTS (
	SELECT 1
	FROM public.film f
	WHERE f.title = 'Guardians of the Galaxy'
)
UNION ALL
SELECT	*
FROM fantastic_mr_fox
WHERE NOT EXISTS (
	SELECT 1
	FROM public.film f
	WHERE f.title = 'Fantastic Mr. Fox'
)
UNION ALL
SELECT *
FROM revolver
WHERE NOT EXISTS (
	SELECT 1
	FROM public.film f
	WHERE f.title = 'Revolver'
)
RETURNING *;


------------------------------------------------
--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  
--Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.
INSERT INTO public.actor (first_name, last_name)
SELECT * FROM (VALUES 
    ('Chris', 'Patt'),
    ('Zoe', 'Zaldana'),
    ('George', 'Clooney'),
    ('Meryl', 'Streep'),
    ('Jason', 'Statham'),
    ('Ray', 'Liotta')
) AS new_actors (first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM public.actor a
    WHERE a.first_name = new_actors.first_name
    AND a.last_name = new_actors.last_name
)
RETURNING *;

---------------------------------------------------------------------
-- populatinh 'film_actor' table with my data
    
WITH guardian_actors AS (
	SELECT a.actor_id, f.film_id FROM actor a 
	CROSS JOIN film f 
	WHERE f.title = 'Guardians of the Galaxy' AND a.last_name IN ('Patt', 'Zaldana')
),
fox_actors AS (
	SELECT  a.actor_id, f.film_id  FROM actor a 
	CROSS JOIN film f 
	WHERE f.title = 'Fantastic Mr. Fox' AND a.last_name IN ('Clooney', 'Streep')
),
revolver_actors AS (
	SELECT  a.actor_id, f.film_id  FROM actor a 
	CROSS JOIN film f 
	WHERE f.title = 'Revolver' AND a.last_name IN ('Statham', 'Liotta')
)
INSERT INTO public.Film_actor (actor_id, film_id)
SELECT * FROM guardian_actors
UNION ALL
SELECT * FROM fox_actors 
UNION ALL
SELECT * FROM revolver_actors
RETURNING *;

----------------------------------------------------------------
--Add your favorite movies to any store's inventory.
INSERT INTO public.inventory ( film_id, store_id)
SELECT f.film_id, 1 --store_id is 1
FROM public.film f 
WHERE NOT EXISTS (
    SELECT 1
    FROM public.inventory i
    WHERE i.film_id = f.film_id
    AND i.store_id = 1
)
RETURNING film_id, store_id, last_update ;
-----------------------------
--Alter any existing customer in the database with at least 43 rental and 43 payment records. 
--Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. 
--Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.
INSERT INTO public.rental(
    rental_date,
    inventory_id,
    customer_id,
    staff_id
)
VALUES (
    now(), 
    FLOOR(1 + RANDOM() * 4000),  -- Random integer between 1 and 4000 for inventory_id
    5, 							-- My choise OF customer ID
    FLOOR(1 + RANDOM() * 5)     -- Random integer between 1 and 5 for staff_id
)
RETURNING *;



INSERT INTO public.payment (
	customer_id,
	staff_id,
	rental_id,
	amount,
	payment_date
	)
SELECT r.customer_id, r.staff_id, r.rental_id, (0.99 + FLOOR(RANDOM() * 10)) AS amount, DATE '2017-01-01' + (FLOOR(RANDOM() * (DATE '2017-05-30' - DATE '2017-01-01' + 1)) * INTERVAL '1 day') AS payment_date
FROM public.rental r
WHERE r.customer_id = 5 AND DATE_PART('year', r.last_update) = 2025
RETURNING *;


UPDATE public.customer
SET
    store_id = 1,
    first_name = 'Elvira',
    last_name = 'Sagiduline',
    email = 'elvirasag@outlook.com',
    address_id = 45,
    create_date = NOW(),  
    last_update = NOW(), 
    active = 1
WHERE
    customer_id = 5;

--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
DELETE FROM public.rental  
WHERE customer_id = 5
RETURNING *;

DELETE FROM public.payment
WHERE customer_id = 5
RETURNING *;

DELETE FROM public.payment 
WHERE customer_id = 5
RETURNING *;

----------------------------------------------
--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the
--first half of 2017)

INSERT INTO public.rental(
    rental_date,
    inventory_id,
    customer_id,
    staff_id
)
SELECT now(),  i.inventory_id, c.customer_id, FLOOR(1 + RANDOM() * 5) AS staff_id
    FROM public.inventory i
    JOIN public.film f
    ON i.film_id = f.film_id 
    JOIN public.customer c
    ON i.store_id = c.store_id
    WHERE f.title = 'Revolver' AND c.last_name  = 'Sagiduline'  
RETURNING *;

INSERT INTO public.payment (
	customer_id,
	staff_id,
	rental_id,
	amount,
	payment_date
	)
SELECT r.customer_id, r.staff_id, r.rental_id, '6.99' AS amount, DATE '2017-01-01' + (FLOOR(RANDOM() * (DATE '2017-05-30' - DATE '2017-01-01' + 1)) * INTERVAL '1 day') AS payment_date
FROM public.rental r
JOIN  public.inventory i
ON r.inventory_id = i.inventory_id
JOIN  public.film f
ON i.film_id = f.film_id
WHERE r.customer_id = 5 AND f.title = 'Revolver'
RETURNING *;
