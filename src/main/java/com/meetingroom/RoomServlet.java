package com.meetingroom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/rooms")
public class RoomServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Authenticate session
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String action = request.getParameter("action");
        if ("delete".equalsIgnoreCase(action)) {
            handleDelete(request, response);
            return;
        } else if ("toggle".equalsIgnoreCase(action)) {
            handleToggleStatus(request, response);
            return;
        }

        String search = request.getParameter("search");
        List<Room> rooms = new ArrayList<>();

        String sql;
        boolean hasSearch = (search != null && !search.trim().isEmpty());
        if (hasSearch) {
            sql = "SELECT * FROM rooms WHERE room_number LIKE ? OR room_name LIKE ? OR building LIKE ? OR room_type LIKE ? OR status LIKE ? ORDER BY room_id DESC";
        } else {
            sql = "SELECT * FROM rooms ORDER BY room_id DESC";
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (hasSearch) {
                String term = "%" + search.trim() + "%";
                for (int i = 1; i <= 5; i++) {
                    ps.setString(i, term);
                }
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Room r = new Room(
                            rs.getInt("room_id"),
                            rs.getString("room_number"),
                            rs.getString("room_name"),
                            rs.getString("building"),
                            rs.getString("floor"),
                            rs.getInt("capacity"),
                            rs.getString("room_type"),
                            rs.getString("facilities"),
                            rs.getDouble("hourly_rate"),
                            rs.getString("status")
                    );
                    rooms.add(r);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("dbError", "Error loading rooms: " + e.getMessage());
        }

        request.setAttribute("rooms", rooms);
        request.setAttribute("searchQuery", search);
        request.getRequestDispatcher("/room-management.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Authenticate session
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String action = request.getParameter("action");
        if ("add".equalsIgnoreCase(action)) {
            handleAddRoom(request, response);
        } else if ("update".equalsIgnoreCase(action)) {
            handleUpdateRoom(request, response);
        } else if ("delete".equalsIgnoreCase(action)) {
            handleDelete(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/rooms");
        }
    }

    private void handleAddRoom(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String roomNumber = request.getParameter("roomNumber");
        String roomName = request.getParameter("roomName");
        String building = request.getParameter("building");
        String floor = request.getParameter("floor");
        String capacityStr = request.getParameter("capacity");
        String roomType = request.getParameter("roomType");
        String facilities = request.getParameter("facilities");
        String status = request.getParameter("status");

        if (roomNumber == null || roomNumber.trim().isEmpty() ||
            roomName == null || roomName.trim().isEmpty() ||
            capacityStr == null || capacityStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Room number, name, and capacity are required.", "UTF-8"));
            return;
        }

        int capacity;
        try {
            capacity = Integer.parseInt(capacityStr.trim());
            if (capacity <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Capacity must be a positive integer.", "UTF-8"));
            return;
        }

        String hourlyRateStr = request.getParameter("hourlyRate");
        double hourlyRate = 15.00;
        if (hourlyRateStr != null && !hourlyRateStr.trim().isEmpty()) {
            try { hourlyRate = Double.parseDouble(hourlyRateStr.trim()); } catch (Exception ignored) {}
        }

        if (status == null || status.trim().isEmpty()) {
            status = "Available";
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Check for duplicate room number
            String checkSql = "SELECT COUNT(*) FROM rooms WHERE room_number = ?";
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                checkPs.setString(1, roomNumber.trim());
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Room number '" + roomNumber.trim() + "' already exists.", "UTF-8"));
                        return;
                    }
                }
            }

            String insertSql = "INSERT INTO rooms (room_number, room_name, building, floor, capacity, room_type, facilities, hourly_rate, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                ps.setString(1, roomNumber.trim());
                ps.setString(2, roomName.trim());
                ps.setString(3, building != null ? building.trim() : "");
                ps.setString(4, floor != null ? floor.trim() : "");
                ps.setInt(5, capacity);
                ps.setString(6, roomType != null ? roomType.trim() : "Meeting Room");
                ps.setString(7, facilities != null ? facilities.trim() : "");
                ps.setDouble(8, hourlyRate);
                ps.setString(9, status.trim());
                ps.executeUpdate();
            }

            response.sendRedirect(request.getContextPath() + "/rooms?success=" + java.net.URLEncoder.encode("Room '" + roomName.trim() + "' added successfully!", "UTF-8"));
        } catch (SQLException e) {
            System.err.println("[RoomServlet] Room creation error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Unable to add room due to a database error.", "UTF-8"));
        }
    }

    private void handleUpdateRoom(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String roomIdStr = request.getParameter("roomId");
        String roomNumber = request.getParameter("roomNumber");
        String roomName = request.getParameter("roomName");
        String building = request.getParameter("building");
        String floor = request.getParameter("floor");
        String capacityStr = request.getParameter("capacity");
        String roomType = request.getParameter("roomType");
        String facilities = request.getParameter("facilities");
        String status = request.getParameter("status");

        if (roomIdStr == null || roomIdStr.trim().isEmpty() ||
            roomNumber == null || roomNumber.trim().isEmpty() ||
            roomName == null || roomName.trim().isEmpty() ||
            capacityStr == null || capacityStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Missing required fields for update.", "UTF-8"));
            return;
        }

        int roomId = Integer.parseInt(roomIdStr.trim());
        int capacity;
        try {
            capacity = Integer.parseInt(capacityStr.trim());
            if (capacity <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Capacity must be a positive integer.", "UTF-8"));
            return;
        }

        String hourlyRateStr = request.getParameter("hourlyRate");
        double hourlyRate = 15.00;
        if (hourlyRateStr != null && !hourlyRateStr.trim().isEmpty()) {
            try { hourlyRate = Double.parseDouble(hourlyRateStr.trim()); } catch (Exception ignored) {}
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Check for duplicate room number excluding current room
            String checkSql = "SELECT COUNT(*) FROM rooms WHERE room_number = ? AND room_id != ?";
            try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                checkPs.setString(1, roomNumber.trim());
                checkPs.setInt(2, roomId);
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Another room with number '" + roomNumber.trim() + "' already exists.", "UTF-8"));
                        return;
                    }
                }
            }

            String updateSql = "UPDATE rooms SET room_number = ?, room_name = ?, building = ?, floor = ?, capacity = ?, room_type = ?, facilities = ?, hourly_rate = ?, status = ? WHERE room_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, roomNumber.trim());
                ps.setString(2, roomName.trim());
                ps.setString(3, building != null ? building.trim() : "");
                ps.setString(4, floor != null ? floor.trim() : "");
                ps.setInt(5, capacity);
                ps.setString(6, roomType != null ? roomType.trim() : "Meeting Room");
                ps.setString(7, facilities != null ? facilities.trim() : "");
                ps.setDouble(8, hourlyRate);
                ps.setString(9, status != null ? status.trim() : "Available");
                ps.setInt(10, roomId);
                ps.executeUpdate();
            }

            // Also update room_number and room_name in existing bookings for consistency
            String syncBookingsSql = "UPDATE bookings SET room_number = ?, room_name = ? WHERE room_id = ?";
            try (PreparedStatement psSync = conn.prepareStatement(syncBookingsSql)) {
                psSync.setString(1, roomNumber.trim());
                psSync.setString(2, roomName.trim());
                psSync.setInt(3, roomId);
                psSync.executeUpdate();
            }

            response.sendRedirect(request.getContextPath() + "/rooms?success=" + java.net.URLEncoder.encode("Room updated successfully!", "UTF-8"));
        } catch (SQLException e) {
            System.err.println("[RoomServlet] Room creation error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Unable to add room due to a database error.", "UTF-8"));
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String roomIdStr = request.getParameter("roomId");
        if (roomIdStr == null || roomIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Invalid room ID.", "UTF-8"));
            return;
        }

        int roomId = Integer.parseInt(roomIdStr.trim());

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Check active bookings: Prevent deleting rooms with active/upcoming bookings
            String checkBookingsSql = "SELECT COUNT(*) FROM bookings WHERE room_id = ? AND booking_status = 'Booked' AND meeting_date >= CURRENT_DATE()";
            try (PreparedStatement psCheck = conn.prepareStatement(checkBookingsSql)) {
                psCheck.setInt(1, roomId);
                try (ResultSet rs = psCheck.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        int activeCount = rs.getInt(1);
                        response.sendRedirect(request.getContextPath() + "/rooms?error=" +
                                java.net.URLEncoder.encode("Cannot delete room: It has " + activeCount + " active/upcoming booking(s). Please cancel or reassign those bookings first.", "UTF-8"));
                        return;
                    }
                }
            }

            // If there are historical cancelled/completed bookings, delete them or handle FK
            String deleteBookingsSql = "DELETE FROM bookings WHERE room_id = ?";
            try (PreparedStatement psDelB = conn.prepareStatement(deleteBookingsSql)) {
                psDelB.setInt(1, roomId);
                psDelB.executeUpdate();
            }

            String deleteSql = "DELETE FROM rooms WHERE room_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                ps.setInt(1, roomId);
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    response.sendRedirect(request.getContextPath() + "/rooms?success=" + java.net.URLEncoder.encode("Room deleted successfully.", "UTF-8"));
                } else {
                    response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Room not found.", "UTF-8"));
                }
            }
        } catch (SQLException e) {
            System.err.println("[RoomServlet] Room creation error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Unable to add room due to a database error.", "UTF-8"));
        }
    }

    private void handleToggleStatus(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String roomIdStr = request.getParameter("roomId");
        if (roomIdStr == null || roomIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/rooms");
            return;
        }
        int roomId = Integer.parseInt(roomIdStr.trim());

        try (Connection conn = DatabaseConnection.getConnection()) {
            String toggleSql = "UPDATE rooms SET status = CASE WHEN status = 'Available' THEN 'Maintenance' ELSE 'Available' END WHERE room_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(toggleSql)) {
                ps.setInt(1, roomId);
                ps.executeUpdate();
            }
            response.sendRedirect(request.getContextPath() + "/rooms?success=" + java.net.URLEncoder.encode("Room status toggled successfully.", "UTF-8"));
        } catch (SQLException e) {
            System.err.println("[RoomServlet] Room creation error: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/rooms?error=" + java.net.URLEncoder.encode("Unable to add room due to a database error.", "UTF-8"));
        }
    }
}
