package com.meetingroom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/availability")
public class AvailabilityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    private void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String meetingDate = request.getParameter("meetingDate");
        String startTime = request.getParameter("startTime");
        String endTime = request.getParameter("endTime");
        String participantsStr = request.getParameter("participants");
        String roomType = request.getParameter("roomType");

        List<Room> availableRooms = new ArrayList<>();
        boolean searched = false;

        if (meetingDate != null && !meetingDate.trim().isEmpty() &&
            startTime != null && !startTime.trim().isEmpty() &&
            endTime != null && !endTime.trim().isEmpty()) {

            searched = true;
            int participants = 1;
            if (participantsStr != null && !participantsStr.trim().isEmpty()) {
                try {
                    participants = Integer.parseInt(participantsStr.trim());
                } catch (NumberFormatException ignored) {}
            }

            String startNorm = normalizeTime(startTime.trim());
            String endNorm = normalizeTime(endTime.trim());

            if (startNorm.compareTo(endNorm) >= 0) {
                request.setAttribute("error", "Start time must be before End time.");
            } else {
                StringBuilder sql = new StringBuilder();
                sql.append("SELECT * FROM rooms r WHERE r.status = 'Available' AND r.capacity >= ? ");

                boolean filterType = (roomType != null && !roomType.trim().isEmpty() && !"All".equalsIgnoreCase(roomType));
                if (filterType) {
                    sql.append("AND r.room_type = ? ");
                }

                // Conflict condition: room is NOT in any active booking that overlaps
                sql.append("AND r.room_id NOT IN (");
                sql.append("    SELECT b.room_id FROM bookings b ");
                sql.append("    WHERE b.meeting_date = ? ");
                sql.append("      AND b.booking_status = 'Booked' ");
                sql.append("      AND (b.start_time < ? AND b.end_time > ?)");
                sql.append(") ORDER BY r.capacity ASC, r.room_number ASC");

                try (Connection conn = DatabaseConnection.getConnection();
                     PreparedStatement ps = conn.prepareStatement(sql.toString())) {

                    int paramIdx = 1;
                    ps.setInt(paramIdx++, participants);
                    if (filterType) {
                        ps.setString(paramIdx++, roomType.trim());
                    }
                    ps.setDate(paramIdx++, Date.valueOf(meetingDate.trim()));
                    ps.setTime(paramIdx++, Time.valueOf(endNorm));
                    ps.setTime(paramIdx++, Time.valueOf(startNorm));

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
                            availableRooms.add(r);
                        }
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Database error: " + e.getMessage());
                }
            }
        }

        request.setAttribute("searched", searched);
        request.setAttribute("availableRooms", availableRooms);
        request.setAttribute("meetingDate", meetingDate);
        request.setAttribute("startTime", startTime);
        request.setAttribute("endTime", endTime);
        request.setAttribute("participants", participantsStr);
        request.setAttribute("roomType", roomType);

        request.getRequestDispatcher("/availability.jsp").forward(request, response);
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
}
