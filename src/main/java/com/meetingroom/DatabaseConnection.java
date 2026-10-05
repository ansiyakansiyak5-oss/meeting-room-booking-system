package com.meetingroom;

import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * DatabaseConnection handles JDBC connections to MySQL (including Aiven Cloud MySQL).
 * Reads configuration from Environment Variables, with support for DATABASE_URL/MYSQL_URL,
 * individual DB_* variables, and fallback defaults.
 */
public class DatabaseConnection {

    private static final String DRIVER_CLASS = "com.mysql.cj.jdbc.Driver";
    private static volatile boolean isInitialized = false;

    static {
        try {
            Class.forName(DRIVER_CLASS);
        } catch (ClassNotFoundException e) {
            System.err.println("[DatabaseConnection] MySQL Driver not found: " + e.getMessage());
        }
    }

    /**
     * Resolves the environment variable value, checking System.getenv and System.getProperty.
     */
    public static String getEnvOrProp(String name, String defaultValue) {
        String val = System.getenv(name);
        if (val == null || val.trim().isEmpty()) {
            val = System.getProperty(name);
        }
        return (val != null && !val.trim().isEmpty()) ? val.trim() : defaultValue;
    }

    /**
     * Establishes and returns a new JDBC Connection to MySQL.
     * Works with Aiven MySQL (requiring SSL) and standard MySQL instances.
     */
    public static Connection getConnection() throws SQLException {
        // Check if full connection URL is provided (common on Railway / Render)
        String databaseUrl = getEnvOrProp("DATABASE_URL", getEnvOrProp("MYSQL_URL", null));

        String host = "localhost";
        String port = "3306";
        String dbName = "meeting_room_db";
        String user = "root";
        String password = "";
        boolean isAivenOrCloud = false;

        if (databaseUrl != null && (databaseUrl.startsWith("mysql://") || databaseUrl.startsWith("jdbc:mysql://"))) {
            try {
                String cleanUrl = databaseUrl;
                if (cleanUrl.startsWith("jdbc:")) {
                    cleanUrl = cleanUrl.substring(5);
                }
                URI uri = new URI(cleanUrl);
                if (uri.getHost() != null) host = uri.getHost();
                if (uri.getPort() > 0) port = String.valueOf(uri.getPort());
                if (uri.getPath() != null && uri.getPath().length() > 1) {
                    dbName = uri.getPath().substring(1);
                }
                if (uri.getUserInfo() != null) {
                    String[] userInfo = uri.getUserInfo().split(":", 2);
                    user = userInfo[0];
                    if (userInfo.length > 1) {
                        password = userInfo[1];
                    }
                }
                isAivenOrCloud = true;
            } catch (Exception e) {
                System.err.println("[DatabaseConnection] Warning: Failed to parse DATABASE_URL: " + e.getMessage());
            }
        } else {
            // Read individual environment variables
            host = getEnvOrProp("DB_HOST", "localhost");
            port = getEnvOrProp("DB_PORT", "3306");
            dbName = getEnvOrProp("DB_NAME", "meeting_room_db");
            user = getEnvOrProp("DB_USER", "root");
            password = getEnvOrProp("DB_PASSWORD", "");
        }

        // Aiven hosts typically contain 'aivencloud.com'
        if (host.contains("aivencloud.com") || "true".equalsIgnoreCase(getEnvOrProp("DB_SSL", "true"))) {
            isAivenOrCloud = true;
        }

        // Build JDBC URL
        // Aiven MySQL requires SSL.
        String jdbcUrl;
        if (isAivenOrCloud && !host.equalsIgnoreCase("localhost")) {
            jdbcUrl = String.format(
                "jdbc:mysql://%s:%s/%s?ssl-mode=REQUIRED&useSSL=true&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                host, port, dbName
            );
        } else {
            jdbcUrl = String.format(
                "jdbc:mysql://%s:%s/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                host, port, dbName
            );
        }

        Connection conn = DriverManager.getConnection(jdbcUrl, user, password);

        // Ensure tables exist on first successful connection
        if (!isInitialized) {
            synchronized (DatabaseConnection.class) {
                if (!isInitialized) {
                    initDatabaseTables(conn);
                    isInitialized = true;
                }
            }
        }

        return conn;
    }

    /**
     * Initializes tables and default records if they do not exist.
     */
    public static void initDatabaseTables(Connection conn) {
        String createUsers = "CREATE TABLE IF NOT EXISTS users (" +
                "user_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "username VARCHAR(50) UNIQUE NOT NULL, " +
                "password VARCHAR(255) NOT NULL" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        String createRooms = "CREATE TABLE IF NOT EXISTS rooms (" +
                "room_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "room_number VARCHAR(30) UNIQUE NOT NULL, " +
                "room_name VARCHAR(100) NOT NULL, " +
                "building VARCHAR(100) NOT NULL, " +
                "floor VARCHAR(30), " +
                "capacity INT NOT NULL, " +
                "room_type VARCHAR(50), " +
                "facilities VARCHAR(255), " +
                "status VARCHAR(30) DEFAULT 'Available'" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        String createBookings = "CREATE TABLE IF NOT EXISTS bookings (" +
                "booking_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "booking_number VARCHAR(50) UNIQUE NOT NULL, " +
                "room_id INT NOT NULL, " +
                "room_number VARCHAR(30) NOT NULL, " +
                "room_name VARCHAR(100), " +
                "employee_name VARCHAR(100) NOT NULL, " +
                "employee_id VARCHAR(50) NOT NULL, " +
                "department VARCHAR(100), " +
                "meeting_title VARCHAR(150) NOT NULL, " +
                "meeting_date DATE NOT NULL, " +
                "start_time TIME NOT NULL, " +
                "end_time TIME NOT NULL, " +
                "participants INT NOT NULL, " +
                "purpose VARCHAR(255), " +
                "booking_status VARCHAR(30) DEFAULT 'Booked', " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE RESTRICT" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        try (Statement stmt = conn.createStatement()) {
            stmt.executeUpdate(createUsers);
            stmt.executeUpdate(createRooms);
            stmt.executeUpdate(createBookings);

            // Insert default admin if not exists
            try (PreparedStatement checkAdmin = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE username = ?")) {
                checkAdmin.setString(1, "admin");
                try (ResultSet rs = checkAdmin.executeQuery()) {
                    if (rs.next() && rs.getInt(1) == 0) {
                        try (PreparedStatement insertAdmin = conn.prepareStatement("INSERT INTO users (username, password) VALUES (?, ?)")) {
                            insertAdmin.setString(1, "admin");
                            insertAdmin.setString(2, "admin123");
                            insertAdmin.executeUpdate();
                            System.out.println("[DatabaseConnection] Default admin user created (admin / admin123).");
                        }
                    }
                }
            }

            // Insert sample rooms if rooms table is empty
            try (Statement checkRooms = conn.createStatement();
                 ResultSet rs = checkRooms.executeQuery("SELECT COUNT(*) FROM rooms")) {
                if (rs.next() && rs.getInt(1) == 0) {
                    String sampleRooms = "INSERT INTO rooms (room_number, room_name, building, floor, capacity, room_type, facilities, status) VALUES " +
                            "('CR-101', 'Apollo Conference Hall', 'Building A', '1st Floor', 20, 'Conference Room', 'Projector, Video Conferencing, Whiteboard, High-Speed Wi-Fi', 'Available'), " +
                            "('MR-202', 'Boardroom Executive', 'Building A', '2nd Floor', 12, 'Board Room', 'Smart TV, Conference Phone, Executive Chairs, Whiteboard', 'Available'), " +
                            "('HR-301', 'Innovation Huddle', 'Building B', '3rd Floor', 6, 'Huddle Room', 'Wall Display, Whiteboard, Power Outlets', 'Available'), " +
                            "('CR-105', 'Orion Seminar Room', 'Building B', '1st Floor', 30, 'Seminar Room', 'Dual Projectors, Mic System, Podium, Sound System', 'Available'), " +
                            "('MR-404', 'Genesis Meeting Room', 'Building C', '4th Floor', 10, 'Meeting Room', 'Video Bar, Whiteboard, Wi-Fi', 'Available')";
                    stmt.executeUpdate(sampleRooms);
                    System.out.println("[DatabaseConnection] Sample meeting rooms inserted.");
                }
            }

        } catch (SQLException e) {
            System.err.println("[DatabaseConnection] Table initialization notice: " + e.getMessage());
        }
    }

    /**
     * Diagnostic method to test connection.
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            System.err.println("[DatabaseConnection] Connection failed: " + e.getMessage());
            return false;
        }
    }

    /**
     * Main method to allow quick terminal-based testing of Aiven/MySQL connection.
     * Run with: java -cp ... com.meetingroom.DatabaseConnection
     */
    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println("  MEETING ROOM BOOKING SYSTEM - DB CONNECTION TEST");
        System.out.println("==================================================");
        System.out.println("DB_HOST: " + getEnvOrProp("DB_HOST", "localhost"));
        System.out.println("DB_PORT: " + getEnvOrProp("DB_PORT", "3306"));
        System.out.println("DB_NAME: " + getEnvOrProp("DB_NAME", "meeting_room_db"));
        System.out.println("DB_USER: " + getEnvOrProp("DB_USER", "root"));
        System.out.println("DB_PASSWORD: [PROTECTED]");
        System.out.println("Connecting...");

        try (Connection conn = getConnection()) {
            if (conn != null && !conn.isClosed()) {
                System.out.println("[SUCCESS] Connected to MySQL successfully!");
                System.out.println("Catalog: " + conn.getCatalog());
                System.out.println("Database Product: " + conn.getMetaData().getDatabaseProductName() + " " + conn.getMetaData().getDatabaseProductVersion());
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to connect: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
