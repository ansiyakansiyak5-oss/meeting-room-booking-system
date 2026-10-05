package com.meetingroom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Time;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@WebServlet("/bookings")
public class BookingServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String action = request.getParameter("action");
        if ("cancel".equalsIgnoreCase(action)) {
            handleCancel(request, response);
            return;
        } else if ("delete".equalsIgnoreCase(action)) {
            handleDelete(request, response);
            return;
        }

        // Load available rooms for dropdown
        List<Room> rooms = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM rooms WHERE status = 'Available' ORDER BY room_number ASC")) {
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
                        rs.getString("status")
                );
                rooms.add(r);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        request.setAttribute("rooms", rooms);

        // If edit mode requested
        String editIdStr = request.getParameter("editId");
        if (editIdStr != null && !editIdStr.trim().isEmpty()) {
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement("SELECT * FROM bookings WHERE booking_id = ?")) {
                ps.setInt(1, Integer.parseInt(editIdStr.trim()));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        Booking b = new Booking(
                                rs.getInt("booking_id"),
                                rs.getString("booking_number"),
                                rs.getInt("room_id"),
                                rs.getString("room_number"),
                                rs.getString("room_name"),
                                rs.getString("employee_name"),
                                rs.getString("employee_id"),
                                rs.getString("department"),
                                rs.getString("meeting_title"),
                                rs.getString("meeting_date"),
                                rs.getString("start_time"),
                                rs.getString("end_time"),
                                rs.getInt("participants"),
                                rs.getString("purpose"),
                                rs.getString("booking_status")
                        );
                        request.setAttribute("editBooking", b);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        request.getRequestDispatcher("/booking.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String action = request.getParameter("action");
        if ("book".equalsIgnoreCase(action) || "create".equalsIgnoreCase(action) || action == null || action.isEmpty()) {
            handleCreateBooking(request, response);
        } else if ("update".equalsIgnoreCase(action)) {
            handleUpdateBooking(request, response);
        } else if ("cancel".equalsIgnoreCase(action)) {
            handleCancel(request, response);
        } else if ("delete".equalsIgnoreCase(action)) {
            handleDelete(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/bookings");
        }
    }

    private void handleCreateBooking(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String roomIdStr = request.getParameter("roomId");
        String employeeName = request.getParameter("employeeName");
        String employeeId = request.getParameter("employeeId");
        String department = request.getParameter("department");
        String meetingTitle = request.getParameter("meetingTitle");
        String meetingDateStr = request.getParameter("meetingDate");
        String startTimeStr = request.getParameter("startTime");
        String endTimeStr = request.getParameter("endTime");
        String participantsStr = request.getParameter("participants");
        String purpose = request.getParameter("purpose");

        // Basic validation
        if (roomIdStr == null || roomIdStr.trim().isEmpty() ||
            employeeName == null || employeeName.trim().isEmpty() ||
            employeeId == null || employeeId.trim().isEmpty() ||
            meetingTitle == null || meetingTitle.trim().isEmpty() ||
            meetingDateStr == null || meetingDateStr.trim().isEmpty() ||
            startTimeStr == null || startTimeStr.trim().isEmpty() ||
            endTimeStr == null || endTimeStr.trim().isEmpty() ||
            participantsStr == null || participantsStr.trim().isEmpty()) {
            redirectWithError(request, response, "All required fields must be filled.", false, null);
            return;
        }

        int roomId = Integer.parseInt(roomIdStr.trim());
        int participants;
        try {
            participants = Integer.parseInt(participantsStr.trim());
            if (participants <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            redirectWithError(request, response, "Participants count must be greater than zero.", false, null);
            return;
        }

        // Format times to HH:mm:ss if only HH:mm provided
        String startTime = normalizeTime(startTimeStr.trim());
        String endTime = normalizeTime(endTimeStr.trim());

        if (startTime.compareTo(endTime) >= 0) {
            redirectWithError(request, response, "Start time must be strictly before End time.", false, null);
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Check room capacity & details
            String roomQuery = "SELECT room_number, room_name, capacity, status FROM rooms WHERE room_id = ?";
            String roomNumber = "";
            String roomName = "";
            int capacity = 0;
            String roomStatus = "";

            try (PreparedStatement ps = conn.prepareStatement(roomQuery)) {
                ps.setInt(1, roomId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        roomNumber = rs.getString("room_number");
                        roomName = rs.getString("room_name");
                        capacity = rs.getInt("capacity");
                        roomStatus = rs.getString("status");
                    } else {
                        redirectWithError(request, response, "Selected room does not exist.", false, null);
                        return;
                    }
                }
            }

            if (!"Available".equalsIgnoreCase(roomStatus)) {
                redirectWithError(request, response, "Room " + roomNumber + " is currently under " + roomStatus + ".", false, null);
                return;
            }

            if (participants > capacity) {
                redirectWithError(request, response, "Participants (" + participants + ") exceed room capacity (" + capacity + " people).", false, null);
                return;
            }

            // CRITICAL CONFLICT DETECTION
            // Check: existing.start_time < new.end_time AND existing.end_time > new.start_time
            String conflictQuery = "SELECT booking_number, meeting_title, employee_name, start_time, end_time " +
                    "FROM bookings " +
                    "WHERE room_id = ? " +
                    "  AND meeting_date = ? " +
                    "  AND booking_status = 'Booked' " +
                    "  AND (start_time < ? AND end_time > ?)";

            try (PreparedStatement checkConflict = conn.prepareStatement(conflictQuery)) {
                checkConflict.setInt(1, roomId);
                checkConflict.setDate(2, Date.valueOf(meetingDateStr.trim()));
                checkConflict.setTime(3, Time.valueOf(endTime));
                checkConflict.setTime(4, Time.valueOf(startTime));

                try (ResultSet rs = checkConflict.executeQuery()) {
                    if (rs.next()) {
                        String conflictMsg = String.format(
                                "Conflict detected! Room '%s' is already booked for '%s' (%s - %s) by %s.",
                                roomNumber,
                                rs.getString("meeting_title"),
                                rs.getTime("start_time").toString().substring(0, 5),
                                rs.getTime("end_time").toString().substring(0, 5),
                                rs.getString("employee_name")
                        );
                        redirectWithError(request, response, conflictMsg, false, null);
                        return;
                    }
                }
            }

            // Generate Booking Number
            String bookingNumber = generateBookingNumber();

            // Insert Booking
            String insertSql = "INSERT INTO bookings " +
                    "(booking_number, room_id, room_number, room_name, employee_name, employee_id, department, " +
                    " meeting_title, meeting_date, start_time, end_time, participants, purpose, booking_status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Booked')";

            int newBookingId = 0;
            try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, bookingNumber);
                ps.setInt(2, roomId);
                ps.setString(3, roomNumber);
                ps.setString(4, roomName);
                ps.setString(5, employeeName.trim());
                ps.setString(6, employeeId.trim());
                ps.setString(7, department != null ? department.trim() : "");
                ps.setString(8, meetingTitle.trim());
                ps.setDate(9, Date.valueOf(meetingDateStr.trim()));
                ps.setTime(10, Time.valueOf(startTime));
                ps.setTime(11, Time.valueOf(endTime));
                ps.setInt(12, participants);
                ps.setString(13, purpose != null ? purpose.trim() : "");

                ps.executeUpdate();

                try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        newBookingId = generatedKeys.getInt(1);
                    }
                }
            }

            // Redirect directly to the Receipt page for immediate confirmation & printing
            response.sendRedirect(request.getContextPath() + "/receipt?bookingId=" + newBookingId + "&new=true");

        } catch (SQLException e) {
            e.printStackTrace();
            redirectWithError(request, response, "Database error: " + e.getMessage(), false, null);
        }
    }

    private void handleUpdateBooking(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String bookingIdStr = request.getParameter("bookingId");
        String roomIdStr = request.getParameter("roomId");
        String employeeName = request.getParameter("employeeName");
        String employeeId = request.getParameter("employeeId");
        String department = request.getParameter("department");
        String meetingTitle = request.getParameter("meetingTitle");
        String meetingDateStr = request.getParameter("meetingDate");
        String startTimeStr = request.getParameter("startTime");
        String endTimeStr = request.getParameter("endTime");
        String participantsStr = request.getParameter("participants");
        String purpose = request.getParameter("purpose");
        String bookingStatus = request.getParameter("bookingStatus");

        if (bookingIdStr == null || bookingIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/history?error=" + encode("Invalid booking reference."));
            return;
        }

        int bookingId = Integer.parseInt(bookingIdStr.trim());
        int roomId = Integer.parseInt(roomIdStr.trim());
        int participants = Integer.parseInt(participantsStr.trim());

        String startTime = normalizeTime(startTimeStr.trim());
        String endTime = normalizeTime(endTimeStr.trim());

        if (startTime.compareTo(endTime) >= 0) {
            redirectWithError(request, response, "Start time must be strictly before End time.", true, bookingIdStr);
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Get Room Details
            String roomNumber = "";
            String roomName = "";
            int capacity = 0;
            try (PreparedStatement ps = conn.prepareStatement("SELECT room_number, room_name, capacity FROM rooms WHERE room_id = ?")) {
                ps.setInt(1, roomId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        roomNumber = rs.getString("room_number");
                        roomName = rs.getString("room_name");
                        capacity = rs.getInt("capacity");
                    }
                }
            }

            if (participants > capacity) {
                redirectWithError(request, response, "Participants (" + participants + ") exceed room capacity (" + capacity + ").", true, bookingIdStr);
                return;
            }

            // CRITICAL CONFLICT DETECTION (Exclude current booking)
            String conflictQuery = "SELECT booking_number, meeting_title, employee_name, start_time, end_time " +
                    "FROM bookings " +
                    "WHERE room_id = ? " +
                    "  AND meeting_date = ? " +
                    "  AND booking_status = 'Booked' " +
                    "  AND booking_id != ? " +
                    "  AND (start_time < ? AND end_time > ?)";

            try (PreparedStatement checkConflict = conn.prepareStatement(conflictQuery)) {
                checkConflict.setInt(1, roomId);
                checkConflict.setDate(2, Date.valueOf(meetingDateStr.trim()));
                checkConflict.setInt(3, bookingId);
                checkConflict.setTime(4, Time.valueOf(endTime));
                checkConflict.setTime(5, Time.valueOf(startTime));

                try (ResultSet rs = checkConflict.executeQuery()) {
                    if (rs.next()) {
                        String conflictMsg = String.format(
                                "Conflict detected! Room '%s' is already booked for '%s' (%s - %s) by %s.",
                                roomNumber,
                                rs.getString("meeting_title"),
                                rs.getTime("start_time").toString().substring(0, 5),
                                rs.getTime("end_time").toString().substring(0, 5),
                                rs.getString("employee_name")
                        );
                        redirectWithError(request, response, conflictMsg, true, bookingIdStr);
                        return;
                    }
                }
            }

            // Update Booking
            String updateSql = "UPDATE bookings SET room_id = ?, room_number = ?, room_name = ?, " +
                    "employee_name = ?, employee_id = ?, department = ?, meeting_title = ?, meeting_date = ?, " +
                    "start_time = ?, end_time = ?, participants = ?, purpose = ?, booking_status = ? " +
                    "WHERE booking_id = ?";

            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setInt(1, roomId);
                ps.setString(2, roomNumber);
                ps.setString(3, roomName);
                ps.setString(4, employeeName.trim());
                ps.setString(5, employeeId.trim());
                ps.setString(6, department != null ? department.trim() : "");
                ps.setString(7, meetingTitle.trim());
                ps.setDate(8, Date.valueOf(meetingDateStr.trim()));
                ps.setTime(9, Time.valueOf(startTime));
                ps.setTime(10, Time.valueOf(endTime));
                ps.setInt(11, participants);
                ps.setString(12, purpose != null ? purpose.trim() : "");
                ps.setString(13, bookingStatus != null ? bookingStatus.trim() : "Booked");
                ps.setInt(14, bookingId);

                ps.executeUpdate();
            }

            response.sendRedirect(request.getContextPath() + "/receipt?bookingId=" + bookingId + "&updated=true");

        } catch (SQLException e) {
            e.printStackTrace();
            redirectWithError(request, response, "Database error: " + e.getMessage(), true, bookingIdStr);
        }
    }

    private void handleCancel(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String bookingIdStr = request.getParameter("bookingId");
        if (bookingIdStr != null && !bookingIdStr.trim().isEmpty()) {
            int bookingId = Integer.parseInt(bookingIdStr.trim());
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement("UPDATE bookings SET booking_status = 'Cancelled' WHERE booking_id = ?")) {
                ps.setInt(1, bookingId);
                ps.executeUpdate();
                response.sendRedirect(request.getContextPath() + "/history?success=" + encode("Booking #" + bookingId + " has been cancelled."));
                return;
            } catch (SQLException e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/history?error=" + encode("Failed to cancel: " + e.getMessage()));
                return;
            }
        }
        response.sendRedirect(request.getContextPath() + "/history");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String bookingIdStr = request.getParameter("bookingId");
        if (bookingIdStr != null && !bookingIdStr.trim().isEmpty()) {
            int bookingId = Integer.parseInt(bookingIdStr.trim());
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement("DELETE FROM bookings WHERE booking_id = ?")) {
                ps.setInt(1, bookingId);
                ps.executeUpdate();
                response.sendRedirect(request.getContextPath() + "/history?success=" + encode("Booking record deleted successfully."));
                return;
            } catch (SQLException e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/history?error=" + encode("Failed to delete: " + e.getMessage()));
                return;
            }
        }
        response.sendRedirect(request.getContextPath() + "/history");
    }

    private String normalizeTime(String t) {
        if (t.matches("^\\d{1,2}:\\d{2}$")) {
            return (t.length() == 4 ? "0" + t : t) + ":00";
        }
        if (t.matches("^\\d{1,2}:\\d{2}:\\d{2}$")) {
            return t.length() == 7 ? "0" + t : t;
        }
        return t;
    }

    private String generateBookingNumber() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
        String datePart = sdf.format(new java.util.Date());
        int randPart = 1000 + new Random().nextInt(9000);
        return "BK-" + datePart + "-" + randPart;
    }

    private void redirectWithError(HttpServletRequest request, HttpServletResponse response,
                                   String errorMsg, boolean isEdit, String bookingId) throws IOException {
        String target = request.getContextPath() + "/bookings";
        if (isEdit && bookingId != null) {
            target += "?editId=" + bookingId + "&error=" + encode(errorMsg);
        } else {
            target += "?error=" + encode(errorMsg);
        }
        response.sendRedirect(target);
    }

    private String encode(String val) {
        return URLEncoder.encode(val, StandardCharsets.UTF_8);
    }
}
