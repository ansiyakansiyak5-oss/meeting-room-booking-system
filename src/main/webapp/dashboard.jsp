<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.meetingroom.DatabaseConnection, java.util.*" %>
<%
    // Session Guard
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }
    String currentUser = (String) session.getAttribute("user");

    // Fetch dashboard stats from database
    int totalRooms = 0;
    int availableRooms = 0;
    int totalBookings = 0;
    int todayBookings = 0;

    List<Map<String, String>> todayBookingList = new ArrayList<>();

    try (Connection conn = DatabaseConnection.getConnection()) {
        // Total rooms
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM rooms")) {
            if (rs.next()) totalRooms = rs.getInt(1);
        }

        // Available rooms
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'Available'")) {
            if (rs.next()) availableRooms = rs.getInt(1);
        }

        // Total bookings
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM bookings WHERE booking_status = 'Booked'")) {
            if (rs.next()) totalBookings = rs.getInt(1);
        }

        // Today's bookings
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM bookings WHERE meeting_date = CURRENT_DATE() AND booking_status = 'Booked'")) {
            if (rs.next()) todayBookings = rs.getInt(1);
        }

        // Today's schedule
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT booking_id, booking_number, room_name, room_number, meeting_title, employee_name, start_time, end_time, booking_status " +
                                          "FROM bookings WHERE meeting_date = CURRENT_DATE() AND booking_status = 'Booked' " +
                                          "ORDER BY start_time ASC LIMIT 5")) {
            while (rs.next()) {
                Map<String, String> b = new HashMap<>();
                b.put("id", String.valueOf(rs.getInt("booking_id")));
                b.put("number", rs.getString("booking_number"));
                b.put("room", rs.getString("room_name") + " (" + rs.getString("room_number") + ")");
                b.put("title", rs.getString("meeting_title"));
                b.put("employee", rs.getString("employee_name"));
                b.put("time", rs.getString("start_time").substring(0, 5) + " - " + rs.getString("end_time").substring(0, 5));
                b.put("status", rs.getString("booking_status"));
                todayBookingList.add(b);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Meeting Room Booking System</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link href="<%= request.getContextPath() %>/css/style.css" rel="stylesheet">
</head>
<body>

    <!-- Header Navigation -->
    <%@ include file="navbar.jsp" %>

    <div class="main-content">
        <div class="container-fluid px-4">
            
            <!-- Welcome Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                    <h2 class="fw-bold mb-1 text-dark">Welcome back, <%= currentUser %>!</h2>
                    <p class="text-muted mb-0">Overview of conference room operations, live reservations, and capacity.</p>
                </div>
                <div class="d-flex gap-2">
                    <a href="<%= request.getContextPath() %>/availability" class="btn btn-outline-primary">
                        <i class="bi bi-search me-1"></i> Check Free Rooms
                    </a>
                    <a href="<%= request.getContextPath() %>/bookings" class="btn btn-primary">
                        <i class="bi bi-calendar-plus me-1"></i> New Booking
                    </a>
                </div>
            </div>

            <!-- Metric Cards Row -->
            <div class="row g-3 mb-4">
                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Total Rooms</div>
                            <h2 class="fw-bold mb-0 text-dark mt-1"><%= totalRooms %></h2>
                            <small class="text-success"><i class="bi bi-check2"></i> Registered rooms</small>
                        </div>
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary">
                            <i class="bi bi-door-closed"></i>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Available Rooms</div>
                            <h2 class="fw-bold mb-0 text-success mt-1"><%= availableRooms %></h2>
                            <small class="text-muted">Ready for booking</small>
                        </div>
                        <div class="stat-icon bg-success bg-opacity-10 text-success">
                            <i class="bi bi-check-circle"></i>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Today's Bookings</div>
                            <h2 class="fw-bold mb-0 text-primary mt-1"><%= todayBookings %></h2>
                            <small class="text-muted">Scheduled today</small>
                        </div>
                        <div class="stat-icon bg-info bg-opacity-10 text-info">
                            <i class="bi bi-calendar-day"></i>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Active Bookings</div>
                            <h2 class="fw-bold mb-0 text-dark mt-1"><%= totalBookings %></h2>
                            <small class="text-primary"><i class="bi bi-graph-up"></i> Total scheduled</small>
                        </div>
                        <div class="stat-icon bg-warning bg-opacity-10 text-warning">
                            <i class="bi bi-calendar-check"></i>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Quick Action Grid -->
            <div class="row g-4 mb-4">
                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0 shadow-sm">
                        <div class="d-inline-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-door-open fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Room Management</h5>
                        <p class="text-muted small mb-3">Add, update, or remove meeting rooms, capacity, and equipment.</p>
                        <a href="<%= request.getContextPath() %>/rooms" class="btn btn-outline-primary btn-sm mt-auto">Manage Rooms</a>
                    </div>
                </div>

                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0 shadow-sm">
                        <div class="d-inline-flex align-items-center justify-content-center bg-success bg-opacity-10 text-success rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-calendar-plus fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Meeting Booking</h5>
                        <p class="text-muted small mb-3">Reserve rooms with real-time smart conflict prevention.</p>
                        <a href="<%= request.getContextPath() %>/bookings" class="btn btn-outline-success btn-sm mt-auto">Book Now</a>
                    </div>
                </div>

                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0 shadow-sm">
                        <div class="d-inline-flex align-items-center justify-content-center bg-info bg-opacity-10 text-info rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-search fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Room Availability</h5>
                        <p class="text-muted small mb-3">Filter by date, time window, and seating capacity to find vacant rooms.</p>
                        <a href="<%= request.getContextPath() %>/availability" class="btn btn-outline-info btn-sm mt-auto">Check Availability</a>
                    </div>
                </div>

                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0 shadow-sm">
                        <div class="d-inline-flex align-items-center justify-content-center bg-warning bg-opacity-10 text-warning rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-clock-history fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Booking History</h5>
                        <p class="text-muted small mb-3">Review all past and current reservations, receipts, and cancellations.</p>
                        <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-warning btn-sm mt-auto">View History</a>
                    </div>
                </div>
            </div>

            <!-- Today's Schedule Table -->
            <div class="card card-custom mb-4 border-0">
                <div class="card-header-custom d-flex justify-content-between align-items-center bg-white">
                    <span class="fw-bold text-dark"><i class="bi bi-calendar-day me-2 text-primary"></i>Today's Meeting Schedule</span>
                    <a href="<%= request.getContextPath() %>/history?date=<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" class="btn btn-sm btn-link text-decoration-none">
                        View All Today's Bookings &rarr;
                    </a>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-custom table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Ref #</th>
                                    <th>Meeting Title</th>
                                    <th>Room</th>
                                    <th>Organizer</th>
                                    <th>Time Slot</th>
                                    <th>Status</th>
                                    <th class="text-end">Receipt</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (todayBookingList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="7" class="text-center py-4 text-muted">
                                            <i class="bi bi-calendar2-x fs-3 d-block mb-1"></i>
                                            No meetings scheduled for today yet.
                                        </td>
                                    </tr>
                                <% } else { %>
                                    <% for (Map<String, String> b : todayBookingList) { %>
                                        <tr>
                                            <td class="fw-bold font-monospace"><%= b.get("number") %></td>
                                            <td><strong><%= b.get("title") %></strong></td>
                                            <td><span class="badge bg-light text-dark border"><%= b.get("room") %></span></td>
                                            <td><%= b.get("employee") %></td>
                                            <td><i class="bi bi-clock me-1 text-muted"></i><%= b.get("time") %></td>
                                            <td><span class="badge-status badge-booked"><%= b.get("status") %></span></td>
                                            <td class="text-end">
                                                <a href="<%= request.getContextPath() %>/receipt?bookingId=<%= b.get("id") %>" class="btn btn-outline-secondary btn-sm" title="View Slip">
                                                    <i class="bi bi-receipt"></i>
                                                </a>
                                            </td>
                                        </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <footer class="text-center">
        <div class="container">
            Meeting Room Booking System &copy; Pure Java Servlets + JSP + MySQL (Aiven)
        </div>
    </footer>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js"></script>
</body>
</html>
