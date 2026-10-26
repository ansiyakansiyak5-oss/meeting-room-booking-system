package com.meetingroom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet("/receipt")
public class ReceiptServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
            return;
        }

        String bookingIdStr = request.getParameter("bookingId");
        String bookingNumber = request.getParameter("bookingNumber");
        String downloadFormat = request.getParameter("download");

        if ((bookingIdStr == null || bookingIdStr.trim().isEmpty()) &&
            (bookingNumber == null || bookingNumber.trim().isEmpty())) {
            response.sendRedirect(request.getContextPath() + "/history?error=No+booking+specified");
            return;
        }

        Booking booking = null;
        Room room = null;

        String sql = "SELECT b.*, r.room_number AS r_num, r.room_name AS r_name, r.building, r.floor, r.capacity, r.room_type, r.facilities, r.status AS r_status " +
                     "FROM bookings b " +
                     "JOIN rooms r ON b.room_id = r.room_id " +
                     "WHERE ";

        if (bookingIdStr != null && !bookingIdStr.trim().isEmpty()) {
            sql += "b.booking_id = ?";
        } else {
            sql += "b.booking_number = ?";
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (bookingIdStr != null && !bookingIdStr.trim().isEmpty()) {
                ps.setInt(1, Integer.parseInt(bookingIdStr.trim()));
            } else {
                ps.setString(1, bookingNumber.trim());
            }

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    booking = new Booking(
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

                    room = new Room(
                            rs.getInt("room_id"),
                            rs.getString("r_num"),
                            rs.getString("r_name"),
                            rs.getString("building"),
                            rs.getString("floor"),
                            rs.getInt("capacity"),
                            rs.getString("room_type"),
                            rs.getString("facilities"),
                            rs.getString("r_status")
                    );
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        if (booking == null) {
            response.sendRedirect(request.getContextPath() + "/history?error=Booking+not+found");
            return;
        }

        // Handle download as TXT
        if ("txt".equalsIgnoreCase(downloadFormat)) {
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment; filename=\"Receipt-" + booking.getBookingNumber() + ".txt\"");
            try (PrintWriter out = response.getWriter()) {
                out.println("================================================================================");
                out.println("                     MEETING ROOM BOOKING SYSTEM - RECEIPT                      ");
                out.println("================================================================================");
                out.println("Booking Reference : " + booking.getBookingNumber());
                out.println("Booking Status    : " + booking.getBookingStatus());
                out.println("Date of Booking   : " + booking.getMeetingDate());
                out.println("Time Slot         : " + booking.getStartTime() + " to " + booking.getEndTime());
                out.println("--------------------------------------------------------------------------------");
                out.println("MEETING DETAILS");
                out.println("Title             : " + booking.getMeetingTitle());
                out.println("Purpose           : " + (booking.getPurpose() != null ? booking.getPurpose() : "N/A"));
                out.println("Participants      : " + booking.getParticipants() + " persons");
                out.println("--------------------------------------------------------------------------------");
                out.println("ROOM INFORMATION");
                out.println("Room Name         : " + (room != null ? room.getRoomName() : booking.getRoomName()));
                out.println("Room Number       : " + (room != null ? room.getRoomNumber() : booking.getRoomNumber()));
                if (room != null) {
                    out.println("Location          : " + room.getBuilding() + " (" + room.getFloor() + ")");
                    out.println("Room Type         : " + room.getRoomType());
                    out.println("Capacity          : " + room.getCapacity() + " people");
                    out.println("Facilities        : " + room.getFacilities());
                }
                out.println("--------------------------------------------------------------------------------");
                out.println("BOOKED BY");
                out.println("Employee Name     : " + booking.getEmployeeName());
                out.println("Employee ID       : " + booking.getEmployeeId());
                out.println("Department        : " + booking.getDepartment());
                out.println("================================================================================");
                out.println("Please present this confirmation slip when occupying the meeting room.");
                out.println("Generated on      : " + new java.util.Date());
                out.println("================================================================================");
            }
            return;
        }

        request.setAttribute("booking", booking);
        request.setAttribute("room", room);
        request.getRequestDispatcher("/receipt.jsp").forward(request, response);
    }
}
