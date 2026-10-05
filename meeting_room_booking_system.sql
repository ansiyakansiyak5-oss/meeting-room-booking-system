-- =======================================================
-- MEETING ROOM BOOKING SYSTEM
-- Database Schema for MySQL / Aiven Cloud MySQL
-- =======================================================

CREATE DATABASE IF NOT EXISTS defaultdb;
USE defaultdb;

-- 1. Users Table (Authentication)
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

-- 2. Rooms Table (Meeting Rooms)
CREATE TABLE IF NOT EXISTS rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_number VARCHAR(30) UNIQUE NOT NULL,
    room_name VARCHAR(100) NOT NULL,
    building VARCHAR(100) NOT NULL,
    floor VARCHAR(30),
    capacity INT NOT NULL,
    room_type VARCHAR(50),
    facilities VARCHAR(255),
    status VARCHAR(30) DEFAULT 'Available'
);

-- 3. Bookings Table (Meeting Reservations)
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_number VARCHAR(50) UNIQUE NOT NULL,
    room_id INT NOT NULL,
    room_number VARCHAR(30) NOT NULL,
    room_name VARCHAR(100),
    employee_name VARCHAR(100) NOT NULL,
    employee_id VARCHAR(50) NOT NULL,
    department VARCHAR(100),
    meeting_title VARCHAR(150) NOT NULL,
    meeting_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    participants INT NOT NULL,
    purpose VARCHAR(255),
    booking_status VARCHAR(30) DEFAULT 'Booked',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE RESTRICT
);

-- Default Administrator
INSERT INTO users (username, password) 
VALUES ('admin', 'admin123')
ON DUPLICATE KEY UPDATE username = username;

-- Sample Rooms
INSERT INTO rooms (room_number, room_name, building, floor, capacity, room_type, facilities, status) VALUES
('CR-101', 'Apollo Conference Hall', 'Building A', '1st Floor', 20, 'Conference Room', 'Projector, Video Conferencing, Whiteboard, High-Speed Wi-Fi', 'Available'),
('MR-202', 'Boardroom Executive', 'Building A', '2nd Floor', 12, 'Board Room', 'Smart TV, Conference Phone, Executive Chairs, Whiteboard', 'Available'),
('HR-301', 'Innovation Huddle', 'Building B', '3rd Floor', 6, 'Huddle Room', 'Wall Display, Whiteboard, Power Outlets', 'Available'),
('CR-105', 'Orion Seminar Room', 'Building B', '1st Floor', 30, 'Seminar Room', 'Dual Projectors, Mic System, Podium, Sound System', 'Available'),
('MR-404', 'Genesis Meeting Room', 'Building C', '4th Floor', 10, 'Meeting Room', 'Video Bar, Whiteboard, Wi-Fi', 'Available')
ON DUPLICATE KEY UPDATE room_name = VALUES(room_name);
