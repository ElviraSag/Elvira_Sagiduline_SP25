-- Create database 
CREATE DATABASE metro;

-- TicketDiscounts
CREATE TABLE IF NOT EXISTS TicketDiscounts (
    DiscountID INT PRIMARY KEY,
    DiscountType VARCHAR(50) CHECK (DiscountType IN ('NONE', 'senior', 'child', 'student')),
    DiscountPercentage INT CHECK (DiscountPercentage IN (0, 10, 20, 50))
);

-- Payroll
CREATE TABLE IF NOT EXISTS Payroll (
    PayrollID INT PRIMARY KEY,
    SalaryEUR DECIMAL(10, 2) NOT NULL,
    PayDay DATE CHECK (PayDay > '2000-01-01') NOT NULL
);

-- Stations
CREATE TABLE IF NOT EXISTS Stations (
    StationID INT PRIMARY KEY,
    StationName VARCHAR(225) UNIQUE NOT NULL,
    Location VARCHAR(225) NOT NULL,
    Status VARCHAR(50) CHECK (Status IN ('open', 'under maintenance'))
);

-- Employees
CREATE TABLE IF NOT EXISTS Employees (
    EmployeeID INT PRIMARY KEY,
    Employee_name VARCHAR(255) NOT NULL,
    Employee_Role VARCHAR(100) NOT NULL,
    HiredDate DATE CHECK (HiredDate > '2000-01-01') NOT NULL,
    PayrollID INT,
    FOREIGN KEY (PayrollID) REFERENCES Payroll(PayrollID)
);

--Trains
CREATE TABLE IF NOT EXISTS Trains (
    TrainID INT PRIMARY KEY,
    LineID INT,
    Status VARCHAR(50) CHECK (Status IN ('active', 'under maintenance'))
);

-- Lines
CREATE TABLE IF NOT EXISTS Lines (
    LineID INT PRIMARY KEY,
    LineName VARCHAR(50) UNIQUE NOT NULL,
    StartStationID INT NOT NULL,
    EndSationID INT NOT NULL,
    OperatingFrequency DECIMAL(4, 2) NOT NULL,
    AssignedTrainID INT CHECK (AssignedTrainID >= 0),
    FOREIGN KEY (StartStationID) REFERENCES Stations(StationID),
    FOREIGN KEY (EndSationID) REFERENCES Stations(StationID),
    FOREIGN KEY (AssignedTrainID) REFERENCES Trains(TrainID)
);

-- Add foreign key to Trains after Lines table exists
ALTER TABLE Trains ADD CONSTRAINT fk_line FOREIGN KEY (LineID) REFERENCES Lines(LineID);

-- Tickets
CREATE TABLE IF NOT EXISTS Tickets (
    TicketID INT PRIMARY KEY,
    TicketType VARCHAR(50) CHECK (TicketType IN ('30min', '60min', '1day', '30days', '1year')),
    Price DECIMAL(10, 2) CHECK (Price >= 0),
    DiscountID INT,
    ValidFrom TIMESTAMP CHECK (ValidFrom > '2000-01-01'),
    ValidUntil TIMESTAMP CHECK (ValidUntil > '2000-01-01'),
    FOREIGN KEY (DiscountID) REFERENCES TicketDiscounts(DiscountID)
);

-- LineStations
CREATE TABLE IF NOT EXISTS LineStations (
    LineStationsID INT PRIMARY KEY,
    LineID INT,
    StationID INT,
    FOREIGN KEY (LineID) REFERENCES Lines(LineID),
    FOREIGN KEY (StationID) REFERENCES Stations(StationID)
);

-- StationSchedules
CREATE TABLE IF NOT EXISTS StationSchedules (
    ScheduleID INT PRIMARY KEY,
    StationID INT,
    TrainID INT,
    ArrivalTime TIMESTAMP CHECK (ArrivalTime > '2000-01-01'),
    DepartureTime TIMESTAMP CHECK (DepartureTime > '2000-01-01'),
    IsLastStop BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (StationID) REFERENCES Stations(StationID),
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID)
);

-- UpkeepRepairsMonitoring
CREATE TABLE IF NOT EXISTS UpkeepRepairsMonitoring (
    RepairID INT PRIMARY KEY,
    RepairType VARCHAR(50) CHECK (RepairType IN ('Tunnel', 'Track', 'Train', 'Station', 'Ticket Reader')) NOT NULL,
    Description TEXT,
    StationID INT,
    TrainID INT,
    RepairDate DATE CHECK (RepairDate > '2000-01-01'),
    RepairStatus VARCHAR(50) CHECK (RepairStatus IN ('Pending', 'In Progress', 'Completed')) NOT NULL,
    FOREIGN KEY (StationID) REFERENCES Stations(StationID),
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID)
);

-- ScheduleMonitoring
CREATE TABLE IF NOT EXISTS ScheduleMonitoring (
    MonitoringID INT PRIMARY KEY,
    StationID INT,
    TrainID INT,
    ArrivalTime TIMESTAMP CHECK (ArrivalTime > '2000-01-01'),
    OnTime BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (StationID) REFERENCES Stations(StationID),
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID)
);

-- TrainAssignments
CREATE TABLE IF NOT EXISTS TrainAssignments (
    TrainAssignmentsID INT PRIMARY KEY,
    TrainID INT,
    EmployeeID INT,
    StartDate DATE CHECK (StartDate > '2000-01-01'),
    EndDate DATE CHECK (EndDate > '2000-01-01'),
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

-- TrainMaintenance
CREATE TABLE IF NOT EXISTS TrainMaintenance (
    MaintenanceID INT PRIMARY KEY,
    TrainID INT,
    MaintenanceType TEXT,
    StartDate DATE CHECK (StartDate > '2000-01-01'),
    EndDate DATE CHECK (EndDate > '2000-01-01'),
    Status VARCHAR(50) CHECK (Status IN ('in progress', 'completed')),
    NextSchedulledDate DATE CHECK (NextSchedulledDate > '2000-01-01'),
    FOREIGN KEY (TrainID) REFERENCES Trains(TrainID)
);

-- StationService
CREATE TABLE IF NOT EXISTS StationService (
    StationServiceID INT PRIMARY KEY,
    StationID INT,
    EmployeeID INT,
    StartDate DATE  CHECK (StartDate > '2000-01-01'),
    EndDate DATE CHECK (EndDate > '2000-01-01'),
    Role VARCHAR(50) CHECK (Role IN ('Maintenance', 'Station Manager', 'Cleaner', 'Conductor')),
    FOREIGN KEY (StationID) REFERENCES Stations(StationID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);


-- ALTER column to include GENERATE ALWAYS 

ALTER TABLE employees ADD COLUMN employee_surename VARCHAR(255) NOT NULL;

ALTER TABLE employees ADD COLUMN employee_full_name TEXT GENERATED ALWAYS AS (employee_name || ' ' || employee_surename) STORED;

--Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.

ALTER TABLE employees ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE lines ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE linestations  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE payroll  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE schedulemonitoring  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE stations  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE stationschedules  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE stationservice  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE ticketdiscounts  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE tickets  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE trainassignments  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE trainmaintenance  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE trains ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();
ALTER TABLE upkeeprepairsmonitoring  ADD COLUMN record_ts DATE NOT NULL DEFAULT NOW();


-- ALTER PK in each table with DEFAULT nextval('name_seq'::regclass)

CREATE SEQUENCE IF NOT EXISTS employeeid_seq;
ALTER TABLE employees ALTER COLUMN EmployeeID SET DEFAULT nextval('employeeid_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS LineID_seq;
ALTER TABLE lines ALTER COLUMN LineID SET DEFAULT nextval('LineID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS LineStationsID_seq;
ALTER TABLE linestations  ALTER COLUMN LineStationsID SET DEFAULT nextval('LineStationsID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS PayrollID_seq;
ALTER TABLE payroll  ALTER COLUMN PayrollID SET DEFAULT nextval('PayrollID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS MonitoringID_seq;
ALTER TABLE schedulemonitoring  ALTER COLUMN MonitoringID SET DEFAULT nextval('MonitoringID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS StationID_seq;
ALTER TABLE stations ALTER COLUMN StationID SET DEFAULT nextval('StationID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS ScheduleID_seq;
ALTER TABLE stationschedules ALTER COLUMN ScheduleID SET DEFAULT nextval('ScheduleID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS StationServiceID_seq;
ALTER TABLE stationservice  ALTER COLUMN StationServiceID SET DEFAULT nextval('StationServiceID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS DiscountID_seq;
ALTER TABLE ticketdiscounts  ALTER COLUMN DiscountID SET DEFAULT nextval('DiscountID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS TicketID_seq;
ALTER TABLE tickets  ALTER COLUMN TicketID SET DEFAULT nextval('TicketID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS TrainAssignmentsID_seq;
ALTER TABLE trainassignments  ALTER COLUMN TrainAssignmentsID SET DEFAULT nextval('TrainAssignmentsID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS MaintenanceID_seq;
ALTER TABLE trainmaintenance ALTER COLUMN MaintenanceID SET DEFAULT nextval('MaintenanceID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS TrainID_seq;
ALTER TABLE trains ALTER COLUMN TrainID SET DEFAULT nextval('TrainID_seq'::regclass);

CREATE SEQUENCE IF NOT EXISTS RepairID_seq;
ALTER TABLE upkeeprepairsmonitoring  ALTER COLUMN RepairID SET DEFAULT nextval('RepairID_seq'::regclass);



--Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).

--  Stations
INSERT INTO Stations (StationName, Location, Status)
VALUES
('Central Station', 'Central', 'open'),
('St. Bernard Station', 'North District', 'under maintenance');

INSERT INTO Stations (StationID, StationName, Location, Status)
VALUES
(1, 'University of Art', 'Eastern', 'open');

-- Trains
INSERT INTO Trains (Status)
VALUES
('active'),
('under maintenance');

-- Payroll
INSERT INTO Payroll (SalaryEUR, PayDay)
VALUES
(2500.00, '2024-12-01'),
(3000.00, '2024-12-01');

-- Employees
INSERT INTO Employees (Employee_name, Employee_surename, Employee_role, HiredDate)
VALUES
('John', 'Smith', 'Station Manager', '2022-01-10'),
('Bob','Lee', 'Conductor', '2023-05-20');

-- TicketDiscount
INSERT INTO TicketDiscounts (DiscountType, DiscountPercentage)
VALUES
('student', 20),
('NONE', 0);

-- Tickets
INSERT INTO Tickets (TicketType, Price, ValidFrom, ValidUntil)
VALUES
('1day', 3.50, '2025-04-01 08:00', '2025-04-02 08:00'),
('30min', 1.00, '2025-04-01 09:00', '2025-04-01 09:30');

-- Lines (after stations exist)
INSERT INTO Lines (LineName, StartStationID, EndSationID, OperatingFrequency)
VALUES
('Green', 1, 2, 5.5),
('Blue', 3, 1, 6.0);


-- StationSchedules
INSERT INTO StationSchedules (ArrivalTime, DepartureTime, IsLastStop)
VALUES
('2025-04-01 08:00', '2025-04-01 08:05', false),
('2025-04-01 09:00', '2025-04-01 09:10', true);

-- TrainAssignments
INSERT INTO TrainAssignments (StartDate, EndDate)
VALUES
('2025-03-01', '2025-04-01'),
('2025-03-10', '2025-04-10');

--TrainMaintenance
INSERT INTO TrainMaintenance (MaintenanceType, StartDate, EndDate, Status, NextSchedulledDate)
VALUES
('Routine Check', '2025-03-15', '2025-03-16', 'completed', '2025-06-15'),
('Brake Fix', '2025-03-25', NULL, 'in progress', '2025-06-25');

--UpkeepRepairsMonitoring
INSERT INTO UpkeepRepairsMonitoring (RepairType, Description, StationID, TrainID, RepairDate, RepairStatus)
VALUES
('Station', 'Fixed ticket reader', 1, NULL, '2025-03-20', 'Completed'),
('Train', 'Wheel alignment', NULL, 2, '2025-03-21', 'In Progress');

--ScheduleMonitoring
INSERT INTO ScheduleMonitoring (ArrivalTime, OnTime)
VALUES
( '2025-04-01 08:00', true),
('2025-04-01 09:05', false);

--StationService
INSERT INTO StationService (StartDate, EndDate, Role)
VALUES
('2025-03-01', '2025-04-01', 'Station Manager'),
('2025-03-01', '2025-04-01', 'Cleaner');


