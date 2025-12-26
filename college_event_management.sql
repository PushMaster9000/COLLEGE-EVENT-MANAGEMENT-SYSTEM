-- =============================================
-- COLLEGE EVENT MANAGEMENT SYSTEM DATABASE
-- Complete SQL Implementation with All Requirements
-- =============================================

-- 1. DDL (DATA DEFINITION LANGUAGE)
-- =============================================

-- Create Database
CREATE DATABASE IF NOT EXISTS college_event_management;
USE college_event_management;

-- Users Table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('student', 'organizer', 'admin') DEFAULT 'student',
    department VARCHAR(50),
    year INT CHECK (year BETWEEN 1 AND 4),
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Events Table
CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    time TIME NOT NULL,
    location VARCHAR(255) NOT NULL,
    category ENUM('technical', 'cultural', 'workshop', 'sports', 'other') NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    organizer_id INT NOT NULL,
    image_url VARCHAR(500),
    status ENUM('upcoming', 'ongoing', 'completed', 'cancelled') DEFAULT 'upcoming',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Registrations Table
CREATE TABLE registrations (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id INT NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'confirmed', 'cancelled', 'attended') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',
    payment_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (payment_amount >= 0),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    UNIQUE KEY unique_registration (user_id, event_id)
);

-- Resources Table
CREATE TABLE resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('equipment', 'venue', 'material', 'other') NOT NULL,
    description TEXT,
    availability BOOLEAN DEFAULT TRUE,
    event_id INT,
    allocated_to INT,
    allocated_date DATE,
    return_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL,
    FOREIGN KEY (allocated_to) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Notifications Table
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'warning', 'success', 'error') DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Payments Table
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('cash', 'card', 'online', 'upi') DEFAULT 'cash',
    transaction_id VARCHAR(100),
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    FOREIGN KEY (registration_id) REFERENCES registrations(registration_id) ON DELETE CASCADE
);

-- Create Indexes for Performance
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_registrations_user ON registrations(user_id);
CREATE INDEX idx_registrations_event ON registrations(event_id);
CREATE INDEX idx_registrations_status ON registrations(status);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_resources_availability ON resources(availability);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_payments_date ON payments(payment_date);

-- =============================================
-- 2. DML (DATA MANIPULATION LANGUAGE)
-- =============================================

-- Insert sample data into users table
INSERT INTO users (name, email, password, role, department, year, phone) VALUES
('Admin User', 'admin@college.edu', 'admin123', 'admin', 'Administration', NULL, '9876543210'),
('Prof. Sharma', 'sharma@college.edu', 'prof123', 'organizer', 'Computer Science', NULL, '9876543211'),
('Dr. Verma', 'verma@college.edu', 'prof123', 'organizer', 'Electronics', NULL, '9876543212'),
('Rahul Kumar', 'rahul@student.college.edu', 'student123', 'student', 'Computer Science', 3, '9876543213'),
('Priya Singh', 'priya@student.college.edu', 'student123', 'student', 'Information Technology', 2, '9876543214'),
('Amit Patel', 'amit@student.college.edu', 'student123', 'student', 'Mechanical', 4, '9876543215'),
('Sneha Gupta', 'sneha@student.college.edu', 'student123', 'student', 'Civil', 1, '9876543216'),
('Rajesh Nair', 'rajesh@student.college.edu', 'student123', 'student', 'Computer Science', 3, '9876543217');

-- Insert sample data into events table
INSERT INTO events (title, description, date, time, location, category, capacity, organizer_id) VALUES
('Annual Tech Fest 2024', 'Biggest technology festival with workshops, hackathons and guest lectures from industry experts', '2024-03-15', '09:00:00', 'Main Auditorium', 'technical', 500, 2),
('Cultural Night 2024', 'An evening of music, dance and cultural performances showcasing diversity of our college', '2024-03-20', '18:00:00', 'Open Air Theater', 'cultural', 300, 3),
('Web Development Workshop', 'Hands-on workshop on modern web technologies: HTML5, CSS3, JavaScript, Node.js and React', '2024-03-25', '14:00:00', 'Computer Lab 3', 'workshop', 30, 2),
('Basketball Tournament', 'Inter-department basketball championship with exciting prizes for winners', '2024-04-05', '08:00:00', 'Sports Complex', 'sports', 100, 3),
('AI and ML Seminar', 'Expert talk on Artificial Intelligence and Machine Learning trends and career opportunities', '2024-04-10', '11:00:00', 'Seminar Hall', 'technical', 200, 2),
('Robotics Workshop', 'Build and program your own robot using Arduino and sensors', '2024-04-15', '10:00:00', 'Electronics Lab', 'workshop', 25, 3);

-- Insert sample data into registrations table
INSERT INTO registrations (user_id, event_id, status, payment_status, payment_amount, notes) VALUES
(4, 1, 'confirmed', 'paid', 100.00, 'Early bird registration'),
(5, 1, 'confirmed', 'paid', 100.00, 'Group registration'),
(6, 1, 'pending', 'pending', 100.00, 'Waiting for payment'),
(4, 2, 'confirmed', 'paid', 50.00, 'Cultural event'),
(7, 2, 'confirmed', 'paid', 50.00, NULL),
(8, 3, 'confirmed', 'paid', 200.00, 'Workshop fee'),
(5, 3, 'confirmed', 'paid', 200.00, 'Advanced track'),
(6, 4, 'confirmed', 'paid', 0.00, 'Free event'),
(7, 5, 'pending', 'pending', 0.00, 'Free seminar'),
(8, 6, 'confirmed', 'paid', 150.00, 'Kit included');

-- Insert sample data into resources table
INSERT INTO resources (name, type, description, availability, event_id, allocated_to) VALUES
('Projector HD', 'equipment', 'High definition projector for presentations', TRUE, NULL, NULL),
('Main Auditorium', 'venue', 'Large auditorium with 500 seating capacity', FALSE, 1, 2),
('Laptop i7', 'equipment', 'High performance laptop for workshops', TRUE, NULL, NULL),
('Sports Equipment', 'material', 'Basketballs, nets and other sports gear', FALSE, 4, 3),
('Arduino Kits', 'material', 'Complete Arduino starter kits with sensors', FALSE, 6, 3),
('Sound System', 'equipment', 'Professional sound system with microphones', TRUE, NULL, NULL);

-- Insert sample data into notifications table
INSERT INTO notifications (user_id, title, message, type, is_read) VALUES
(4, 'Registration Confirmed', 'Your registration for Annual Tech Fest 2024 has been confirmed', 'success', TRUE),
(5, 'Payment Pending', 'Please complete your payment for Web Development Workshop', 'warning', FALSE),
(6, 'Event Reminder', 'Basketball Tournament starts tomorrow at 8:00 AM', 'info', FALSE),
(7, 'Registration Successful', 'You have successfully registered for AI and ML Seminar', 'success', TRUE);

-- Insert sample data into payments table
INSERT INTO payments (registration_id, amount, payment_method, transaction_id, status) VALUES
(1, 100.00, 'online', 'TXN001234', 'completed'),
(2, 100.00, 'card', 'TXN001235', 'completed'),
(4, 50.00, 'upi', 'TXN001236', 'completed'),
(5, 50.00, 'cash', 'TXN001237', 'completed'),
(6, 200.00, 'online', 'TXN001238', 'completed'),
(7, 200.00, 'card', 'TXN001239', 'completed'),
(8, 0.00, 'cash', NULL, 'completed'),
(10, 150.00, 'online', 'TXN001240', 'completed');

-- =============================================
-- 3. SQL QUERIES, FUNCTIONS AND OPERATORS
-- =============================================

-- Simple SELECT queries with WHERE clause
SELECT * FROM users WHERE role = 'student';
SELECT name, email, department FROM users WHERE year = 3;
SELECT title, date, location FROM events WHERE date > '2024-03-20';

-- Using Aggregate Functions
SELECT COUNT(*) AS total_students FROM users WHERE role = 'student';
SELECT AVG(payment_amount) AS avg_payment FROM registrations WHERE payment_status = 'paid';
SELECT MAX(capacity) AS max_capacity, MIN(capacity) AS min_capacity FROM events;
SELECT SUM(payment_amount) AS total_revenue FROM registrations WHERE payment_status = 'paid';

-- Using String Functions
SELECT UPPER(name) AS uppercase_name, LOWER(department) AS lower_dept FROM users;
SELECT CONCAT(name, ' - ', department) AS user_info FROM users;
SELECT SUBSTRING(title, 1, 10) AS short_title FROM events;

-- Using Date Functions
SELECT title, DATE_FORMAT(date, '%W, %M %d, %Y') AS formatted_date FROM events;
SELECT DATEDIFF(date, CURDATE()) AS days_remaining, title FROM events WHERE date > CURDATE();
SELECT YEAR(date) AS event_year, MONTH(date) AS event_month, COUNT(*) AS events_count 
FROM events GROUP BY YEAR(date), MONTH(date);

-- Using Mathematical Operators
SELECT title, capacity, (capacity - (
    SELECT COUNT(*) FROM registrations r 
    WHERE r.event_id = events.event_id AND r.status = 'confirmed'
)) AS available_slots FROM events;

-- Using Logical Operators (AND, OR, NOT)
SELECT * FROM events WHERE category = 'technical' AND capacity > 100;
SELECT * FROM users WHERE role = 'student' AND (department = 'Computer Science' OR department = 'Information Technology');
SELECT * FROM events WHERE NOT status = 'cancelled';

-- Using Comparison Operators
SELECT * FROM events WHERE capacity BETWEEN 50 AND 300;
SELECT * FROM users WHERE year IN (2, 3);
SELECT * FROM registrations WHERE payment_amount > 0 AND payment_status = 'paid';

-- Using LIKE operator for pattern matching
SELECT * FROM users WHERE name LIKE 'R%';
SELECT * FROM events WHERE title LIKE '%Workshop%';
SELECT * FROM users WHERE email LIKE '%@student.%';

-- =============================================
-- 4. JOIN OPERATIONS
-- =============================================

-- INNER JOIN: Get events with organizer details
SELECT e.title, e.date, e.location, u.name AS organizer_name, u.department
FROM events e
INNER JOIN users u ON e.organizer_id = u.user_id;

-- LEFT JOIN: Get all users and their event registrations
SELECT u.name, u.department, e.title AS event_name, r.registration_date
FROM users u
LEFT JOIN registrations r ON u.user_id = r.user_id
LEFT JOIN events e ON r.event_id = e.event_id
WHERE u.role = 'student';

-- RIGHT JOIN: Get all events and their registrations (including events with no registrations)
SELECT e.title, COUNT(r.registration_id) AS registration_count
FROM registrations r
RIGHT JOIN events e ON r.event_id = e.event_id
GROUP BY e.event_id, e.title;

-- Multiple JOINs: Get complete registration details
SELECT 
    u.name AS student_name,
    u.department,
    e.title AS event_title,
    e.date,
    r.registration_date,
    r.payment_status,
    p.amount,
    p.payment_method
FROM registrations r
JOIN users u ON r.user_id = u.user_id
JOIN events e ON r.event_id = e.event_id
LEFT JOIN payments p ON r.registration_id = p.registration_id;

-- SELF JOIN: Find students from same department and year
SELECT 
    u1.name AS student1,
    u2.name AS student2,
    u1.department,
    u1.year
FROM users u1
JOIN users u2 ON u1.department = u2.department 
    AND u1.year = u2.year 
    AND u1.user_id < u2.user_id
WHERE u1.role = 'student';

-- =============================================
-- 5. VIEWS AND NESTED QUERIES
-- =============================================

-- Create View for Event Statistics
CREATE VIEW event_statistics AS
SELECT 
    e.event_id,
    e.title,
    e.date,
    e.capacity,
    COUNT(r.registration_id) AS registered_count,
    (e.capacity - COUNT(r.registration_id)) AS available_slots,
    ROUND((COUNT(r.registration_id) / e.capacity * 100), 2) AS registration_percentage,
    SUM(r.payment_amount) AS total_revenue
FROM events e
LEFT JOIN registrations r ON e.event_id = r.event_id AND r.status = 'confirmed'
GROUP BY e.event_id, e.title, e.date, e.capacity;

-- Create View for Student Dashboard
CREATE VIEW student_dashboard AS
SELECT 
    u.user_id,
    u.name,
    u.department,
    u.year,
    COUNT(r.registration_id) AS total_registrations,
    SUM(CASE WHEN r.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_registrations,
    SUM(r.payment_amount) AS total_payments
FROM users u
LEFT JOIN registrations r ON u.user_id = r.user_id
WHERE u.role = 'student'
GROUP BY u.user_id, u.name, u.department, u.year;

-- Create View for Organizer Events
CREATE VIEW organizer_events AS
SELECT 
    u.name AS organizer_name,
    u.department,
    e.event_id,
    e.title,
    e.date,
    e.status,
    COUNT(r.registration_id) AS total_registrations
FROM users u
JOIN events e ON u.user_id = e.organizer_id
LEFT JOIN registrations r ON e.event_id = r.event_id
GROUP BY u.user_id, u.name, u.department, e.event_id, e.title, e.date, e.status;

-- Nested Queries (Subqueries)

-- Find events with above average capacity
SELECT title, capacity 
FROM events 
WHERE capacity > (SELECT AVG(capacity) FROM events);

-- Find students who registered for technical events
SELECT name, department
FROM users
WHERE user_id IN (
    SELECT DISTINCT user_id 
    FROM registrations 
    WHERE event_id IN (
        SELECT event_id 
        FROM events 
        WHERE category = 'technical'
    )
);

-- Find most popular event category
SELECT category, COUNT(*) AS event_count
FROM events
GROUP BY category
HAVING COUNT(*) = (
    SELECT MAX(event_count) 
    FROM (
        SELECT COUNT(*) AS event_count 
        FROM events 
        GROUP BY category
    ) AS category_counts
);

-- Correlated Subquery: Find events with maximum registrations in their category
SELECT e1.title, e1.category, COUNT(r.registration_id) AS registration_count
FROM events e1
LEFT JOIN registrations r ON e1.event_id = r.event_id
GROUP BY e1.event_id, e1.title, e1.category
HAVING COUNT(r.registration_id) = (
    SELECT MAX(reg_count)
    FROM (
        SELECT COUNT(r2.registration_id) AS reg_count
        FROM events e2
        LEFT JOIN registrations r2 ON e2.event_id = r2.event_id
        WHERE e2.category = e1.category
        GROUP BY e2.event_id
    ) AS category_max
);

-- =============================================
-- 6. TRIGGERS
-- =============================================

-- Trigger to update event status based on date
DELIMITER //
CREATE TRIGGER update_event_status
BEFORE UPDATE ON events
FOR EACH ROW
BEGIN
    IF NEW.date < CURDATE() AND OLD.status != 'completed' THEN
        SET NEW.status = 'completed';
    ELSEIF NEW.date = CURDATE() AND OLD.status != 'ongoing' THEN
        SET NEW.status = 'ongoing';
    END IF;
END//
DELIMITER ;

-- Trigger to prevent overbooking
DELIMITER //
CREATE TRIGGER prevent_overbooking
BEFORE INSERT ON registrations
FOR EACH ROW
BEGIN
    DECLARE current_registrations INT;
    DECLARE event_capacity INT;
    
    SELECT COUNT(*) INTO current_registrations 
    FROM registrations 
    WHERE event_id = NEW.event_id AND status = 'confirmed';
    
    SELECT capacity INTO event_capacity 
    FROM events 
    WHERE event_id = NEW.event_id;
    
    IF current_registrations >= event_capacity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Event is already full. Cannot register.';
    END IF;
END//
DELIMITER ;

-- Trigger to update resource availability when allocated to event
DELIMITER //
CREATE TRIGGER update_resource_availability
BEFORE UPDATE ON resources
FOR EACH ROW
BEGIN
    IF NEW.event_id IS NOT NULL AND OLD.event_id IS NULL THEN
        SET NEW.availability = FALSE;
        SET NEW.allocated_date = CURDATE();
    ELSEIF NEW.event_id IS NULL AND OLD.event_id IS NOT NULL THEN
        SET NEW.availability = TRUE;
        SET NEW.allocated_date = NULL;
        SET NEW.return_date = CURDATE();
    END IF;
END//
DELIMITER ;

-- Trigger to log registration changes
CREATE TABLE registration_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT,
    old_status ENUM('pending', 'confirmed', 'cancelled', 'attended'),
    new_status ENUM('pending', 'confirmed', 'cancelled', 'attended'),
    changed_by VARCHAR(100),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER log_registration_changes
AFTER UPDATE ON registrations
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO registration_audit (registration_id, old_status, new_status, changed_by)
        VALUES (NEW.registration_id, OLD.status, NEW.status, USER());
    END IF;
END//
DELIMITER ;

-- =============================================
-- 7. DCL (DATA CONTROL LANGUAGE) AND TCL (TRANSACTION CONTROL LANGUAGE)
-- =============================================

-- Create Users for Database Access
CREATE USER 'event_admin'@'localhost' IDENTIFIED BY 'admin_password';
CREATE USER 'event_organizer'@'localhost' IDENTIFIED BY 'organizer_password';
CREATE USER 'event_student'@'localhost' IDENTIFIED BY 'student_password';

-- Grant Privileges (DCL)
-- Admin has all privileges
GRANT ALL PRIVILEGES ON college_event_management.* TO 'event_admin'@'localhost';

-- Organizer can manage events and view registrations
GRANT SELECT, INSERT, UPDATE, DELETE ON college_event_management.events TO 'event_organizer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON college_event_management.registrations TO 'event_organizer'@'localhost';
GRANT SELECT ON college_event_management.users TO 'event_organizer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON college_event_management.resources TO 'event_organizer'@'localhost';

-- Student can view events and manage their registrations
GRANT SELECT ON college_event_management.events TO 'event_student'@'localhost';
GRANT SELECT, INSERT, UPDATE ON college_event_management.registrations TO 'event_student'@'localhost';
GRANT SELECT ON college_event_management.users TO 'event_student'@'localhost';

-- Apply privileges
FLUSH PRIVILEGES;

-- Transaction Examples (TCL)

-- Example 1: Complete event registration with payment
START TRANSACTION;

-- Register for event
INSERT INTO registrations (user_id, event_id, status, payment_status, payment_amount)
VALUES (4, 3, 'confirmed', 'paid', 200.00);

-- Get the last inserted registration ID
SET @reg_id = LAST_INSERT_ID();

-- Record payment
INSERT INTO payments (registration_id, amount, payment_method, transaction_id, status)
VALUES (@reg_id, 200.00, 'online', CONCAT('TXN', UNIX_TIMESTAMP()), 'completed');

-- Update resource allocation
UPDATE resources 
SET event_id = 3, allocated_to = 4, availability = FALSE 
WHERE resource_id = 3;

COMMIT;

-- Example 2: Cancel registration with refund
START TRANSACTION;

-- Update registration status
UPDATE registrations 
SET status = 'cancelled', payment_status = 'refunded'
WHERE registration_id = 2;

-- Record refund in payments
INSERT INTO payments (registration_id, amount, payment_method, status)
VALUES (2, -100.00, 'online', 'refunded');

-- Free up allocated resources
UPDATE resources 
SET event_id = NULL, allocated_to = NULL, availability = TRUE 
WHERE allocated_to = 5 AND event_id = 1;

COMMIT;

-- Example 3: Rollback on error
START TRANSACTION;

BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Attempt to register for full event (will trigger prevent_overbooking trigger)
    INSERT INTO registrations (user_id, event_id, status, payment_status, payment_amount)
    VALUES (7, 1, 'confirmed', 'paid', 100.00);
    
    COMMIT;
END;

-- =============================================
-- 8. STORED PROCEDURES AND FUNCTIONS
-- =============================================

-- Procedure to register student for event
DELIMITER //
CREATE PROCEDURE RegisterForEvent(
    IN p_user_id INT,
    IN p_event_id INT,
    IN p_payment_amount DECIMAL(10,2),
    IN p_payment_method ENUM('cash', 'card', 'online', 'upi')
)
BEGIN
    DECLARE v_registration_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insert registration
    INSERT INTO registrations (user_id, event_id, payment_amount)
    VALUES (p_user_id, p_event_id, p_payment_amount);
    
    SET v_registration_id = LAST_INSERT_ID();
    
    -- If payment amount > 0, record payment
    IF p_payment_amount > 0 THEN
        INSERT INTO payments (registration_id, amount, payment_method, status)
        VALUES (v_registration_id, p_payment_amount, p_payment_method, 'completed');
        
        UPDATE registrations 
        SET payment_status = 'paid', status = 'confirmed'
        WHERE registration_id = v_registration_id;
    ELSE
        UPDATE registrations 
        SET status = 'confirmed'
        WHERE registration_id = v_registration_id;
    END IF;
    
    -- Send notification
    INSERT INTO notifications (user_id, title, message, type)
    SELECT 
        p_user_id,
        'Registration Successful',
        CONCAT('You have successfully registered for ', title),
        'success'
    FROM events WHERE event_id = p_event_id;
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to get event statistics
DELIMITER //
CREATE PROCEDURE GetEventStatistics(IN p_event_id INT)
BEGIN
    SELECT 
        e.title,
        e.date,
        e.location,
        e.capacity,
        COUNT(r.registration_id) AS total_registrations,
        SUM(CASE WHEN r.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_registrations,
        SUM(r.payment_amount) AS total_revenue,
        u.name AS organizer_name
    FROM events e
    LEFT JOIN registrations r ON e.event_id = r.event_id
    LEFT JOIN users u ON e.organizer_id = u.user_id
    WHERE e.event_id = p_event_id
    GROUP BY e.event_id, e.title, e.date, e.location, e.capacity, u.name;
END//
DELIMITER ;

-- Function to calculate event popularity score
DELIMITER //
CREATE FUNCTION CalculateEventPopularity(p_event_id INT) 
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE popularity_score DECIMAL(5,2);
    DECLARE reg_count INT;
    DECLARE event_capacity INT;
    DECLARE days_until_event INT;
    
    SELECT 
        COUNT(r.registration_id),
        e.capacity,
        DATEDIFF(e.date, CURDATE())
    INTO reg_count, event_capacity, days_until_event
    FROM events e
    LEFT JOIN registrations r ON e.event_id = r.event_id AND r.status = 'confirmed'
    WHERE e.event_id = p_event_id
    GROUP BY e.event_id;
    
    IF reg_count = 0 THEN
        SET popularity_score = 0;
    ELSE
        SET popularity_score = (reg_count / event_capacity) * 100;
        
        -- Adjust score based on how soon the event is
        IF days_until_event <= 7 THEN
            SET popularity_score = popularity_score * 1.2;
        ELSEIF days_until_event <= 30 THEN
            SET popularity_score = popularity_score * 1.1;
        END IF;
    END IF;
    
    RETURN LEAST(popularity_score, 100);
END//
DELIMITER ;

-- Function to check if user can register for event
DELIMITER //
CREATE FUNCTION CanUserRegister(p_user_id INT, p_event_id INT) 
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE already_registered INT;
    DECLARE event_capacity INT;
    DECLARE current_registrations INT;
    DECLARE event_date DATE;
    
    -- Check if already registered
    SELECT COUNT(*) INTO already_registered
    FROM registrations
    WHERE user_id = p_user_id AND event_id = p_event_id;
    
    IF already_registered > 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Check event capacity
    SELECT capacity, date INTO event_capacity, event_date
    FROM events
    WHERE event_id = p_event_id;
    
    SELECT COUNT(*) INTO current_registrations
    FROM registrations
    WHERE event_id = p_event_id AND status = 'confirmed';
    
    IF current_registrations >= event_capacity THEN
        RETURN FALSE;
    END IF;
    
    -- Check if event date is in future
    IF event_date <= CURDATE() THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END//
DELIMITER ;

-- Procedure to generate monthly report
DELIMITER //
CREATE PROCEDURE GenerateMonthlyReport(IN p_year INT, IN p_month INT)
BEGIN
    SELECT 
        e.category,
        COUNT(e.event_id) AS total_events,
        COUNT(r.registration_id) AS total_registrations,
        SUM(r.payment_amount) AS total_revenue,
        AVG(r.payment_amount) AS avg_payment
    FROM events e
    LEFT JOIN registrations r ON e.event_id = r.event_id
    WHERE YEAR(e.date) = p_year AND MONTH(e.date) = p_month
    GROUP BY e.category
    ORDER BY total_revenue DESC;
END//
DELIMITER ;

-- =============================================
-- DEMONSTRATION QUERIES
-- =============================================

-- Test the functions and procedures

-- Test CalculateEventPopularity function
SELECT 
    title,
    capacity,
    (SELECT COUNT(*) FROM registrations WHERE event_id = events.event_id AND status = 'confirmed') AS registrations,
    CalculateEventPopularity(event_id) AS popularity_score
FROM events;

-- Test CanUserRegister function
SELECT 
    name,
    CanUserRegister(user_id, 1) AS can_register
FROM users 
WHERE role = 'student';

-- Test stored procedures
CALL GetEventStatistics(1);
CALL GenerateMonthlyReport(2024, 3);

-- Test RegisterForEvent procedure
CALL RegisterForEvent(5, 2, 50.00, 'online');

-- Show all views
SELECT * FROM event_statistics;
SELECT * FROM student_dashboard;
SELECT * FROM organizer_events;

-- Show trigger effects
SELECT * FROM registration_audit;

-- =============================================
-- CLEANUP (Optional - for reset)
-- =============================================
/*
-- Drop database (use with caution)
-- DROP DATABASE IF EXISTS college_event_management;

-- Drop users
-- DROP USER 'event_admin'@'localhost';
-- DROP USER 'event_organizer'@'localhost';
-- DROP USER 'event_student'@'localhost';
*/