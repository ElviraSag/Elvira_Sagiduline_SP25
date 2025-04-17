-- Create database 
CREATE DATABASE metro;

-- Create schema
CREATE SCHEMA IF NOT EXISTS metro;

--Creat tables
-- TicketDiscounts
CREATE TABLE IF NOT EXISTS metro.TicketDiscounts (
    DiscountID INT PRIMARY KEY,
    DiscountType VARCHAR(50) CHECK (DiscountType IN ('NONE', 'senior', 'child', 'student')),
    DiscountPercentage INT CHECK (DiscountPercentage IN (0, 10, 20, 50))
);

-- Payroll
CREATE TABLE IF NOT EXISTS metro.Payroll (
    PayrollID INT PRIMARY KEY,
    SalaryEUR DECIMAL(10, 2) NOT NULL,
    PayDay DATE CHECK (PayDay > '2000-01-01') NOT NULL
);

-- Stations
CREATE TABLE IF NOT EXISTS metro.Stations (
    StationID INT PRIMARY KEY,
    StationName VARCHAR(225) UNIQUE NOT NULL,
    Location VARCHAR(225) NOT NULL,
    Status VARCHAR(50) CHECK (Status IN ('open', 'under maintenance'))
);

-- Employees
CREATE TABLE IF NOT EXISTS metro.Employees (
    EmployeeID INT PRIMARY KEY,
    Employee_name VARCHAR(255) NOT NULL,
    Employee_Role VARCHAR(100) NOT NULL,
    HiredDate DATE CHECK (HiredDate > '2000-01-01') NOT NULL,
    PayrollID INT,
    FOREIGN KEY (PayrollID) REFERENCES metro.Payroll(PayrollID)
);

-- Trains
CREATE TABLE IF NOT EXISTS metro.Trains (
    TrainID INT PRIMARY KEY,
    LineID INT,
    Status VARCHAR(50) CHECK (Status IN ('active', 'under maintenance'))
);

-- Lines
CREATE TABLE IF NOT EXISTS metro.Lines (
    LineID INT PRIMARY KEY,
    LineName VARCHAR(50) UNIQUE NOT NULL,
    StartStationID INT NOT NULL,
    EndSationID INT NOT NULL,
    OperatingFrequency DECIMAL(4, 2) NOT NULL,
    AssignedTrainID INT CHECK (AssignedTrainID >= 0),
    FOREIGN KEY (StartStationID) REFERENCES metro.Stations(StationID),
    FOREIGN KEY (EndSationID) REFERENCES metro.Stations(StationID),
    FOREIGN KEY (AssignedTrainID) REFERENCES metro.Trains(TrainID)
);

-- Add foreign key to Trains after Lines table exists
ALTER TABLE metro.Trains ADD CONSTRAINT fk_line FOREIGN KEY (LineID) REFERENCES metro.Lines(LineID);

-- Tickets
CREATE TABLE IF NOT EXISTS metro.Tickets (
    TicketID INT PRIMARY KEY,
    TicketType VARCHAR(50) CHECK (TicketType IN ('30min', '60min', '1day', '30days', '1year')),
    Price DECIMAL(10, 2) CHECK (Price >= 0),
    DiscountID INT,
    ValidFrom TIMESTAMP CHECK (ValidFrom > '2000-01-01'),
    ValidUntil TIMESTAMP CHECK (ValidUntil > '2000-01-01'),
    FOREIGN KEY (DiscountID) REFERENCES metro.TicketDiscounts(DiscountID)
);

-- LineStations
CREATE TABLE IF NOT EXISTS metro.LineStations (
    LineStationsID INT PRIMARY KEY,
    LineID INT,
    StationID INT,
    FOREIGN KEY (LineID) REFERENCES metro.Lines(LineID),
    FOREIGN KEY (StationID) REFERENCES metro.Stations(StationID)
);

-- StationSchedules
CREATE TABLE IF NOT EXISTS metro.StationSchedules (
    ScheduleID INT PRIMARY KEY,
    StationID INT,
    TrainID INT,
    ArrivalTime TIMESTAMP CHECK (ArrivalTime > '2000-01-01'),
    DepartureTime TIMESTAMP CHECK (DepartureTime > '2000-01-01'),
    IsLastStop BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (StationID) REFERENCES metro.Stations(StationID),
    FOREIGN KEY (TrainID) REFERENCES metro.Trains(TrainID)
);

-- UpkeepRepairsMonitoring
CREATE TABLE IF NOT EXISTS metro.UpkeepRepairsMonitoring (
    RepairID INT PRIMARY KEY,
    RepairType VARCHAR(50) CHECK (RepairType IN ('Tunnel', 'Track', 'Train', 'Station', 'Ticket Reader')) NOT NULL,
    Description TEXT,
    StationID INT,
    TrainID INT,
    RepairDate DATE CHECK (RepairDate > '2000-01-01'),
    RepairStatus VARCHAR(50) CHECK (RepairStatus IN ('Pending', 'In Progress', 'Completed')) NOT NULL,
    FOREIGN KEY (StationID) REFERENCES metro.Stations(StationID),
    FOREIGN KEY (TrainID) REFERENCES metro.Trains(TrainID)
);

-- ScheduleMonitoring
CREATE TABLE IF NOT EXISTS metro.ScheduleMonitoring (
    MonitoringID INT PRIMARY KEY,
    StationID INT,
    TrainID INT,
    ArrivalTime TIMESTAMP CHECK (ArrivalTime > '2000-01-01'),
    OnTime BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (StationID) REFERENCES metro.Stations(StationID),
    FOREIGN KEY (TrainID) REFERENCES metro.Trains(TrainID)
);

-- TrainAssignments
CREATE TABLE IF NOT EXISTS metro.TrainAssignments (
    TrainAssignmentsID INT PRIMARY KEY,
    TrainID INT,
    EmployeeID INT,
    StartDate DATE CHECK (StartDate > '2000-01-01'),
    EndDate DATE CHECK (EndDate > '2000-01-01'),
    FOREIGN KEY (TrainID) REFERENCES metro.Trains(TrainID),
    FOREIGN KEY (EmployeeID) REFERENCES metro.Employees(EmployeeID)
);

-- TrainMaintenance
CREATE TABLE IF NOT EXISTS metro.TrainMaintenance (
    MaintenanceID INT PRIMARY KEY,
    TrainID INT,
    MaintenanceType TEXT,
    StartDate DATE CHECK (StartDate > '2000-01-01'),
    EndDate DATE CHECK (EndDate > '2000-01-01'),
    Status VARCHAR(50) CHECK (Status IN ('in progress', 'completed')),
    NextSchedulledDate DATE CHECK (NextSchedulledDate > '2000-01-01'),
    FOREIGN KEY (TrainID) REFERENCES metro.Trains(TrainID)
);

-- StationService
CREATE TABLE IF NOT EXISTS metro.StationService (
    StationServiceID INT PRIMARY KEY,
    StationID INT,
    EmployeeID INT,
    StartDate DATE  CHECK (StartDate > '2000-01-01'),
    EndDate DATE CHECK (EndDate > '2000-01-01'),
    Role VARCHAR(50) CHECK (Role IN ('Maintenance', 'Station Manager', 'Cleaner', 'Conductor')),
    FOREIGN KEY (StationID) REFERENCES metro.Stations(StationID),
    FOREIGN KEY (EmployeeID) REFERENCES metro.Employees(EmployeeID)
);

-- ALTER column to include GENERATE ALWAYS 
ALTER TABLE metro.Employees ADD COLUMN employee_surename VARCHAR(255) NOT NULL;

ALTER TABLE metro.Employees ADD COLUMN employee_full_name TEXT 
    GENERATED ALWAYS AS (Employee_name || ' ' || employee_surename) STORED;

--Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.
ALTER TABLE metro.Employees ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.Lines ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.LineStations ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.Payroll ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.ScheduleMonitoring ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.Stations ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.StationSchedules ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.StationService ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.TicketDiscounts ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.Tickets ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.TrainAssignments ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.TrainMaintenance ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.Trains ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE metro.UpkeepRepairsMonitoring ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();

-- ALTER PK in each table with DEFAULT nextval('name_seq'::regclass)
CREATE SEQUENCE IF NOT EXISTS employeeid_seq;
ALTER TABLE metro.Employees ALTER COLUMN EmployeeID SET DEFAULT nextval('employeeid_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS LineID_seq;
ALTER TABLE metro.Lines ALTER COLUMN LineID SET DEFAULT nextval('LineID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS LineStationsID_seq;
ALTER TABLE metro.LineStations ALTER COLUMN LineStationsID SET DEFAULT nextval('LineStationsID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS PayrollID_seq;
ALTER TABLE metro.Payroll ALTER COLUMN PayrollID SET DEFAULT nextval('PayrollID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS MonitoringID_seq;
ALTER TABLE metro.ScheduleMonitoring ALTER COLUMN MonitoringID SET DEFAULT nextval('MonitoringID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS StationID_seq;
ALTER TABLE metro.Stations ALTER COLUMN StationID SET DEFAULT nextval('StationID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS ScheduleID_seq;
ALTER TABLE metro.StationSchedules ALTER COLUMN ScheduleID SET DEFAULT nextval('ScheduleID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS StationServiceID_seq;
ALTER TABLE metro.StationService ALTER COLUMN StationServiceID SET DEFAULT nextval('StationServiceID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS DiscountID_seq;
ALTER TABLE metro.TicketDiscounts ALTER COLUMN DiscountID SET DEFAULT nextval('DiscountID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS TicketID_seq;
ALTER TABLE metro.Tickets ALTER COLUMN TicketID SET DEFAULT nextval('TicketID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS TrainAssignmentsID_seq;
ALTER TABLE metro.TrainAssignments ALTER COLUMN TrainAssignmentsID SET DEFAULT nextval('TrainAssignmentsID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS MaintenanceID_seq;
ALTER TABLE metro.TrainMaintenance ALTER COLUMN MaintenanceID SET DEFAULT nextval('MaintenanceID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS TrainID_seq;
ALTER TABLE metro.Trains ALTER COLUMN TrainID SET DEFAULT nextval('TrainID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS RepairID_seq;
ALTER TABLE metro.UpkeepRepairsMonitoring ALTER COLUMN RepairID SET DEFAULT nextval('RepairID_seq'::regclass);

--Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
-- Stations
INSERT INTO metro.Stations (StationName, Location, Status)
VALUES
('Central Station', 'Central', 'open'),
('St. Bernard Station', 'North District', 'under maintenance');


-- Trains
INSERT INTO metro.Trains (Status)
VALUES
('active'),
('under maintenance');

-- Payroll
INSERT INTO metro.Payroll (SalaryEUR, PayDay)
VALUES
(2500.00, '2024-12-01'),
(3000.00, '2024-12-01');


-- Employees
INSERT INTO metro.Employees (Employee_name, Employee_surename, Employee_role, HiredDate, PayrollID)
VALUES
('John', 'Smith', 'Station Manager', '2022-01-10',1),
('Bob','Lee', 'Conductor', '2023-05-20',2);

-- TicketDiscount
INSERT INTO metro.TicketDiscounts (DiscountType, DiscountPercentage)
VALUES
('student', 20),
('NONE', 0);

-- Tickets
INSERT INTO metro.Tickets (TicketType, Price, DiscountID, ValidFrom, ValidUntil)
VALUES
('1day', 3.50, 1, '2025-04-01 08:00', '2025-04-02 08:00'),
('30min', 1.00, 2, '2025-04-01 09:00', '2025-04-01 09:30');

-- Lines (after stations exist)
INSERT INTO metro.Lines (LineName, StartStationID, EndSationID, OperatingFrequency)
VALUES
('Green', 1, 2, 5.5),
('Blue', 3, 1, 6.0);

--LineStations
INSERT INTO metro.LineStations (LineID, StationID)
VALUES
(6, 2),
(7, 3);

-- StationSchedules
INSERT INTO metro.StationSchedules (ArrivalTime,StationID, trainid, DepartureTime, IsLastStop)
VALUES
('2025-04-01 08:00',2,2, '2025-04-01 08:05', false),
('2025-04-01 09:00',3,3, '2025-04-01 09:10', true);

-- TrainAssignments
INSERT INTO metro.TrainAssignments (TrainID, EmployeeID, StartDate, EndDate)
VALUES
(2,3,'2025-03-01', '2025-04-01'),
(3,2,'2025-03-10', '2025-04-10');

-- TrainMaintenance
INSERT INTO metro.TrainMaintenance (MaintenanceType, TrainID, StartDate, EndDate, Status, NextSchedulledDate)
VALUES
('Routine Check', 2,'2025-03-15', '2025-03-16', 'completed', '2025-06-15'),
('Brake Fix', 3,'2025-03-25', NULL, 'in progress', '2025-06-25');

-- UpkeepRepairsMonitoring
INSERT INTO metro.UpkeepRepairsMonitoring (RepairType, Description, StationID, TrainID, RepairDate, RepairStatus)
VALUES
('Station', 'Fixed ticket reader', 3, 2, '2025-03-20', 'Completed'),
('Train', 'Wheel alignment', 2, 3,'2025-03-21', 'In Progress');

-- ScheduleMonitoring
INSERT INTO metro.ScheduleMonitoring (StationID, TrainID,ArrivalTime, OnTime)
VALUES
(2,2,'2025-04-01 08:00', true),
(3,3,'2025-04-01 09:05', false);


-- StationService
INSERT INTO metro.StationService (StationID, employeeid, StartDate, EndDate, Role)
VALUES
(1,2,'2025-03-01', '2025-04-01', 'Station Manager'),
(2,3,'2025-03-01', '2025-04-01', 'Cleaner');

----Altering tables LineStations, TrainAssignments, StationService  to have composite primery key

ALTER TABLE metro.LineStations DROP COLUMN IF EXISTS LineStationsID;
ALTER TABLE metro.TrainAssignments DROP COLUMN IF EXISTS TrainAssignmentsID;
ALTER TABLE metro.StationService DROP COLUMN IF EXISTS StationServiceID;

ALTER TABLE metro.LineStations ADD PRIMARY KEY (LineID, StationID);
ALTER TABLE metro.TrainAssignments ADD PRIMARY KEY (TrainID, EmployeeID);
ALTER TABLE metro.StationService ADD PRIMARY KEY (StationID, EmployeeID);


