--Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rentaluser') THEN
        CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
    END IF;
END $$;

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;


--Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
GRANT SELECT ON public.customer TO rentaluser;
--testing SELECT * FROM public.customer;

---Create a new user group called "rental" and add "rentaluser" to the group. 
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rental') THEN
        CREATE USER rental;
    END IF;
END $$;

GRANT rental TO rentaluser;

--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
GRANT INSERT, UPDATE ON public.rental TO rental;

-- Insert (replace values appropriately based on existing foreign keys)
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (CURRENT_TIMESTAMP, 1, 1, 1);

-- Update (replace ID with a valid one)
UPDATE public.rental
SET return_date = CURRENT_TIMESTAMP
WHERE rental_id = 1;


--Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
REVOKE INSERT ON public.rental FROM rental;
-- This should now fail with permission denied
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (CURRENT_TIMESTAMP, 1, 1, 1);

--Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty
DO $$
DECLARE
    cust RECORD;
	role_name TEXT;
BEGIN
    FOR cust IN
        SELECT c.customer_id, c.first_name, c.last_name
        FROM customer c
        JOIN payment p ON c.customer_id = p.customer_id
        JOIN rental r ON c.customer_id = r.customer_id
    LOOP
		role_name := format('client_%I_%I', cust.first_name, cust.last_name);

		IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
           EXECUTE format('CREATE ROLE %I;',role_name);
		end if;
    END LOOP;
END $$;

        
 