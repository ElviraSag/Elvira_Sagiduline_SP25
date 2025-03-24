---All animation movies released between 2017 and 2019 with rate more than 1, alphabetical

--ANSWER1
select
	f.title,
	f.rental_rate,
	f.release_year
from
	public.film f
join film_category fc
on
	f.film_id = fc.film_id
join category c
on
	fc.category_id = c.category_id
where
	(f.release_year between 2017 and 2019)
	and f.rental_rate > 1
	and c.name = 'Animation'
order by
	f.title;

--ANSWER2
with animation_films as (
select
	f.film_id,
	f.title,
	f.rental_rate,
	f.release_year
from
	public.film f
join film_category fc on
	f.film_id = fc.film_id
join category c on
	fc.category_id = c.category_id
where
	c.name = 'Animation'
)
select
	af.title,
	af.rental_rate,
	af.release_year
from
	animation_films af
where
	af.release_year between 2017 and 2019
	and af.rental_rate > 1
order by
	af.title;
------------------------------------------------------------------------------------------------------------------
--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)

--ANSWER
with store_adress as (
select
	s.store_id,
	CONCAT(c.city,
	',',
	c2.country) as State,
	CONCAT(a.address,
	' ' ,
	a.address2) as address
from
	public.store s
join address a
on
	a.address_id = s.address_id
join city c
on
	c.city_id = a.city_id
join country c2
on
	c.country_id = c2.country_id
join sales_by_store sbs
on
	sbs.store = CONCAT(c.city,
	',',
	c2.country)
order by
	s.store_id )
select
	sa.store_id ,
	sa.state,
	sa.address,
	sum(amount)
from
	payment p
join customer_list cl
on
	cl.id = p.customer_id
join customer c
on
	cl.id = c.customer_id
join store_adress sa
on
	sa.store_id = c.store_id
where
	DATE_PART('month',
	payment_date) > 3
	and DATE_PART('year',
	payment_date) >2016
group by
	sa.store_id,
	sa.state,
	sa.address;

--------------------------------------------------------------------------------------------------------
--Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
--ANSWER
select
	a.first_name,
	a.last_name ,
	COUNT(fa.film_id) as number_of_movies
from
	film_actor fa
join actor a
on
	fa.actor_id = a.actor_id
join film f
on
	f.film_id = fa.film_id
where
	release_year > 2015
group by
	fa.actor_id,
	a.first_name,
	a.last_name
order by
	number_of_movies desc
limit 5;

-------------------------------------------------------------------------------------------------------------------
--Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies),
--sorted by release year in descending order. Dealing with NULL values is encouraged)
--ANSWER
select
	f.release_year,
	COUNT(*) filter (
where
	c.name = 'Drama') as number_of_drama_movies,
	COUNT(*) filter (
where
	c.name = 'Travel') as number_of_travel_movies,
	COUNT(*) filter (
where
	c.name = 'Documentary') as number_of_documentary_movies
from
	film f
join film_category fc
on
	f.film_id = fc.film_id
join category c
on
	c.category_id = fc.category_id
group by
	f.release_year
order by
	f.release_year desc;

-----------------------------------------------------------------------------------------------------------------
--Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance.
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store;
--take into account only payment_date
--ANSWER
with staff_name as (
select
	staff_id,
	first_name,
	last_name,
	MAX(store_id) wortket_at_store
from
	staff
group by
	staff_id,
	first_name,
	last_name),
store_name as (
select
	s.store_id,
	c.city,
	c2.country
from
	store s
join address a on
	s.address_id = a.address_id
join city c on
	a.city_id = c.city_id
join country c2 on
	c.country_id = c2.country_id )
select
	p.staff_id,
	sn.first_name ,
	sn.last_name ,
	SUM(p.amount) as revenue,
	CONCAT(stn.city,
	stn.country) as store_name
from
	payment p
join staff_name sn
on
	sn.staff_id = p.staff_id
join store_name stn
on
	stn.store_id = sn.wortket_at_store
where
	DATE_PART('year',
	p.payment_date) = 2017
group by
	p.staff_id,
	DATE_PART('year',
	payment_date),
	sn.first_name ,
	sn.last_name,
	sn.wortket_at_store,
	stn.city,
	stn.country
order by
	revenue desc
limit 3;

---------------------------------------------------------------------------------------------
-- Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?
-- To determine expected age please use 'Motion Picture Association film rating system
--ANSWER
select
	i.film_id,
	f.title,
	f.rating,
	COUNT(r.rental_id) as how_many_times_rented
from
	inventory i
join rental r
on
	i.inventory_id = r.inventory_id
join film f
on
	i.film_id = f.film_id
group by
	i.film_id,
	f.title,
	f.rating
order by
	how_many_times_rented desc
limit 5;

----------------------------------------------------------------------------------------
--Which actors/actresses didn't act for a longer period of time than the others?
--V1: gap between the latest release_year and current year per each actor;

--ANSWER1
with actor_name as (
--This CTE reflects actor_info table
select
	actor_id,
	first_name,
	last_name
from
	actor_info),
--THIS CTE caclulates maximum absentse years across all actors
	max_year as (
select 
	an.first_name ,
	an.last_name ,
	(2025-MAX(f.release_year)) as max_years
from
	film f
join film_actor fa
on
	fa.film_id = f.film_id
join actor_name an
on
	an.actor_id = fa.actor_id
group by
	an.first_name ,
	an.last_name)
select
	an.first_name ,
	an.last_name ,
	(2025-MAX(f.release_year)) as years_of_absent
from
	film f
join film_actor fa
on
	fa.film_id = f.film_id
join actor_name an
on
	an.actor_id = fa.actor_id
group by
	an.first_name ,
	an.last_name
-- Subquery to find maximum value
having
	(2025-MAX(f.release_year)) = (
	select
		MAX(max_years)
	from
		max_year)
order by
	years_of_absent desc;

--ANSWE2
select
	actor_id,
	MAX(f.release_year) as last_seen_in_film,
	(DATE_PART('year',
	CURRENT_DATE)- MAX(f.release_year) )as since_last_seen
from
	film_actor fa
join film f
on
	fa.film_id = f.film_id
group by
	actor_id
order by
	since_last_seen desc;

-------------------------------------------------------------------------------------
--V2: gaps between sequential films per each actor;
--ANSWER
with gaps_between_films as (
select
	actor_id,
	(f.release_year - lag(f.release_year) over (partition by actor_id
order by
	f.release_year)) as gap
from
	film f
join film_actor fa on
	f.film_id = fa.film_id )
select
	fa.actor_id,
	a.first_name ,
	a.last_name,
	MAX(gap) as biggest_gap_in_filming
from
	film_actor fa
join film f
on
	fa.film_id = f.film_id
join gaps_between_films bg
on
	bg.actor_id = fa.actor_id
join actor a
on
	fa.actor_id = a.actor_id
group by
	fa.actor_id,
	fa.actor_id,
	a.first_name ,
	a.last_name
having
	MAX(gap) = (
	select
		MAX(gap) as biggest_gap_between_films
	from
		gaps_between_films)
order by
	biggest_gap_in_filming desc
;
