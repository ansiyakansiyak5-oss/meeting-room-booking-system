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

        // Optional local convenience: Load db.env if present
        try {
            java.io.File[] candidates = new java.io.File[] {
                new java.io.File("db.env"),
                new java.io.File("../db.env"),
                new java.io.File(System.getProperty("catalina.base", "."), "db.env"),
                new java.io.File(System.getProperty("catalina.base", "."), "../db.env")
            };
            for (java.io.File envFile : candidates) {
                if (envFile.exists() && envFile.isFile()) {
                    java.util.Properties props = new java.util.Properties();
                    try (java.io.FileInputStream fis = new java.io.FileInputStream(envFile)) {
                        props.load(fis);
                        for (String key : props.stringPropertyNames()) {
                            if (System.getProperty(key) == null) {
                                System.setProperty(key, props.getProperty(key).trim());
                            }
                        }
                    }
                    break;
                }
            }
        } catch (Exception ignored) {}
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

        // Read individual environment variables
        host = getEnvOrProp("DB_HOST", "localhost");
        port = getEnvOrProp("DB_PORT", "3306");
        dbName = getEnvOrProp("DB_NAME", "meeting_room_db");
        user = getEnvOrProp("DB_USER", "root");
        password = getEnvOrProp("DB_PASSWORD", "");

        // If full database URL is provided (DATABASE_URL or MYSQL_URL), or if host contains full URI
        String fullUrlCandidate = getEnvOrProp("DATABASE_URL", getEnvOrProp("MYSQL_URL", null));
        if (fullUrlCandidate == null && (host.startsWith("mysql://") || host.startsWith("jdbc:mysql://") || host.startsWith("http://") || host.startsWith("https://") || host.contains("@"))) {
            fullUrlCandidate = host;
        }

        if (fullUrlCandidate != null && !fullUrlCandidate.trim().isEmpty()) {
            String s = fullUrlCandidate.trim();
            if (s.startsWith("jdbc:mysql://")) s = s.substring(13);
            else if (s.startsWith("mysql://")) s = s.substring(8);
            else if (s.startsWith("https://")) s = s.substring(8);
            else if (s.startsWith("http://")) s = s.substring(7);

            int qIdx = s.indexOf('?');
            if (qIdx != -1) s = s.substring(0, qIdx);

            int atIdx = s.indexOf('@');
            if (atIdx != -1) {
                String creds = s.substring(0, atIdx);
                s = s.substring(atIdx + 1);
                int colon = creds.indexOf(':');
                if (colon != -1) {
                    user = creds.substring(0, colon);
                    password = creds.substring(colon + 1);
                } else {
                    user = creds;
                }
            }

            int slashIdx = s.indexOf('/');
            if (slashIdx != -1) {
                String parsedDb = s.substring(slashIdx + 1);
                if (!parsedDb.isEmpty()) dbName = parsedDb;
                s = s.substring(0, slashIdx);
            }

            int portIdx = s.indexOf(':');
            if (portIdx != -1) {
                port = s.substring(portIdx + 1);
                s = s.substring(0, portIdx);
            }

            host = s.trim();
            isAivenOrCloud = true;
        }

        // Clean any accidental protocols or colons in individual variables
        if (host.startsWith("jdbc:mysql://")) host = host.substring(13);
        if (host.startsWith("mysql://")) host = host.substring(8);
        if (host.startsWith("https://")) host = host.substring(8);
        if (host.startsWith("http://")) host = host.substring(7);
        if (host.contains(":")) {
            int c = host.indexOf(':');
            port = host.substring(c + 1).replace("/", "").trim();
            host = host.substring(0, c).trim();
        }
        if (host.endsWith("/")) host = host.substring(0, host.length() - 1);
        if (port != null) port = port.replace(":", "").trim();
        if (dbName != null) {
            if (dbName.startsWith("/")) dbName = dbName.substring(1);
            int q = dbName.indexOf('?');
            if (q != -1) dbName = dbName.substring(0, q);
        }

        // Aiven hosts typically contain 'aivencloud.com'
        if (host.contains("aivencloud.com") || "true".equalsIgnoreCase(getEnvOrProp("DB_SSL", "true"))) {
            isAivenOrCloud = true;
        }

        // Auto-fix Aiven X-Protocol port to standard MySQL port
        if ("26552".equals(port)) {
            port = "26548";
        }

        // Build JDBC URL
        String jdbcUrl;
        if (isAivenOrCloud && !host.equalsIgnoreCase("localhost")) {
            jdbcUrl = String.format(
                "jdbc:mysql://%s:%s/%s?sslMode=REQUIRED&useSSL=true&allowPublicKeyRetrieval=true&autoReconnect=true&connectTimeout=10000&socketTimeout=30000&serverTimezone=UTC",
                host, port, dbName
            );
        } else {
            jdbcUrl = String.format(
                "jdbc:mysql://%s:%s/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                host, port, dbName
            );
        }

        Connection conn;
        try {
            conn = DriverManager.getConnection(jdbcUrl, user, password);
        } catch (SQLException e) {
            // If connection failed and port is 26552, retry with 26548
            if ("26552".equals(port)) {
                try {
                    String retryUrl = jdbcUrl.replace(":26552", ":26548");
                    conn = DriverManager.getConnection(retryUrl, user, password);
                } catch (SQLException retryEx) {
                    throw new SQLException(
                        String.format("Unable to connect to MySQL at [%s:%s/%s] with user '%s': %s", host, port, dbName, user, retryEx.getMessage()),
                        retryEx
                    );
                }
            } else {
                throw new SQLException(
                    String.format("Unable to connect to MySQL at [%s:%s/%s] with user '%s': %s", host, port, dbName, user, e.getMessage()),
                    e
                );
            }
        }

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
                "hourly_rate DECIMAL(10,2) DEFAULT 15.00, " +
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
                "user_type VARCHAR(50) DEFAULT 'Employee', " +
                "meeting_title VARCHAR(150) NOT NULL, " +
                "meeting_date DATE NOT NULL, " +
                "start_time TIME NOT NULL, " +
                "end_time TIME NOT NULL, " +
                "participants INT NOT NULL, " +
                "purpose VARCHAR(255), " +
                "total_amount DECIMAL(10,2) DEFAULT 0.00, " +
                "payment_method VARCHAR(50) DEFAULT 'Offline', " +
                "payment_status VARCHAR(30) DEFAULT 'Pending', " +
                "booking_status VARCHAR(30) DEFAULT 'Booked', " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE RESTRICT" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

        try (Statement stmt = conn.createStatement()) {
            stmt.executeUpdate(createUsers);
            stmt.executeUpdate(createRooms);
            stmt.executeUpdate(createBookings);

            // Ensure new columns exist in older tables (migration safeguard)
            try { stmt.executeUpdate("ALTER TABLE rooms ADD COLUMN hourly_rate DECIMAL(10,2) DEFAULT 15.00"); } catch (Exception ignored) {}
            try { stmt.executeUpdate("ALTER TABLE bookings ADD COLUMN user_type VARCHAR(50) DEFAULT 'Employee'"); } catch (Exception ignored) {}
            try { stmt.executeUpdate("ALTER TABLE bookings ADD COLUMN total_amount DECIMAL(10,2) DEFAULT 0.00"); } catch (Exception ignored) {}
            try { stmt.executeUpdate("ALTER TABLE bookings ADD COLUMN payment_method VARCHAR(50) DEFAULT 'Offline'"); } catch (Exception ignored) {}
            try { stmt.executeUpdate("ALTER TABLE bookings ADD COLUMN payment_status VARCHAR(30) DEFAULT 'Pending'"); } catch (Exception ignored) {}

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

            // Insert default student if not exists
            try (PreparedStatement checkStudent = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE username = ?")) {
                checkStudent.setString(1, "student");
                try (ResultSet rs = checkStudent.executeQuery()) {
                    if (rs.next() && rs.getInt(1) == 0) {
                        try (PreparedStatement insertStudent = conn.prepareStatement("INSERT INTO users (username, password) VALUES (?, ?)")) {
                            insertStudent.setString(1, "student");
                            insertStudent.setString(2, "student123");
                            insertStudent.executeUpdate();
                            System.out.println("[DatabaseConnection] Default student user created (student / student123).");
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
