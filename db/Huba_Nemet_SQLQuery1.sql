CREATE DATABASE TimesheetDB;
GO
 
USE TimesheetDB;
GO

-- Crearea tabelei Employees
create table employees (
	employee_id int primary key,
	employee_name nvarchar(100) not null,
	email nvarchar(100) unique,
);
	-- modificarea tabelei cu adaugarea unui nou camp
	ALTER TABLE employees
	ADD hire_date DATE CHECK (hire_date > '2000-01-01');


-- Crearea tabelei Projects
CREATE TABLE Projects (
    project_id INT PRIMARY KEY,
    project_name NVARCHAR(100) NOT NULL,
    start_date DATE NOT NULL DEFAULT GETDATE(),  -- Constraint DEFAULT direct în CREATE TABLE
    end_date DATE
);


-- Crearea tabelei Departments
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name NVARCHAR(100) NOT NULL
);


-- Crearea tabelei Timesheets
CREATE TABLE Timesheets (
    timesheet_id INT PRIMARY KEY,
    employee_id INT,
    project_id INT,
    department_id INT,
    work_date DATE NOT NULL,
    hours_worked FLOAT CHECK (hours_worked BETWEEN 0 AND 24),
    notes_json NVARCHAR(MAX), -- date semi-structurate
	FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON delete cascade on update cascade,
);

-- Popularea tabelei Employees
INSERT INTO Employees (employee_id, employee_name, email, hire_date) VALUES
(1, 'Alice Johnson', 'alice.johnson@endava.com', '2021-03-15'),
(2, 'Bob Smith', 'bob.smith@endava.com', '2020-07-01'),
(3, 'Carol White', 'carol.white@endava.com', '2022-05-20'),
(4, 'David Brown', 'david.brown@endava.com', '2023-11-11'),
(5, 'Eve Black', 'eve.black@endava.com', '2023-01-25'),
(6, 'Frank Adams', 'frank.adams@endava.com', '2023-06-01');

-- Popularea tabelei Projects
INSERT INTO Projects VALUES
(1, 'Apollo', '2023-01-01', '2023-06-30'),
(2, 'Orion', '2023-02-15', '2023-12-01'),
(3, 'Zephyr', '2023-03-10', '2023-07-20');

-- Popularea tabelei Departments
INSERT INTO Departments VALUES
(1, 'Human Resources'),
(2, 'Engineering');

-- Popularea tabelei Timesheets
INSERT INTO Timesheets VALUES 
-- Andrei Popescu
(1, 1, 1001, 1, '2024-06-03', 8.0, N'{"task": "feature A", "notes": "finalizat"}'),
-- Andrada Matei
(2, 2, 1001, 1, '2024-06-04', 6.5, N'{"task": "debugging", "severity": "high"}'),
-- Maria Ionescu
(3, 3, 1002, 2, '2024-06-03', 7.0, N'{"task": "recruitment dashboard"}'),
-- Mihai Pascu
(4, 4, 1002, 2, '2024-06-04', 8.0, N'{"task": "email system"}'),
-- George Enescu, Proiect 3
(5, 5, 1003, 3, '2024-06-03', 4.0, N'{"task": "budget check"}'),
-- Stelian Voicu
(6, 6, 1003, 3, '2024-06-04', 5.5, N'{"task": "reporting", "notes": "in progres"}');


-- Index non FK/PK pe coloana idx_hours
CREATE INDEX idx_hours ON Timesheets(hours_worked);


-- view with left join
CREATE VIEW Timesheet_Audit AS
SELECT 
    e.employee_name,
    p.project_name,
    d.department_name,
    t.work_date,
    t.hours_worked,
    t.notes_json
FROM Timesheets t
LEFT JOIN Employees e ON t.employee_id = e.employee_id
LEFT JOIN Projects p ON t.project_id = p.project_id
LEFT JOIN Departments d ON t.department_id = d.department_id;
GO

-- MATERIALIZED VIEW SIMULAT (VIEW cu SCHEMABINDING + INDEX)
-- Comentariu: Totalul orelor lucrate per proiect și lună
CREATE VIEW Timesheet_MonthlyStats
WITH SCHEMABINDING
AS
SELECT 
    t.project_id,
    CONVERT(CHAR(7), t.work_date, 120) AS work_month,  -- ex: '2025-06'
    SUM(t.hours_worked) AS total_hours
FROM dbo.Timesheets t
GROUP BY t.project_id, CONVERT(CHAR(7), t.work_date, 120);
GO

-- Acest SELECT grupează pontajele pentru a obține totalul de ore per proiect pentru fiecare angajat folosind GROUP BY.
SELECT 
    employee_id,
    project_id,
    SUM(hours_worked) AS total_hours
FROM Timesheets
GROUP BY employee_id, project_id;
GO

-- Lista tuturor angajaților și pontările lor de ieri (dacă există) folosinf LEFT JOIN.
SELECT 
    e.employee_id,
    e.employee_name,
    t.work_date,
    t.hours_worked
FROM Employees e
LEFT JOIN Timesheets t ON e.employee_id = t.employee_id AND t.work_date = CAST(GETDATE() - 1 AS DATE);
GO

-- SELECT cu FUNCȚIE ANALITICĂ
-- Comentariu: Compară orele lucrate cu ziua precedentă folosind LAG().
SELECT 
    employee_id,
    work_date,
    hours_worked,
    LAG(hours_worked) OVER (PARTITION BY employee_id ORDER BY work_date) AS prev_day_hours
FROM Timesheets;
-- Pentru fiecare angajat, afișează orele lucrate în ziua curentă și în ziua precedentă.
GO
