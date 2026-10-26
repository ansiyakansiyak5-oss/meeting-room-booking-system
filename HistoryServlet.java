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
import java.util.ArrayList;
import java.util.List;

@WebServlet("/history")
public class HistoryServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String search = request.getParameter("search");
        String statusFilter = request.getParameter("status");
        String dateFilter = request.getParameter("date");

        List<Booking> bookings = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT * FROM bookings WHERE 1=1 ");

        boolean hasSearch = (search != null && !search.trim().isEmpty());
        boolean hasStatus = (statusFilter != null && !statusFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(statusFilter));
        boolean hasDate = (dateFilter != null && !dateFilter.trim().isEmpty());

        if (hasSearch) {
            sql.append("AND (booking_number LIKE ? OR meeting_title LIKE ? OR employee_name LIKE ? OR employee_id LIKE ? OR room_number LIKE ? OR department LIKE ?) ");
        }
        if (hasStatus) {
            sql.append("AND booking_status = ? ");
        }
        if (hasDate) {
            sql.append("AND meeting_date = ? ");
        }

        sql.append("ORDER BY meeting_date DESC, start_time DESC");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            int paramIndex = 1;
            if (hasSearch) {
                String term = "%" + search.trim() + "%";
                for (int i = 0; i < 6; i++) {
                    ps.setString(paramIndex++, term);
                }
            }
            if (hasStatus) {
                ps.setString(paramIndex++, statusFilter.trim());
            }
            if (hasDate) {
                ps.setDate(paramIndex++, Date.valueOf(dateFilter.trim()));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
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
                    bookings.add(b);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("dbError", "Error fetching booking history: " + e.getMessage());
        }

        request.setAttribute("bookings", bookings);
        request.setAttribute("searchQuery", search);
        request.setAttribute("statusFilter", statusFilter);
        request.setAttribute("dateFilter", dateFilter);

        request.getRequestDispatcher("/history.jsp").forward(request, response);
    }
}
