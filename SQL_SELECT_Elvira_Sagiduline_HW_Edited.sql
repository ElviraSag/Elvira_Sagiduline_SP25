---All animation movies released between 2017 and 2019 with rate more than 1, alphabetical

--ANSWER1
select
	f.title,
	f.rental_rate,
	f.release_year
from
	public.film f
inner join public.film_category fc on	f.film_id = fc.film_id
inner join public.category c on	fc.category_id = c.category_id
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
inner join public.film_category fc on 	f.film_id = fc.film_id
inner join public.category c on	fc.category_id = c.category_id
where
	c.name = 'Animation'
)
select
	af.title,
	af.rental_rate,
	af.release_year
from
	public.animation_films af
where
	af.release_year between 2017 and 2019
	and af.rental_rate > 1
order by
	af.title;
-----------------------------------------------------------------------------------------------------------------
--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
--ANSWER
select s.store_id , SUM(p.amount) as revenue, CONCAT(a.address,	' ' ,	a.address2) as address
from public.payment p 
inner join public.rental r on p.rental_id=r.rental_id
inner join public.inventory i on r.inventory_id = i.inventory_id 
inner join public. store s on s.store_id = i.store_id
inner join public.address a on a.address_id =s.address_id
where
	DATE_PART('month',	payment_date) > 3
	and DATE_PART('year',	payment_date) >= 2017
group by  s.store_id , CONCAT(a.address,	' ' ,	a.address2)

--------------------------------------------------------------------------------------------------------
--Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
--ANSWER
select
	a.first_name,
	a.last_name ,
	COUNT(fa.film_id) as number_of_movies
from
	public.film_actor fa
inner join public.actor a on	fa.actor_id = a.actor_id
inner join public.film f on	f.film_id = fa.film_id
where
	release_year >= 2015
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
	COUNT(*) filter (where	c.name = 'Drama') as number_of_drama_movies,
	COUNT(*) filter (where	c.name = 'Travel') as number_of_travel_movies,
	COUNT(*) filter (where	c.name = 'Documentary') as number_of_documentary_movies
from
	public.film f
inner join film_category fc on	f.film_id = fc.film_id
inner join public.category c on	c.category_id = fc.category_id
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
	public.staff
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
	public.store s
inner join public.address a on	s.address_id = a.address_id
inner join public.city c on	a.city_id = c.city_id
inner join public.country c2 on	c.country_id = c2.country_id )
select
	p.staff_id,
	sn.first_name ,
	sn.last_name ,
	SUM(p.amount) as revenue,
	CONCAT(stn.city,	stn.country) as store_name
from
	public.payment p
inner join staff_name sn on	sn.staff_id = p.staff_id
inner join store_name stn on	stn.store_id = sn.wortket_at_store
where
	DATE_PART('year',	p.payment_date) = 2017
group by
	p.staff_id,
	DATE_PART('year',	payment_date),
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
	case
		when f.rating = 'G' then 'All Ages'
		when f.rating = 'PG-13' then 'Inappropriate for Children Under 13'
		when f.rating = 'R' then 'Children Under 17 Require Accompanying Adult'
		when f.rating = 'NC-17' then 'Inappropriate for Children Under 17'
		when f.rating = 'PG' then 'Parental Guidance Suggested'
		else 'Check with a Motion Picture Association film rating system'
	end as Motion_picture_rating,
	COUNT(r.rental_id) as how_many_times_rented
from
	public.inventory i
inner join public.rental r on
	i.inventory_id = r.inventory_id
inner join public.film f on
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
	public.actor_info),
--THIS CTE caclulates maximum absentse years across all actors
	max_year as (
select 
	an.first_name ,
	an.last_name ,
	(2025-MAX(f.release_year)) as max_years
from
	public.film f
inner join public.film_actor fa on	fa.film_id = f.film_id
inner join actor_name an on	an.actor_id = fa.actor_id
group by
	an.first_name ,
	an.last_name)
select
	an.first_name ,
	an.last_name ,
	(2025-MAX(f.release_year)) as years_of_absent
from
	public.film f
inner join public.film_actor fa on	fa.film_id = f.film_id
inner join actor_name an on	an.actor_id = fa.actor_id
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
	(DATE_PART('year',	CURRENT_DATE)- MAX(f.release_year) )as since_last_seen
from
	public.film_actor fa
inner join public.film f on	fa.film_id = f.film_id
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
	public.film f
inner join public.film_actor fa on 	f.film_id = fa.film_id )
select
	fa.actor_id,
	a.first_name ,
	a.last_name,
	MAX(gap) as biggest_gap_in_filming
from
	public.film_actor fa
inner join public.film f on	fa.film_id = f.film_id
inner join gaps_between_films bg on	bg.actor_id = fa.actor_id
inner join public.actor a on	fa.actor_id = a.actor_id
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

------------------------------------------------------------------------