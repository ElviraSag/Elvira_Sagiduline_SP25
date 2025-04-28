
CREATE DATABASE museum_db;

CREATE SCHEMA museum_schema;

-- Exhibition Table
DROP TABLE IF EXISTS museum_schema.exhibition CASCADE;
CREATE TABLE museum_schema.exhibition (
    exhibition_id SERIAL PRIMARY KEY,
    exhibition_name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    description TEXT
);

-- Storage Table
DROP TABLE IF EXISTS museum_schema.storage CASCADE;
CREATE TABLE museum_schema.storage (
    storage_id SERIAL PRIMARY KEY,
    location_name TEXT NOT NULL,
    temperature_control BOOLEAN DEFAULT FALSE,
    capacity INTEGER NOT NULL
);

-- Item Table
DROP TABLE IF EXISTS museum_schema.item CASCADE;
CREATE TABLE museum_schema.item (
    item_id SERIAL PRIMARY KEY,
    item_type VARCHAR(225) DEFAULT 'NEW',
    item_name VARCHAR(225) NOT NULL,
    description TEXT,
    acquisition_date DATE,
    stored_at_id INTEGER,
    CONSTRAINT fk_storage FOREIGN KEY (stored_at_id) REFERENCES museum_schema.storage(storage_id)
);

-- Visitor Table
DROP TABLE IF EXISTS museum_schema.visitor CASCADE;
CREATE TABLE museum_schema.visitor (
    visitor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(225) NOT NULL,
    last_name VARCHAR(225) NOT NULL,
    email VARCHAR(225) UNIQUE
);

-- Ticket Table
DROP TABLE IF EXISTS museum_schema.ticket CASCADE;
CREATE TABLE museum_schema.ticket (
    ticket_id SERIAL PRIMARY KEY,
    visitor_id INTEGER NOT NULL,
    exhibition_id INTEGER NOT NULL,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    price DECIMAL(5,2) NOT NULL,
    discount_type TEXT DEFAULT 'no discount',
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    CONSTRAINT fk_visitor FOREIGN KEY (visitor_id) REFERENCES museum_schema.visitor(visitor_id),
    CONSTRAINT fk_exhibition FOREIGN KEY (exhibition_id) REFERENCES museum_schema.exhibition(exhibition_id)
);

-- Employee Table
DROP TABLE IF EXISTS museum_schema.employee CASCADE;
CREATE TABLE museum_schema.employee (
    employee_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    hire_date DATE NOT NULL,
    position VARCHAR(100),
    salary DECIMAL(10,2) NOT NULL
);

-- Exhibition_Item (Many-to-Many)
DROP TABLE IF EXISTS museum_schema.exhibition_item CASCADE;
CREATE TABLE museum_schema.exhibition_item (
    exhibition_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    PRIMARY KEY (exhibition_id, item_id),
    CONSTRAINT fk_exhibition FOREIGN KEY (exhibition_id) REFERENCES museum_schema.exhibition(exhibition_id),
    CONSTRAINT fk_item FOREIGN KEY (item_id) REFERENCES museum_schema.item(item_id)
);


ALTER TABLE museum_schema.exhibition
ADD CONSTRAINT chk_exhibition_start_date CHECK (start_date > '2024-01-01');

ALTER TABLE museum_schema.exhibition
ADD CONSTRAINT chk_exhibition_end_date CHECK (end_date IS NULL OR end_date > start_date);

ALTER TABLE museum_schema.item
ADD CONSTRAINT chk_item_type CHECK (item_type IN ('NEW','Modern Art', 'Natural history', 'Human history', 'Classic Art'));

ALTER TABLE museum_schema.employee
ADD CONSTRAINT chk_employee_salary CHECK (salary >= 0);

ALTER TABLE museum_schema.ticket
ADD CONSTRAINT chk_ticket_discount CHECK (discount_type IN ('senior', 'student', 'child', 'no discount'));

INSERT INTO museum_schema.storage (location_name, temperature_control, capacity)
VALUES 
('Storage Room A', TRUE, 100),
('Storage Room B', FALSE, 150),
('Storage Room C', TRUE, 200),
('Storage Room D', TRUE, 80),
('Storage Room E', FALSE, 50),
('Storage Room F', TRUE, 120);

INSERT INTO museum_schema.exhibition (exhibition_name, start_date, end_date, description)
VALUES 
('Modern Art', '2024-03-01', '2024-05-30', 'Exhibition on modern art trends'),
('Ace Age  animals', '2024-02-15',  '2024-06-01', 'Artifacts from Ace Age'),
('Historical war artifacts', ' 2024-03-10', '2024-05-15', 'Rare historical objects'),
('Renesance Art','2024-04-01',  '2024-02-20', 'Painting from privat art collection'),
('Sculpture of ancient Greece ', '2024-02-20', '2024-06-10', 'Various sculptures on display'),
('Science Exhibition', '2024-04-05',  '2024-07-15', 'Scientific discoveries and inventions');


INSERT INTO museum_schema.item (item_type, item_name, description, acquisition_date, stored_at_id)
VALUES 
('Modern Art', 'Modern Abstract', 'Contemporary art piece', '2024-02-10', 1),
('Natural history', 'Mammoth skeleton', 'Mammoth skeleton exelant condition', '2024-03-01', 2),
('Human history', 'Viking swords ', 'Hilt of a Frankish sword of ca. the 10th century, with characteristically lobed pommel', '2024-03-15', 1),
('Classic Art', 'The Starry Night', 'Oil on canvas from 1889', '2024-04-01', 3),
('Ancient Art', 'Statue of Applon ', 'The large white marble sculpture is 2.24 m high, AD120-140', '2024-02-25', 4),
('Modern history', 'Model of CERN', 'Model of CERN, part of educational exihibition', '2024-03-20', 2);


INSERT INTO museum_schema.visitor (first_name, last_name, email)
VALUES 
('Alisa',  'Johnson', 'alisa.johnson@example.com'),
('Bob', 'Bobas', ' bob.sbobas@example.com'),
('Viktoria', 'Vikky', 'viktoria.vikky@example.com'),
('Tomas',  'Tomm', 'tomas.tomm@example.com'),
('Olivia', 'Oliv', 'olivia.oliv@example.com'),
('Katerina', 'Katia', ' katerina.katia@example.com');

INSERT INTO museum_schema.ticket (visitor_id, exhibition_id, purchase_date, price, discount_type, valid_from, valid_to)
VALUES 
(1, 1, '2024-04-10', 15.00, 'student', '2024-04-10', '2024-05-30'),
(2, 2, '2024-04-12', 20.00, 'senior', '2024-04-12', '2024-06-01'),
(3, 3, '2024-04-15', 18.00, 'no discount', '2024-04-15', '2024-06-01'),
(4, 1, '2024-04-18', 15.00, 'child', ' 2024-04-18', '2024-05-30'),
(5, 5, '2024-04-20', 15.00, 'student', '2024-04-20', '2024-06-10'),
(6, 6, '2024-04-25', 15.00, 'student', '2024-04-25', '2025-04-25');


INSERT INTO museum_schema.employee (first_name, last_name, hire_date, position, salary)
VALUES 
('Lady', 'Gaga', '2023-01-10', 'Manager', 2500.00),
('Taylor', 'Swift', '2023-06-15', 'Security', 1800.00),
('Britney', 'Spears', '2023-09-20', 'Guide', 2100.00),
('Julia', 'Roberts', '2022-11-25', 'Guide', 2400.00),
('Ariana', 'Grande', '2022-10-30', 'Guide', 2200.00),
('Dua', 'Lipa', '2024-01-15', 'Manager', 3200.00);


INSERT INTO museum_schema.exhibition_item (exhibition_id, item_id, displayed_from, displayed_to)
VALUES 
(1, 1, '2024-03-01', '2024-05-30'),
(2, 2, '2024-02-15', '2024-06-01'),
(2, 3, '2024-02-15', '2024-06-01'),
(3, 4, '2024-04-01', NULL),
(5, 5, '2024-02-20', '2024-06-10'),
(4, 6, '2024-03-10', '2024-05-15');


--5.1 Create a function that updates data in one of your tables.
CREATE OR REPLACE FUNCTION update_item(p_item_id INTEGER, p_column_name VARCHAR, p_new_value TEXT )
RETURNS BOOLEAN AS
$$
DECLARE
    query TEXT;                 
BEGIN
    IF p_column_name IN ('item_type','item_name', 'description', 'acquisition_date', 'stored_at_id')
    THEN query := 'UPDATE Item SET ' || quote_ident(p_column_name) || ' = $1 WHERE item_id = $2';
        EXECUTE query USING p_new_value, p_item_id;
        IF FOUND THEN RETURN TRUE; 
        ELSE RETURN FALSE;
        END IF;
    ELSE
        RAISE EXCEPTION 'Invalid column name: %', p_column_name;
        RETURN FALSE;
    END IF;
END; $$ LANGUAGE plpgsql;

--5. 2 Create a function that adds a new transaction to your transaction table. 
CREATE OR REPLACE FUNCTION museum_schema.add_new_ticket(
    p_visitor_id INTEGER, p_exhibition_id INTEGER,
    p_purchase_date DATE, p_price DECIMAL(5,2),
    p_discount_type TEXT, p_valid_from DATE,
    p_valid_to DATE )
RETURNS VOID AS $$
BEGIN
    INSERT INTO museum_schema.ticket (
        visitor_id, exhibition_id,
        purchase_date, price,
        discount_type, valid_from,
        valid_to)
    VALUES (p_visitor_id, p_exhibition_id,
        p_purchase_date, p_price,
        p_discount_type, p_valid_from,
        p_valid_to);
    RAISE NOTICE 'Ticket transaction added successfully.';
END; $$ LANGUAGE plpgsql;



--6. Create a view that presents analytics for the most recently added quarter in your database. 
--View shows total tiket sold, total revenue and most visited exihibition.

CREATE OR REPLACE VIEW quarter_ticket_analytics AS
WITH ticket_sold AS (
    SELECT *
    FROM ticket
    WHERE purchase_date >= date_trunc('quarter', CURRENT_DATE) - INTERVAL '3 months'
    AND purchase_date < date_trunc('quarter', CURRENT_DATE)
),
most_visited_exhb AS (
    SELECT
        t.exhibition_id,
        e.exhibition_name, 
        COUNT(*) as visit_count,
        RANK() OVER (ORDER BY COUNT(*) DESC) as rank
    FROM ticket_sold t
    JOIN exhibition e ON t.exhibition_id = e.exhibition_id 
    GROUP BY t.exhibition_id, e.exhibition_name 
)
SELECT
    (SELECT COUNT(*) FROM ticket_sold) AS ticket_count,
    (SELECT COALESCE(SUM(price), 0) FROM ticket_sold) AS total_revenue,
    (SELECT exhibition_name FROM most_visited_exhb WHERE rank = 1 LIMIT 1) AS most_visited_exhibition;


--7. Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database tables, and also be able to log in.

CREATE ROLE manager_readonly WITH LOGIN PASSWORD 'StrongPassword123';  
GRANT CONNECT ON DATABASE museum_db TO manager_readonly;
GRANT USAGE ON SCHEMA museum_schema TO manager_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA museum_schema TO manager_readonly;