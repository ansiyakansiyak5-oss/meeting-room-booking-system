-- =======================================================
-- MEETING ROOM BOOKING SYSTEM
-- Database Schema for MySQL / Aiven Cloud MySQL
-- =======================================================

CREATE DATABASE IF NOT EXISTS meeting_room_db;
USE meeting_room_db;

-- 1. Users Table (Authentication)
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

-- 2. Rooms Table (Meeting Rooms & Rates)
CREATE TABLE IF NOT EXISTS rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_number VARCHAR(30) UNIQUE NOT NULL,
    room_name VARCHAR(100) NOT NULL,
    building VARCHAR(100) NOT NULL,
    floor VARCHAR(30),
    capacity INT NOT NULL,
    room_type VARCHAR(50),
    facilities VARCHAR(255),
    hourly_rate DECIMAL(10,2) DEFAULT 15.00,
    status VARCHAR(30) DEFAULT 'Available'
);

-- 3. Bookings Table (Meeting Reservations with Payment Details)
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_number VARCHAR(50) UNIQUE NOT NULL,
    room_id INT NOT NULL,
    room_number VARCHAR(30) NOT NULL,
    room_name VARCHAR(100),
    employee_name VARCHAR(100) NOT NULL,
    employee_id VARCHAR(50) NOT NULL,
    department VARCHAR(100),
    user_type VARCHAR(50) DEFAULT 'Employee',
    meeting_title VARCHAR(150) NOT NULL,
    meeting_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    participants INT NOT NULL,
    purpose VARCHAR(255),
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'Offline',
    payment_status VARCHAR(30) DEFAULT 'Pending',
    booking_status VARCHAR(30) DEFAULT 'Booked',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE RESTRICT
);

-- Default Administrator & Student Users (Secure SHA-256 hashed)
-- student / student123: 703b0a3d6ad75b649a28adde7d83c6251da457549263bc7ff45ec709b0a8448b
-- admin / admin123: 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9
INSERT INTO users (username, password) 
VALUES 
    ('student', '703b0a3d6ad75b649a28adde7d83c6251da457549263bc7ff45ec709b0a8448b'),
    ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9')
ON DUPLICATE KEY UPDATE username = username;

-- Sample Rooms with Pricing
INSERT INTO rooms (room_number, room_name, building, floor, capacity, room_type, facilities, hourly_rate, status) VALUES
('CR-101', 'Apollo Conference Hall', 'Campus Main Building', '1st Floor', 20, 'Conference Room', 'Projector, Video Conferencing, Whiteboard, High-Speed Wi-Fi', 25.00, 'Available'),
('MR-202', 'Boardroom Executive', 'Admin Block', '2nd Floor', 12, 'Board Room', 'Smart TV, Conference Phone, Executive Chairs, Whiteboard', 30.00, 'Available'),
('HR-301', 'Innovation Student Huddle', 'Student Tech Center', '3rd Floor', 6, 'Huddle Room', 'Wall Display, Whiteboard, Power Outlets, High-Speed Wi-Fi', 10.00, 'Available'),
('CR-105', 'Orion Auditorium & Seminar Hall', 'Academic Hall', '1st Floor', 30, 'Seminar Room', 'Dual Projectors, Mic System, Podium, Sound System', 40.00, 'Available'),
('MR-404', 'Genesis Team Collaboration Room', 'Research Wing', '4th Floor', 10, 'Meeting Room', 'Video Bar, Whiteboard, High-Speed Wi-Fi', 15.00, 'Available')
ON DUPLICATE KEY UPDATE 
    room_name = VALUES(room_name),
    hourly_rate = VALUES(hourly_rate);
